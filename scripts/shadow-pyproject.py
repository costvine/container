#!/usr/bin/env python

# Read pyproject.toml and generate a complimentary package.json.

import os
import sys
import tomlkit
import tomlkit.items
import json
from typing import cast, Dict, Any


def main() -> None:
    if not os.path.exists("pyproject.toml"):
        print("pyproject.toml not found", file=sys.stderr)
        exit(1)

    try:
        with open("pyproject.toml") as f:
            pyproject = cast(Dict[str, Any], tomlkit.parse(f.read()))
    except Exception as e:
        print(f"Error reading pyproject.toml: {e}", file=sys.stderr)
        exit(1)

    # Check if pyproject.toml contains poetry section
    try:
        poetry = pyproject["tool"]["poetry"]
    except KeyError:
        print("pyproject.toml does not contain a 'tool.poetry' section", file=sys.stderr)
        exit(1)

    # Check for costvine section
    try:
        costvine = pyproject["tool"]["costvine"]
    except KeyError:
        costvine = {}

    output_json = {}

    output_json["name"] = poetry["name"]
    output_json["version"] = poetry["version"]
    output_json["description"] = poetry["description"]
    output_json["type"] = "module"
    if "author" in poetry:
        output_json["author"] = poetry["author"]
    if "authors" in poetry:
        output_json["contributors"] = poetry["authors"]
    if "license" in poetry:
        output_json["license"] = poetry["license"]
    output_json["private"] = True

    output_json["scripts"] = {}
    if "scripts" in costvine:
        scripts = costvine["scripts"]
        for scriptname in scripts:
            output_json["scripts"][scriptname] = scripts[scriptname]

    output_json["dependencies"] = {}
    if "dependencies" in poetry:
        dependencies = poetry["dependencies"]
        for depname in dependencies:
            if type(dependencies[depname]) == tomlkit.items.InlineTable:
                if "path" in dependencies[depname]:
                    output_json["dependencies"][depname] = "workspace:^"

    print(json.dumps(output_json, indent="\t"))


if __name__ == "__main__":
    main()
