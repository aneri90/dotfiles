#!/usr/bin/env python3
"""Stands in for `glab api`: answers from the scenario in $FAKE_SCENARIO.

Each route is {"method", "match" (regex on the path), "responses": [...]}; a route
returns its responses in order and repeats the last one. Calls are logged to
$FAKE_SCENARIO.log so tests can assert what was (not) sent.
"""
import json
import os
import re
import sys

args = sys.argv[1:]
assert args[0] == "api", args
path = args[1]
method = args[args.index("-X") + 1] if "-X" in args else "GET"
fields = [args[i + 1] for i, a in enumerate(args) if a == "-f"]
scenario_path = os.environ["FAKE_SCENARIO"]
state_path = scenario_path + ".state"
with open(scenario_path) as f:
    routes = json.load(f)
state = json.load(open(state_path)) if os.path.exists(state_path) else {}
with open(scenario_path + ".log", "a") as log:
    log.write(json.dumps({"method": method, "path": path, "fields": fields}) + "\n")
for i, route in enumerate(routes):
    if route.get("method", "GET") == method and re.search(route["match"], path):
        n = state.get(str(i), 0)
        state[str(i)] = n + 1
        json.dump(state, open(state_path, "w"))
        resp = route["responses"][min(n, len(route["responses"]) - 1)]
        status = resp.get("status", 200)
        if status >= 400:
            sys.stderr.write("glab: error (HTTP %d)\n" % status)
            sys.exit(1)
        print(json.dumps(resp.get("body")))
        sys.exit(0)
sys.stderr.write("glab: no fake route for %s %s (HTTP 404)\n" % (method, path))
sys.exit(1)
