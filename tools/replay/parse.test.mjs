// Parser tests for the round replay viewer. No dependencies: `node tools/replay/parse.test.mjs`.
//
// The parser lives inline in index.html (so the page works from file://, where Chrome blocks
// ES module imports). This test pulls the <script id="replay-parser"> block out of the page and
// runs it in a fresh VM context, so it tests exactly the code the page runs.
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import vm from 'node:vm';
import assert from 'node:assert/strict';

const here = dirname(fileURLToPath(import.meta.url));
const html = readFileSync(join(here, 'index.html'), 'utf8');

const src = html.match(/<script id="replay-parser">([\s\S]*?)<\/script>/);
assert.ok(src, 'index.html has a <script id="replay-parser"> block');
const ctx = {};
vm.runInNewContext(src[1], ctx);
const { parse } = ctx.ReplayParse;

let passed = 0;
function test(name, fn) {
  try { fn(); passed++; console.log('ok   ' + name); }
  catch (e) { console.error('FAIL ' + name + '\n     ' + e.message); process.exitCode = 1; }
}
const strokesByHole = (r) => Object.fromEntries(r.holes.map((h) => [h.hole, h.strokes]));
const summary = (r) => r.shots.map((s) => [s.hole, s.n, s.club, s.putt, s.distance, s.startUnix,
  s.start && [s.start.lat, s.start.lon, s.start.acc], s.end && [s.end.lat, s.end.lon, s.end.acc]]);

const geoText = readFileSync(join(here, 'samples', 'sample-round.geojson'), 'utf8');
const csvText = readFileSync(join(here, 'samples', 'sample-round.csv'), 'utf8');
const EXPECTED = { 1: 4, 2: 4, 3: 2, 4: 4, 5: 4 };

test('sample round GeoJSON: 5 holes, 18 strokes, H1=4 H2=4 H3=2 H4=4 H5=4', () => {
  const r = parse(geoText, 'sample round.geojson');
  assert.equal(r.format, 'geojson');
  assert.equal(r.roundId, 1);
  assert.equal(r.units, 'yds');
  assert.equal(r.startUnix, null, 'startUnix 0 means unknown');
  assert.equal(r.totalStrokes, 18);
  assert.deepEqual({ ...strokesByHole(r) }, EXPECTED);
  assert.equal(r.totalPutts, 8);
});

test('sample round CSV: same strokes per hole', () => {
  const r = parse(csvText, 'sample round.csv');
  assert.equal(r.format, 'csv');
  assert.equal(r.units, 'yds', 'units inferred from distance vs coordinates');
  assert.equal(r.unitsGuessed, false);
  assert.deepEqual({ ...strokesByHole(r) }, EXPECTED);
});

test('sample round GeoJSON and CSV produce identical shots', () => {
  const g = parse(geoText), c = parse(csvText);
  assert.deepEqual(JSON.parse(JSON.stringify(summary(g))), JSON.parse(JSON.stringify(summary(c))));
});

test('shot details: drive, putts, roll targets, timing', () => {
  const r = parse(geoText);
  const s = r.shots[0];
  assert.equal(s.club, 'Driver'); assert.equal(s.distance, 216); assert.equal(s.putt, false);
  assert.equal(s.start.acc, 0.6); assert.equal(s.end.lat, 36.5691204); assert.equal(s.end.lon, -121.9462869);
  const p1 = r.shots[2], p2 = r.shots[3];
  assert.equal(p1.putt, true); assert.equal(p1.distance, null); assert.equal(p1.end, null);
  assert.equal(p1.restPoint, p2.start, 'first putt rolls to where the second putt started');
  assert.equal(p2.restPoint, null, 'last putt has no hole-out position');
  assert.equal(p2.holedOut, true);
  assert.equal(r.shots[1].sincePrev, 1780358693 - 1780358400);
  assert.equal(r.shots[4].n, 1); assert.equal(r.shots[4].of, 4);
});

