import { createServer } from 'vite';

const seed = Number(process.argv[2] ?? 170);
const server = await createServer({
  appType: 'custom',
  logLevel: 'error',
  server: { middlewareMode: true, hmr: false },
});

try {
  const {
    buildProbeValidationReport,
    formatBuildProbeValidationReport,
  } = await server.ssrLoadModule('/src/systems/BuildProbeValidationSystem.ts');
  const report = buildProbeValidationReport(Number.isFinite(seed) ? seed : 170);
  console.log(formatBuildProbeValidationReport(report));
  process.exitCode = report.ok ? 0 : 1;
} finally {
  await server.close();
}
