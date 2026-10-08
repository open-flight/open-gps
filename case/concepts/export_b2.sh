#!/bin/sh
# Export Concept B2's print parts, in print orientation, to stl_b2/.
# Usage: ./export_b2.sh            (run from case/concepts/; add -D 'mount_socket=true' etc. as extra args)
set -e
cd "$(dirname "$0")"
OS=${OPENSCAD:-/opt/homebrew/bin/openscad}
mkdir -p stl_b2
for p in back_shell lid plate knob plunger; do
    "$OS" --backend=manifold -D "part=\"$p\"" "$@" -o "stl_b2/$p.stl" concept_b2_stone.scad 2>&1 \
        | grep -E "Status|Genus|Volumes|WARNING|ERROR" | sed "s/^/  $p: /"
done
