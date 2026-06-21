#!/usr/bin/env node
// Extracts Korean radio station stream URLs from radio-korea.com.
// The site ships an AES-256-CFB encrypted stream descriptor per page; we
// replicate the site's client-side decryption (see radio-detail JS bundle).
import crypto from "node:crypto";
import fs from "node:fs";

const BASE = "https://www.radio-korea.com";
const UA =
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120 Safari/537.36";

// path -> display name (scraped from the radio-korea.com directory)
const STATIONS = JSON.parse(fs.readFileSync(new URL("./station_list.json", import.meta.url)));

// key derivation: cycle the timestamp string's char codes into a 32-byte hex key
function deriveKeyHex(ts) {
  let out = "";
  let o = 0;
  for (let r = 0; r < 32; r++) {
    out += ts.charCodeAt(o).toString(16).padStart(2, "0");
    o = (o + 1) % ts.length;
  }
  return out;
}

// CryptoJS AES.decrypt strips PKCS7 padding by default even in CFB mode;
// Node's aes-256-cfb does not, so we strip it manually.
function stripPKCS7(buf) {
  if (buf.length === 0) return buf;
  const pad = buf[buf.length - 1];
  if (pad < 1 || pad > 16 || pad > buf.length) return buf;
  for (let i = buf.length - pad; i < buf.length; i++) {
    if (buf[i] !== pad) return buf;
  }
  return buf.subarray(0, buf.length - pad);
}

function decryptStream(cipher, ivHex, ts) {
  const b64 = String(cipher).replace(/-/g, "+").replace(/_/g, "/");
  const ct = Buffer.from(b64, "base64");
  const key = Buffer.from(deriveKeyHex(ts), "hex");
  const iv = Buffer.from(ivHex, "hex");
  const d = crypto.createDecipheriv("aes-256-cfb", key, iv);
  const plain = stripPKCS7(Buffer.concat([d.update(ct), d.final()]));
  return plain.toString("utf8").trim();
}

function extract(re, html) {
  const m = html.match(re);
  return m ? m[1] : null;
}

async function fetchStation(path, name) {
  const url = `${BASE}${path}`;
  const res = await fetch(url, { headers: { "User-Agent": UA } });
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  const html = await res.text();

  const ts = extract(/id="last-update"[^>]*data-timestamp="([^"]+)"/, html);
  const jsonRaw = extract(
    /<script[^>]*id="radio-streams-json"[^>]*>([\s\S]*?)<\/script>/,
    html
  );
  const logo =
    extract(/class="radio-player__logo"[^>]*src="([^"]+)"/, html) ||
    extract(/<img[^>]*class="radio-player__logo"[^>]*src="([^"]+)"/, html) ||
    extract(/srcset="(https:\/\/static\.mytuner[^"]+)"/, html);
  const freq = extract(/class="radio-player__frequency"[^>]*data-text="([^"]+)"/, html);
  const genre = extract(/radio-player__genre-tag[^>]*>([^<]+)</, html);

  if (!ts || !jsonRaw) throw new Error("no stream descriptor");
  const streams = JSON.parse(jsonRaw.trim());

  const urls = [];
  for (const s of streams) {
    if (!s || s.type === "mms") continue;
    const u = decryptStream(s.cipher, s.iv, ts);
    if (u) urls.push({ url: u, type: s.type || "unknown" });
  }
  // prefer https hls
  urls.sort((a, b) => {
    const score = (x) =>
      (x.url.startsWith("https") ? 2 : 0) + (x.type === "hls" ? 1 : 0);
    return score(b) - score(a);
  });
  if (!urls.length) throw new Error("no decryptable streams");

  // Some stations encode the dynamic child playlist (chunklist.m3u8), which can
  // 404; the sibling master playlist.m3u8 is stable. Prefer the master, keep
  // the original as a fallback.
  let primary = urls[0].url;
  const rest = urls.slice(1).map((x) => x.url);
  if (/\/chunklist\.m3u8(\?|$)/.test(primary)) {
    const master = primary.replace(/\/chunklist\.m3u8/, "/playlist.m3u8");
    rest.unshift(primary);
    primary = master;
  }

  return {
    id: path.replace(/^\//, ""),
    name,
    streamURL: primary,
    streamType: urls[0].type,
    alternateURLs: [...new Set(rest)],
    logoURL: logo || null,
    frequency: freq || null,
    genre: genre || null,
  };
}

const results = [];
const failures = [];
const entries = Object.entries(STATIONS);

// modest concurrency to be polite
const CONC = 6;
let cursor = 0;
async function worker() {
  while (cursor < entries.length) {
    const i = cursor++;
    const [path, name] = entries[i];
    try {
      const r = await fetchStation(path, name);
      results.push(r);
      process.stdout.write(`✓ ${r.name} -> ${r.streamURL}\n`);
    } catch (e) {
      failures.push({ path, name, error: e.message });
      process.stdout.write(`✗ ${name} (${path}): ${e.message}\n`);
    }
  }
}
await Promise.all(Array.from({ length: CONC }, worker));

results.sort((a, b) => a.name.localeCompare(b.name, "ko"));
const outDir = new URL("../Sources/meradio/Resources/", import.meta.url);
fs.mkdirSync(outDir, { recursive: true });
fs.writeFileSync(new URL("stations.json", outDir), JSON.stringify(results, null, 2));

console.log(`\nDone. ${results.length} stations extracted, ${failures.length} failed.`);
if (failures.length) console.log("Failures:", JSON.stringify(failures, null, 2));
