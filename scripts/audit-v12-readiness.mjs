import { createServer } from 'vite';

const server = await createServer({
  appType: 'custom',
  logLevel: 'error',
  server: { middlewareMode: true, hmr: false },
});

try {
  const {
    buildV12ReadinessReport,
    formatV12ReadinessReport,
  } = await server.ssrLoadModule('/src/systems/V12ReadinessSystem.ts');
  const report = buildV12ReadinessReport(170);
  console.log(formatV12ReadinessReport(report));
} finally {
  await server.close();
}
