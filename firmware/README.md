# Shot Tracker Firmware (v0.1)

Arduino firmware for the SparkFun Thing Plus ESP32-S3 with the NEO-M9N GPS, the Qwiic OLED 1.3" and the Qwiic Twist.

## Controls

There's one control, the dial:

- **Turn** to pick a club or move through menus.
- **Click** to select or to mark a position.
- **Hold** (0.7 s) to open the menu. Holding again closes it.

## Playing a round

1. From the home screen, choose **New round**. The round starts on hole 1.
2. **Pick a club.** Turn the dial and the club name shows on screen.
3. **Click at the ball.** The device averages GPS for 2.5 s ("Hold still"). That marks the start of the shot.
4. **Walk to the ball.** The screen shows the live distance from the start.
5. **Click at the ball again.** The landing point is marked and the shot distance is shown for 4 s.
6. **Putts:** select *Putter* and one click records the shot. There's no landing step. The dial stays on the putter for the next putt.
7. **Finish the hole:** turn one click past *Putter* to **Hole out** and click. That advances to the next hole. Holing out on 18 asks whether to finish the round.

**Dial LED colours**

| Colour | Meaning |
|---|---|
| Green | Ready |
| Blue | Shot in flight |
| White | Marking a position |
| Amber | No GPS fix |
| Purple | In a menu |

**Menu** (hold the dial during a round):

- Back
- Next hole
- Go to hole…
- Cancel this shot / Undo last shot (asks to confirm)
- Scorecard
- GPS status
- End round (asks to confirm)
- Power off

**Saved rounds** (home screen) lists the newest 9 rounds as `#id date shots`; `*` marks a round that was never finished. Click a round to delete it (asks to confirm, defaults to No). Older rounds appear as newer ones are deleted, or remove them over USB with `rm <id>`.

**If there's no GPS fix when you mark:** you get a choice of *Try again*, *Save without GPS* or *Cancel*. Save without GPS keeps the stroke count correct, but that shot has no distance.

## Storage and resume

- **Where rounds live:** in LittleFS on the internal flash. The round is rewritten after every change, using a temp file and a swap, so power loss can't corrupt it.
- **Resume:** a RESET, a dead battery or the EN switch mid-round all come back to the same hole and the same shot. That includes a shot that's still in flight.
- **Capacity:** 250 shots per round. The 1.5 MB partition holds hundreds of rounds.

## Exporting rounds (USB serial, 115200)

| Command | Output |
|---|---|
| `ls` | List rounds (id, shots, done/active) |
| `geojson <id>` | Export as GeoJSON. Each shot is a start→landing line and each putt is a point. Properties include club, distance and accuracy. |
| `csv <id>` | Export as CSV, one row per shot |
| `rm <id>` | Delete a round |
| `gps` | Current fix |

To replay a round on a satellite map, save the `geojson` or `csv` output to a file and open it in the round replay viewer: open [`tools/replay/index.html`](../tools/replay/index.html) in a browser (straight from disk is fine) and drop the file on it. It walks through the round shot by shot with a scorecard and per-club stats. See [`tools/replay/README.md`](../tools/replay/README.md). The CSV is the complete record: the GeoJSON leaves out shots saved without GPS.

## Power

The *Power off* menu item:

1. Saves the round.
2. Cuts the Qwiic rail with GPIO45, which switches off the GPS, OLED and Twist.
3. Holds that pin low.
4. Deep-sleeps with no wake source.

To wake it, press the **RESET** button on the lid. The **EN slide switch** on the side is the hard off. It disables the main 3.3 V regulator, and the battery still charges over USB while it's off.

**Recommended board mods** (cut-trace jumpers on the Thing Plus):

- **JP2:** the rail's default pull-up. Cut it so the Qwiic rail defaults *off*. Otherwise GPIO45 fights a 10k pull-up (about 330 µA) the whole time the device is "off". The firmware drives the pin high at boot either way, so nothing else changes.
- **JP1:** the red power LED. It's optional to cut, and it saves roughly 1 mA+ while running.

## Building

**Arduino IDE 2 or arduino-cli, with the Espressif ESP32 core:**

- **Board:** *SparkFun ESP32-S3 Thing Plus* in core 3.x. On older 2.0.x cores, use *ESP32S3 Dev Module* with 4 MB flash.
- **USB CDC On Boot:** *Enabled*. This is needed for serial over the USB-C port.
- **Partition scheme:** *Default 4MB with spiffs*. LittleFS uses the spiffs partition.

**Libraries** (Library Manager):

- SparkFun u-blox GNSS v3
- SparkFun Qwiic OLED Arduino Library
- SparkFun Qwiic Twist Arduino Library
- SparkFun MAX1704x Fuel Gauge Arduino Library