test('club stats', () => {
  const r = parse(csvText);
  const by = Object.fromEntries(r.clubs.map((c) => [c.club, c]));
  assert.equal(by.Driver.count, 3); assert.equal(by.Driver.max, 291);
  assert.equal(Math.round(by.Driver.avg), Math.round((216 + 266 + 291) / 3));
  assert.equal(by.GW.count, 2); assert.equal(by.Putter.count, 8); assert.equal(by.Putter.avg, null);
  assert.equal(r.clubs[r.clubs.length - 1].club, 'Putter', 'putter sorts last');
});

test('embedded sample in index.html matches samples/sample-round.geojson', () => {
  const m = html.match(/<script type="application\/json" id="sample-round">([\s\S]*?)<\/script>/);
  assert.ok(m);
  assert.deepEqual(JSON.parse(m[1]), JSON.parse(geoText));
});

// ---- edge cases (formats as written by storage.h exportGeoJSON / exportCSV) ----

const HDR = 'hole,shot,club,putt,start_lat,start_lon,start_acc_m,end_lat,end_lon,end_acc_m,distance,start_unix,end_unix';

test('CSV: shot saved without GPS has no geometry but counts as a stroke', () => {
  const r = parse([HDR,
    '1,1,Driver,0,,,,,,,-1,0,0',
    '1,2,PW,0,36.57,-121.95,0.5,36.571,-121.951,0.6,140,1780358693,1780358889',
    '1,3,Putter,1,36.5711,-121.9511,0.5,,,,-1,1780359020,0', ''].join('\n'));
  assert.equal(r.totalStrokes, 3);
  assert.equal(r.shots[0].noGps, true); assert.equal(r.shots[0].start, null); assert.equal(r.shots[0].club, 'Driver');
});

test('GeoJSON: gaps in shot numbering become no-GPS strokes', () => {
  const f = (hole, shot, putt) => ({ type: 'Feature', geometry: { type: 'Point', coordinates: [-121.95, 36.57] },
    properties: { hole, shot, club: putt ? 'Putter' : '7 Iron', distance: -1, putt, startAccM: 0.5, endAccM: 0, startUnix: 0, endUnix: 0 } });
  const r = parse(JSON.stringify({ type: 'FeatureCollection', properties: { round: 2, startUnix: 0, units: 'm' },
    features: [f(1, 2, false), f(1, 4, true), f(2, 1, true)] }));
  assert.deepEqual({ ...strokesByHole(r) }, { 1: 4, 2: 1 });
  assert.equal(r.shots[0].inferred, true); assert.equal(r.shots[2].inferred, true);
  assert.equal(r.units, 'm');
  assert.ok(r.warnings.some((w) => /inferred/.test(w)));
  assert.equal(parse(geoText).warnings.length, 0, 'clean sample round export has no warnings');
});

test('holes with only putts, full shot with no landing, unfinished round', () => {
  const r = parse([HDR,
    '1,1,Putter,1,36.57,-121.95,0.5,,,,-1,100,0',
    '2,1,Driver,0,36.58,-121.96,0.5,,,,-1,200,0', ''].join('\n'));
  assert.deepEqual({ ...strokesByHole(r) }, { 1: 1, 2: 1 });
  assert.equal(r.shots[1].putt, false); assert.equal(r.shots[1].end, null); assert.equal(r.shots[1].restPoint, null);
  assert.equal(r.unitsGuessed, true);
});

test('serial noise around the export is tolerated', () => {
  const r = parse('> geojson 6\r\n' + geoText.trim() + '\r\n> ');
  assert.equal(r.totalStrokes, 18);
  const c = parse('> csv 6\r\n' + csvText.replace(/\n/g, '\r\n') + '> ');
  assert.equal(c.totalStrokes, 18);
});

test('empty and invalid files give friendly errors', () => {
  for (const [text, re] of [
    ['', /empty/], ['   \n', /empty/],
    ['{"type":"FeatureCollection","features":[', /valid JSON/],
    ['{"type":"FeatureCollection","properties":{},"features":[]}', /No shots/],
    ['{"foo":1}', /FeatureCollection/],
    [HDR + '\n', /No shots/],
    ['hello world', /doesn't look like/],
  ]) {
    assert.throws(() => parse(text), (e) => e.friendly === true && re.test(e.message), JSON.stringify(text));
  }
});

console.log(`\n${passed} passed${process.exitCode ? ', some FAILED' : ''}`);
