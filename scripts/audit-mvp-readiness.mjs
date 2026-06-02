import { createServer } from 'vite';

const server = await createServer({
  appType: 'custom',
  logLevel: 'error',
  server: { middlewareMode: true, hmr: false },
});

try {
  const {
    buildMvpReadinessReport,
    formatMvpReadinessReport,
  } = await server.ssrLoadModule('/src/systems/MvpReadinessSystem.ts');
  const report = buildMvpReadinessReport(170);
  console.log(formatMvpReadinessReport(report));
  process.exitCode = report.readyForCompletion ? 0 : 1;
} finally {
  await server.close();
}
