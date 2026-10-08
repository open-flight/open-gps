#!/bin/sh
# Regenerate every PNG in renders/ (full geometry with colours, Tomorrow scheme).
# Usage: ./render_all.sh            (run from case/concepts/)
set -e
cd "$(dirname "$0")"
OS=${OPENSCAD:-/opt/homebrew/bin/openscad}
# r <file> <part> <out> <rx,ry,rz> [WxH]   -- auto-framed (--viewall)
r() { "$OS" --backend=manifold --colorscheme=Tomorrow --render --projection=p --imgsize=${5:-1400,1100} \
        --viewall --autocenter --camera=0,0,0,$4,0 $EXTRA -D "part=\"$2\"" -o "renders/$3" "$1" >/dev/null 2>&1 && echo "renders/$3"; }
# c <file> <part> <out> <camera tx,ty,tz,rx,ry,rz,dist> <WxH>   -- explicit camera
c() { "$OS" --backend=manifold --colorscheme=Tomorrow --render --projection=p --imgsize=$5 \
        --camera=$4 -D "part=\"$2\"" -o "renders/$3" "$1" >/dev/null 2>&1 && echo "renders/$3"; }
mkdir -p renders
for k in "a_grip concept_a_grip.scad" "b_stone concept_b_stone.scad"; do
    set -- $k; n=$1; f=$2
    r $f assembly ${n}_front.png     70,0,28
    r $f assembly ${n}_back.png      70,0,215
    r $f cutaway  ${n}_cutaway.png   64,0,62
    r $f exploded ${n}_exploded.png  60,0,63
    r $f cart     ${n}_cart.png      68,0,30
    r $f cart     ${n}_cart_side.png 75,0,125
    r $f strap    ${n}_strap.png     78,0,-58
done
# Concept B2 (layered stone)
f=concept_b2_stone.scad
r $f assembly b2_stone_front.png     70,0,28
r $f assembly b2_stone_back.png      70,0,215
r $f side     b2_stone_side.png      84,0,62  1400,900
r $f cutaway  b2_stone_cutaway.png   70,0,72
r $f exploded b2_stone_exploded.png  60,0,63
EXTRA="-D mount_socket=true" r $f cart     b2_stone_cart.png      68,0,30
EXTRA="-D mount_socket=true" r $f strap    b2_stone_strap.png     78,0,-58
r mount_kit.scad kit mount_kit.png 75,0,20
c mount_kit.scad socket mount_socket.png 30,0,-4,72,0,-8,175 1400,760
c lineup.scad all lineup.png 109,0,20,84,0,10,560 1600,820
c lineup.scad b2 lineup_b2.png 100,0,20,84,0,10,520 1600,820
# Concept B2 print STLs (print orientation) -> stl_b2/
./export_b2.sh >/dev/null && echo "stl_b2/*.stl"
