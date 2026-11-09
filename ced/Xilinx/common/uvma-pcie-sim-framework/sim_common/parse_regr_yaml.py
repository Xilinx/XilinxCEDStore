#!/usr/bin/env python3
import argparse
import re
import sys
from os.path import exists

try:
    import yaml
except ImportError:
    sys.exit("ERROR: PyYAML is not installed. Run: pip3 install pyyaml")

ap = argparse.ArgumentParser(description='Parse regression YAML testlist')
ap.add_argument('filepath', help='Path to YAML testlist file')
ap.add_argument('--mode', choices=['tests', 'defines'], default='tests',
                help='Output mode: tests (tab-delimited) or defines (comma-separated)')
args = ap.parse_args()

filepath = args.filepath
if not exists(filepath):
    sys.exit("ERROR: File '{}' does not exist".format(filepath))

with open(filepath, 'r') as f:
    try:
        data = yaml.safe_load(f)
    except yaml.YAMLError as e:
        sys.exit("ERROR: Invalid YAML in '{}': {}".format(filepath, e))

if not isinstance(data, dict) or 'tests' not in data:
    sys.exit("ERROR: YAML must have a top-level 'tests' key")

yaml_defines = data.get('defines', [])
if not isinstance(yaml_defines, list):
    sys.exit("ERROR: 'defines' must be a list of strings")
define_re = re.compile(r'^[a-zA-Z_][a-zA-Z0-9_]*(=[^\s,]+)?$')
for i, d in enumerate(yaml_defines):
    if not isinstance(d, str):
        sys.exit("ERROR: defines[{}] must be a string".format(i))
    if not define_re.match(d):
        sys.exit("ERROR: defines[{}] invalid format: '{}'".format(i, d))

if args.mode == 'defines':
    if yaml_defines:
        print(','.join(yaml_defines))
    sys.exit(0)

tests = data['tests']
if not isinstance(tests, list) or len(tests) == 0:
    sys.exit("ERROR: 'tests' must be a non-empty list")

name_re = re.compile(r'^[a-zA-Z0-9_]+$')
seen = set()
validated = []

for i, entry in enumerate(tests):
    if not isinstance(entry, dict):
        sys.exit("ERROR: tests[{}] must be a mapping with 'name' and 'runs'".format(i))

    if 'name' not in entry:
        sys.exit("ERROR: tests[{}] missing required field 'name'".format(i))
    name = entry['name']
    if not isinstance(name, str) or not name_re.match(name):
        sys.exit("ERROR: tests[{}] 'name' must match [a-zA-Z0-9_]+, got '{}'".format(i, name))

    if name in seen:
        sys.exit("ERROR: duplicate test name '{}'".format(name))
    seen.add(name)

    runs = entry.get('runs', 1)
    if not isinstance(runs, int) or runs < 1:
        sys.exit("ERROR: tests[{}] 'runs' must be an integer >= 1, got '{}'".format(i, runs))

    plusargs = entry.get('plusargs', '')
    if not isinstance(plusargs, str):
        sys.exit("ERROR: tests[{}] 'plusargs' must be a string".format(i))
    if '\t' in plusargs:
        sys.exit("ERROR: tests[{}] 'plusargs' must not contain tab characters".format(i))

    validated.append((name, runs, plusargs))

for name, runs, plusargs in validated:
    print("{}\t{}\t{}".format(name, runs, plusargs))
