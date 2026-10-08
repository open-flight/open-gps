# Round replay viewer

A single static page that replays a round exported from the shot tracker on a satellite map, shot by shot.

## Open it

- **From disk:** open `tools/replay/index.html` in a browser. No server or build step.
- **Served:** any static server works, e.g. `python3 -m http.server -d tools/replay`.
- **Load a round:** drop a file on the page or use *Open file…*. Use the output of `geojson <id>` or `csv <id>` from the USB serial console (see [firmware/README.md](../../firmware/README.md#exporting-rounds-usb-serial-115200)). Stray serial prompt lines around the export are fine.
- **Load sample** replays an embedded copy of `samples/sample-round.geojson`, a synthetic round (a real round moved to another location, rotated and re-timed). Deep links: `index.html#sample`, `#sample&shot=9`, `#sample&play`.

It needs a network connection for Leaflet (cdnjs) and the Esri World Imagery tiles. Offline, the scorecard and stats still work, but there's no map.

## Controls

| Key | Action |
|---|---|
| `←` / `→` | Previous / next shot |
| `↑` / `↓` | Previous / next hole |
| `Space` | Play / pause |
| `O` | Overview of the whole round |

You can also click a dot on the timeline, a scorecard row, a tee marker or a shot on the map.

## How shots are drawn

- **Full shots** fly from start to landing as an arc, with a ground shadow and a trail. Then the camera moves to the next shot.
- **Putts** only record where they were struck. A putt rolls to where the next stroke on the same hole started, because that's where the ball stopped. The last putt on a hole pulses in place. *Hole out* doesn't record a position, so the cup location can't be derived.
- **Full shots with no landing** (an unfinished or in-flight shot): if the next stroke on the hole has a position, a dashed line goes there with an approximate (`~`) distance. Otherwise the shot pulses in place.
- **Shots saved without GPS** count as strokes in the scorecard and timeline, but there's nothing to draw. The map shows a note instead.

## GeoJSON vs CSV

Both formats come from `storage.h` and parse to the same shots:

- **CSV is complete.** Every stroke gets a row. A row with no GPS has empty coordinates.
- **GeoJSON drops shots that have no start fix.** The viewer spots gaps in the per-hole `shot` numbers and adds those strokes back with an unknown club. A no-GPS shot that's the *last* stroke on a hole leaves no gap, so it can't be detected. Use the CSV if that matters.
- **Units:** GeoJSON states them (`"units"`). CSV doesn't, so the viewer compares distances with the coordinates to tell yards from metres.
- **Round status:** neither export says whether the round was finished, so the last hole is shown as recorded. A round's `startUnix` is `0` when GPS time wasn't known at the start. The viewer uses the first shot time instead.

## Tests

```sh
node tools/replay/parse.test.mjs
```

The parser lives inline in `index.html` as a classic `<script id="replay-parser">`. ES module imports fail from `file://` in Chrome, so it isn't a separate module. The test extracts that block, runs it in a Node VM and checks the following:

- `samples/sample-round.geojson` and `samples/sample-round.csv` give identical shots: 5 holes, H1=4, H2=4, H3=2, H4=4, H5=4, 18 strokes.
- The embedded sample matches `samples/sample-round.geojson`.
- Edge cases parse correctly: no-GPS shots, numbering gaps, putt-only holes, serial noise, and empty or invalid files.

If you change the embedded sample, keep it identical to `samples/sample-round.geojson` or update the test.
