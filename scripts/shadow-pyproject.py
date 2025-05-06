#!/usr/bin/env python

# Read a package.json file and transform it for use in packaging cloud functions.

import os
import sys
import json
import yaml
from typing import cast, Dict, Any


def main() -> None:
    if not os.path.exists("package.json"):
        print("package.json not found", file=sys.stderr)
        exit(1)

    try:
        with open("package.json") as f:
            jsproject = cast(Dict[str, Any], json.loads(f.read()))
    except Exception as e:
        print(f"Error reading package.json: {e}", file=sys.stderr)
        exit(1)

    if not "REPO_ROOT" in os.environ:
        print("Environment variable REPO_ROOT is not set", file=sys.stderr)
        exit(1)

    REPO_ROOT = os.environ["REPO_ROOT"]
    workspace_file = os.path.join(REPO_ROOT, "pnpm-workspace.yaml")
    if not os.path.exists(workspace_file):
        print(f"pnpm workspace configuration file {workspace_file} not found", file=sys.stderr)
        exit(1)

    try:
        with open(workspace_file) as f:
            catalog = cast(Dict[str, Any], yaml.safe_load(f.read()))["catalog"]
    except Exception as e:
        print(f"Error reading catalog from pnpm workspace configuration file {workspace_file}: {e}", file=sys.stderr)
        exit(1)

    jsproject["name"] = jsproject["name"].replace("@costvine/", "")

    if "type" in jsproject:
        del jsproject["type"]
    if "scripts" in jsproject:
        del jsproject["scripts"]
    if "devDependencies" in jsproject:
        del jsproject["devDependencies"]

    if not "NODE_VERSION" in os.environ:
        print("Environment variable NODE_VERSION is not set", file=sys.stderr)
        exit(1)

    jsproject["engines"] = {"node": os.environ["NODE_VERSION"].split(".")[0], "pnpm": ">=9"}
    jsproject["main"] = "index.cjs"

    pathedDependencies = {}
    for dep in jsproject["dependencies"].keys():
        if not dep.startswith("@costvine/"):
            version = jsproject["dependencies"][dep]
            if version == "catalog:":
                version = catalog[dep]
            pathedDependencies[dep] = version

    jsproject["dependencies"] = pathedDependencies

    print(json.dumps(jsproject, indent="\t"))


if __name__ == "__main__":
    main()