```
arduino-cli compile -b "esp32:esp32:sparkfun_esp32s3_thing_plus:CDCOnBoot=cdc,PartitionScheme=default" firmware/shot_tracker
```

## Flashing

Do the first flash **before you close the case**. The BOOT button you may need for recovery sits under the Twist once the lid is on.

### One-time setup

**Arduino IDE 2:**

1. Go to *Settings → Additional boards manager URLs* and add
   `https://espressif.github.io/arduino-esp32/package_esp32_index.json`
2. In *Boards Manager*, install **esp32 by Espressif Systems**.
3. In *Library Manager*, install the four libraries listed under Building.

**arduino-cli:**
```
arduino-cli config add board_manager.additional_urls https://espressif.github.io/arduino-esp32/package_esp32_index.json
arduino-cli core update-index
arduino-cli core install esp32:esp32
arduino-cli lib install "SparkFun u-blox GNSS v3" "SparkFun Qwiic OLED Arduino Library" \
  "SparkFun Qwiic Twist Arduino Library" "SparkFun MAX1704x Fuel Gauge Arduino Library"
```

### Upload

1. Plug the Thing Plus into your computer over USB-C. Use a data cable; some charge-only cables won't show up.
2. Pick the port:

   | OS | Port name |
   |---|---|
   | macOS | `/dev/cu.usbmodem…` |
   | Linux | `/dev/ttyACM0` (your user needs to be in the `dialout` group) |
   | Windows | `COMx` |

3. **Arduino IDE:** open `firmware/shot_tracker/shot_tracker.ino`.
   - Set *Tools → Board* to **SparkFun ESP32-S3 Thing Plus**. On older 2.0.x cores, use *ESP32S3 Dev Module* with Flash Size = 4MB.
   - Set *USB CDC On Boot* to **Enabled**.
   - Set *Partition Scheme* to **Default 4MB with spiffs**.
   - Then click **Upload**.
4. **arduino-cli:**
   ```
   arduino-cli board listall | grep -i "thing plus"      # confirm the board ID on your core version
   arduino-cli compile --upload -p /dev/cu.usbmodem101 \
     -b "esp32:esp32:sparkfun_esp32s3_thing_plus:CDCOnBoot=cdc,PartitionScheme=default" \
     firmware/shot_tracker
   ```
   On Apple Silicon without Rosetta, add `--build-property tools.ctags.path=$PWD/tools/noop-ctags` (see the top-level README). Keep `CDCOnBoot=cdc`.
5. Open a serial monitor at 115200. On boot it prints `oled=1 twist=1 gps=1 fuel=1 fs=1`. A `0` means that part wasn't found; check its Qwiic cable. Type `help` for the export commands.

The first boot formats the storage partition, which takes a few seconds with a blank screen. That's normal.

### If the upload fails or the port disappears

Normally the ESP32-S3 resets itself into upload mode over USB. If the firmware crashes early, or the port never appears:

1. Open the case.
2. **Hold BOOT, tap RESET, then release BOOT.** The board is now in upload mode and a port should appear. It may have a different name than usual.
3. Upload again.
4. Press RESET afterwards to run the new firmware. The board doesn't always leave upload mode on its own.

**The EN slide switch has to be ON.** With it off the board has no 3.3 V and won't show up over USB, even though the battery is still charging.

### Saved rounds and reflashing

- **Rounds survive normal uploads.** They live in a separate flash partition.
- **These wipe every saved round**, so export first (`ls`, then `geojson <id>`):
  - turning on *Erase All Flash Before Sketch Upload*
  - changing the *Partition Scheme*
  - running `esptool erase_flash`
- **Changing the storage format** (bumping `ROUND_VERSION` in `model.h`) makes older rounds unreadable. They stay on flash but won't load.

**Code layout:**

| File | Contents |
|---|---|
| `config.h` | Clubs, units, timings, GPS averaging |
| `model.h` | Round/shot structs and distance maths |
| `storage.h` | LittleFS persistence and GeoJSON/CSV export |
| `gps.h` | GNSS wrapper and averaged marking |
| `input.h` | Dial click/long-press handling |
| `ui.h` | OLED helpers |
| `app.cpp` | State machine, screens and serial commands |

**Host simulation:** `make -C firmware/test` builds the real `app.cpp` against stubbed hardware with sanitizers. It plays a scripted round: drives, putts, hole-out, cancel, undo, a RESET mid-shot, a no-fix save, going to hole 18, finishing, exporting and power-off. It asserts the results and checks that no text or graphics run off the 128×64 display.

## Not in v0.1

- Penalty strokes and provisional balls.
- Picking which club list to carry.
- Pin or green positions.
- Auto sleep between holes.
- BLE sync to a phone.

The GeoJSON properties are meant to be the starting point for the course-overlay viewer.
