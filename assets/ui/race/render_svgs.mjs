// Renders every SVG in ./svg to a transparent PNG in ./png at the SVG's own width/height.
// Usage (repo root): node assets/ui/race/render_svgs.mjs
// Needs Google Chrome; starts a headless copy on port 9334 and closes it afterwards.
import { spawn } from "node:child_process";
import { readdirSync, readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const svgDir = join(here, "svg"), pngDir = join(here, "png");
mkdirSync(pngDir, { recursive: true });
const port = 9334;
const chrome = spawn("C:/Program Files/Google/Chrome/Application/chrome.exe",
  ["--headless=new", `--remote-debugging-port=${port}`, `--user-data-dir=${join(tmpdir(), "race-svg-render")}`, "about:blank"], { stdio: "ignore" });
const sleep = ms => new Promise(r => setTimeout(r, ms));
let target;
for (let i = 0; i < 120 && !target; i++) {
  try { target = await (await fetch(`http://127.0.0.1:${port}/json/new?about:blank`, { method: "PUT" })).json(); } catch { await sleep(250); }
}
if (!target) { chrome.kill(); throw new Error("Chrome did not start"); }
const ws = new WebSocket(target.webSocketDebuggerUrl);
await new Promise(r => ws.addEventListener("open", r));
let id = 0; const waiting = new Map();
ws.addEventListener("message", e => { const m = JSON.parse(e.data); if (m.id && waiting.has(m.id)) { waiting.get(m.id)(m); waiting.delete(m.id); } });
const send = (method, params = {}) => new Promise(r => { const i = ++id; waiting.set(i, r); ws.send(JSON.stringify({ id: i, method, params })); });
await send("Page.enable");
await send("Emulation.setDefaultBackgroundColorOverride", { color: { r: 0, g: 0, b: 0, a: 0 } });
for (const file of readdirSync(svgDir).filter(f => f.endsWith(".svg"))) {
  const svg = readFileSync(join(svgDir, file), "utf8");
  const w = +svg.match(/width="(\d+)"/)[1], h = +svg.match(/height="(\d+)"/)[1];
  await send("Emulation.setDeviceMetricsOverride", { width: w, height: h, deviceScaleFactor: 1, mobile: false });
  const html = `<html><body style="margin:0;background:transparent">${svg}</body></html>`;
  await send("Page.navigate", { url: "data:text/html;base64," + Buffer.from(html).toString("base64") });
  await sleep(300);
  const shot = await send("Page.captureScreenshot", { format: "png", clip: { x: 0, y: 0, width: w, height: h, scale: 1 } });
  writeFileSync(join(pngDir, file.replace(/\.svg$/, ".png")), Buffer.from(shot.result.data, "base64"));
  console.log("rendered", file, w + "x" + h);
}
ws.close(); chrome.kill();
