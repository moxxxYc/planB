import { spawn } from 'node:child_process';
import { existsSync } from 'node:fs';
import { mkdir, rm, writeFile } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import { createServer } from 'vite';

const repoRoot = resolve(new URL('..', import.meta.url).pathname);
const chromeCandidates = [
  process.env.CHROME_PATH,
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  '/Applications/Chromium.app/Contents/MacOS/Chromium',
].filter(Boolean);

const chromePath = chromeCandidates.find((candidate) => existsSync(candidate));
if (!chromePath) {
  console.error(`No Chrome executable found. Set CHROME_PATH or install Google Chrome.`);
  process.exit(1);
}

const server = await createServer({
  root: repoRoot,
  appType: 'spa',
  logLevel: 'error',
  server: { host: '127.0.0.1', port: 0, hmr: false },
});

let chrome;
let ws;
let profileDir;

try {
  await server.listen();
  const localUrl = server.resolvedUrls?.local?.[0];
  if (!localUrl) throw new Error('Vite did not expose a local URL.');

  const { buildIdentitySmokePlan } = await server.ssrLoadModule('/src/systems/BuildVisualSmokeSystem.ts');
  const plan = buildIdentitySmokePlan('docs');
  const cdpPort = 9341 + Math.floor(Math.random() * 300);
  profileDir = `/tmp/planb-build-visuals-${Date.now()}`;
  await mkdir(profileDir, { recursive: true });

  chrome = spawn(chromePath, [
    '--headless=new',
    '--disable-gpu',
    '--hide-scrollbars',
    '--mute-audio',
    '--no-first-run',
    '--no-default-browser-check',
    `--remote-debugging-port=${cdpPort}`,
    `--user-data-dir=${profileDir}`,
    '--window-size=1280,720',
    'about:blank',
  ], { stdio: 'ignore' });

  const target = await getPageTarget(cdpPort);
  ws = await openCdpSocket(target.webSocketDebuggerUrl);
  const send = createCdpSender(ws);

  await send('Page.enable');
  await send('Runtime.enable');
  await send('Emulation.setDeviceMetricsOverride', {
    width: 1280,
    height: 720,
    deviceScaleFactor: 1,
    mobile: false,
  });
  await send('Page.navigate', { url: localUrl });
  await waitForCanvas(send);

  const results = [];
  for (const item of plan) {
    const applied = await send('Runtime.evaluate', {
      expression: `Boolean(window.planBAction) && (window.planBAction(${JSON.stringify(item.action)}), true)`,
      returnByValue: true,
    });
    if (!applied.result?.value) throw new Error(`Scene action failed: ${item.action}`);

    await delay(1100);
    const capture = await send('Page.captureScreenshot', {
      format: 'png',
      captureBeyondViewport: false,
    });
    const outputPath = resolve(repoRoot, item.outputPath);
    const bytes = Buffer.from(capture.data, 'base64');
    await mkdir(dirname(outputPath), { recursive: true });
    await writeFile(outputPath, bytes);
    results.push({ preset: item.displayName, outputPath: item.outputPath, bytes: bytes.length });
  }

  console.table(results);
} finally {
  ws?.close();
  if (chrome) {
    chrome.kill('SIGTERM');
    await Promise.race([
      new Promise((resolve) => chrome.once('exit', resolve)),
      delay(1000),
    ]);
  }
  if (profileDir) {
    try {
      await rm(profileDir, { recursive: true, force: true });
    } catch {
      // Chrome can keep a short-lived temp handle after shutdown; the OS temp path is disposable.
    }
  }
  await server.close();
}

function createCdpSender(socket) {
  let nextId = 1;
  const pending = new Map();
  socket.addEventListener('message', (event) => {
    const message = JSON.parse(event.data);
    if (!message.id || !pending.has(message.id)) return;
    const { resolve, reject } = pending.get(message.id);
    pending.delete(message.id);
    if (message.error) reject(new Error(JSON.stringify(message.error)));
    else resolve(message.result);
  });

  return (method, params = {}) => {
    const id = nextId++;
    socket.send(JSON.stringify({ id, method, params }));
    return new Promise((resolve, reject) => pending.set(id, { resolve, reject }));
  };
}

async function openCdpSocket(url) {
  const socket = new WebSocket(url);
  await new Promise((resolve, reject) => {
    socket.addEventListener('open', resolve, { once: true });
    socket.addEventListener('error', reject, { once: true });
  });
  return socket;
}

async function getPageTarget(port) {
  const deadline = Date.now() + 10000;
  while (Date.now() < deadline) {
    try {
      const response = await fetch(`http://127.0.0.1:${port}/json`);
      if (response.ok) {
        const targets = await response.json();
        const target = targets.find((item) => item.type === 'page') ?? targets[0];
        if (target?.webSocketDebuggerUrl) return target;
      }
    } catch {
      // Chrome may need a short moment before exposing the CDP endpoint.
    }
    await delay(100);
  }
  throw new Error('Chrome CDP endpoint did not become ready.');
}

async function waitForCanvas(send) {
  const deadline = Date.now() + 10000;
  while (Date.now() < deadline) {
    const ready = await send('Runtime.evaluate', {
      expression: 'document.readyState === "complete" && Boolean(document.querySelector("canvas"))',
      returnByValue: true,
    });
    if (ready.result?.value) return;
    await delay(100);
  }
  throw new Error('Phaser canvas did not render.');
}

function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
