#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$repo_root"

python3 - <<'PY'
import json
import pathlib


def strip_jsonc(text):
    output = []
    index = 0
    in_string = False
    escape = False

    while index < len(text):
        char = text[index]
        next_char = text[index + 1] if index + 1 < len(text) else ""

        if in_string:
            output.append(char)
            if escape:
                escape = False
            elif char == "\\":
                escape = True
            elif char == '"':
                in_string = False
            index += 1
            continue

        if char == '"':
            in_string = True
            output.append(char)
            index += 1
            continue

        if char == "/" and next_char == "/":
            index = text.find("\n", index)
            if index == -1:
                break
            output.append("\n")
            index += 1
            continue

        output.append(char)
        index += 1

    return "".join(output)


def remove_trailing_commas(text):
    output = []
    index = 0
    in_string = False
    escape = False

    while index < len(text):
        char = text[index]

        if in_string:
            output.append(char)
            if escape:
                escape = False
            elif char == "\\":
                escape = True
            elif char == '"':
                in_string = False
            index += 1
            continue

        if char == '"':
            in_string = True
            output.append(char)
            index += 1
            continue

        if char == ",":
            lookahead = index + 1
            while lookahead < len(text) and text[lookahead].isspace():
                lookahead += 1
            if lookahead < len(text) and text[lookahead] in "}]":
                index += 1
                continue

        output.append(char)
        index += 1

    return "".join(output)


path = pathlib.Path("settings.json")
json.loads(remove_trailing_commas(strip_jsonc(path.read_text())))
print(f"OK {path}")
PY
