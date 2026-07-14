const express = require('express');

const app = express();

// Azure App Service (Linux) injects the PORT environment variable —
// the app must listen on it (falls back to 8080 for local runs).
// test
const port = process.env.PORT || 8080;

app.get('/', (req, res) => {
  res.status(200).json({
    message: 'Hello from Azure App Service! good!! Very Hot',
    deployedVia: 'GitHub Actions self-hosted runner (Azure Container Apps + KEDA)',
    hostname: require('os').hostname(),
    timestamp: new Date().toISOString(),
  });
});

// Simple health check endpoint for App Service health check / smoke tests
app.get('/health', (req, res) => {
  res.status(200).send('OK');
});

app.listen(port, () => {
  console.log(`Server listening on port ${port}`);
});
