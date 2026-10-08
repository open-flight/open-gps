# Golf Shot Tracker – Handheld Enclosure (v0.1)

A parametric OpenSCAD enclosure for the SparkFun plug-and-play shot tracker. It holds these parts:

- SparkFun Thing Plus ESP32-S3
- SparkFun GPS Breakout NEO-M9N, SMA (Qwiic)
- SparkFun Qwiic OLED 1.3" 128x64
- SparkFun Qwiic Twist RGB Rotary Encoder
- Lithium Ion Battery 2Ah
- GPS/GNSS Magnetic Mount Antenna 3m (SMA)
- SparkFun Qwiic Cable Kit

Board outlines, mounting holes and connector positions come from SparkFun's own Eagle and KiCad source files on GitHub. Only the parts listed under "Measure before you print" were estimated.

## Size

The case is 74.4 x 74.4 x 31.6 mm (W x H x D). The GPS antenna plugs into an SMA port in the top wall, and the antenna and its cable stay outside the case.

## Layout

Viewed from the front:

- **Top wall:** the SMA antenna port. This is the GPS board's own edge-mount SMA jack, sitting 0.6 mm behind the wall. An 11 mm opening lets the plug's coupling nut reach the thread. To its left are a zip-tie anchor (to strain-relieve the antenna cable) and a lanyard lug. To its right, a small bulge holds a 5 mm pocket behind the GPS's top-edge Qwiic port, so a plug fits there.
- **Front:** the OLED window with the Twist dial below it, and the **RESET button** between them. A printed plunger, standing 1 mm proud of the lid, presses the Thing Plus RESET button, which wakes the device from firmware power-off.
- **Left side:** the **EN slide switch**, the hard power-off. It pulls the Thing Plus EN pin to GND, which disables the main 3.3 V regulator. Charging still works with it off.
- **Bottom end:** USB-C (charging and programming) and a microSD slot, both on the Thing Plus.
- **Inside, stacked from the back:** the battery sits on the floor. An internal plate sits above it and carries the Thing Plus (left) and the GPS (right, rotated so its SMA faces the top wall).
- **Lid:** the OLED and the Twist screw onto bosses on the lid.
- **Closing:** the lid has two tongues that hook under the top wall. It swings down and is held by two M3 screws from the back.

## Files

- `cad/shot_tracker_case.scad`: single source file. Set `part` to `shell`, `lid`, `plate`, `knob`, `plunger`, `assembly` or `exploded`.
- `stl/`: pre-exported parts in print orientation.

To re-export a part:
```
openscad -D 'part="shell"' -o shell.stl cad/shot_tracker_case.scad
```
Collision-check targets (`chk_shell`, `chk_lid`, `chk_plate`, …) intersect each part with the ghost components. They should come back empty or zero-volume.

## Hardware

| Qty | Item | Where |
|---|---|---|
| 2 | M3 heat-set insert, 4.0 mm hole, ≤5.8 mm long | lid bottom corners |
| 2 | M3 x 25 socket head | back → lid |
| 6 | M2.5 x 5 pan head (self-tapping into PETG) | Thing Plus (2), GPS (4) → plate. **Don't use longer than 5 mm.** A 6 mm screw pokes through the plate toward the battery. |
| 3 | M2.5 x 6 flat head | plate → shell pillars |
| 4 | M2.5 x 8 pan head | Twist → lid |
| 4 | M2.5 x 4 pan head | OLED → lid (longer screws will dimple the lid face) |
| 1 | Mini SPDT slide switch, SS12D00G3-style (8.7 x 3.6 x 3.6 mm body, 3-pin, 2.54 mm pitch) | left wall, wired EN ↔ GND |
| 2 | ~6 cm of 28–30 AWG wire | switch to the Thing Plus EN and GND pins |
| 1 | Small square of 1 mm foam tape | behind the battery (optional anti-rattle) |

## Printing (Bambu X2D, PETG)

- 0.4 mm nozzle, 0.2 mm layers, 3–4 walls, 20% gyroid.
- No supports needed on any part.
- **Shell:** print back-down.
- **Lid:** print face-down. A textured PEI plate gives a nice front finish.
- **Plate:** print flat.
- **Knob:** print upright. Use clear or translucent PETG so the encoder's RGB light shows through the centre light pipe.
- **Plunger:** print upright, tip down. Use 0.12 mm layers for a clean 2.1 mm shaft.

## Assembly order

1. Press the 2 M3 inserts into the lid corner bosses. Drop the RESET plunger into its guide tube from inside the lid. Its collar keeps it from falling out the front.
2. Screw the OLED (face down, glass against the lid) and the Twist (encoder through the round hole) to the lid. Plug in Qwiic cables. OLED → Twist is a short hop.
3. Solder the slide switch: the centre pin to the Thing Plus **EN** pin and one outer pin to **GND**. Slide = off pulls EN low. Hold the switch against the left wall with the actuator through the slot and fix it with hot glue (there's no cradle; the plate has a notch so it drops in past the switch).
4. Put the battery in the shell. The lead exits toward the left side.
5. Screw the Thing Plus and the GPS to the plate, then drop the plate in over the battery. Route the battery lead up through the left notch into the Thing Plus JST. Screw the plate down (3x M2.5 flat head).
6. Connect Qwiic: Thing Plus → GPS → OLED → Twist. Both GPS Qwiic ports are usable. The one facing the top wall plugs into the pocket beside the SMA port.
7. Hook the lid's top tongues under the top wall, swing the bottom down, and fit the 2 M3 x 25 screws from the back.
8. Screw the antenna onto the SMA port. Zip-tie the cable to the anchor next to the port so tugs don't load the GPS board's edge connector.

## Measure before you print

These values were estimated or conflict between sources. Every one is a single parameter at the top of the `.scad` file.

- **`batt`:** SparkFun and DigiKey list 61 x 53.3 x 6.4 mm, but some resellers list 68.8 x 49.2 x 5.6 mm. The default pocket is 55 x 64 (2 mm longer than the listed cell, which measured tight in practice). If yours is the longer cell, it won't fit without reworking the layout.
- **`oled_glass_t`:** glass plus adhesive thickness (default 1.6). This sets the OLED boss height.
- **`enc_body` / `enc_hole_d`:** encoder body 12.4 x 13.4 x 7.8 mm, from a third-party model of COM-15141. The lid hole clears an M9 bushing.
- **`sw_body` / `sw_slot`:** the slide switch body and actuator slot. Measure your switch.
- **`sma_edge_gap` / `sma_port_d`:** the gap between the GPS board edge and the top wall, and the port opening size. If the plug won't thread fully, reduce the gap or enlarge the opening.

## Known limitations / next steps

- **External antenna.** The antenna rides outside the case on its 3 m cable. A small active patch antenna could later go inside the case, or in a snap-on cap over the port.
- **Board mods:** cut JP2 on the Thing Plus so firmware power-off doesn't fight the Qwiic rail's 10k pull-up. Details are in the firmware README.
- **Slow charging.** The Thing Plus charger runs at ~213 mA, so a full 2 Ah charge takes roughly 10 hours. Fine overnight, slow for a top-up.
- **No weather sealing** (per v0.1 scope).
- **No belt or cart clip yet.** The back is flat, so a clip or mount plate can be added later.
