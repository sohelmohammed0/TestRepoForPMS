const http = require('http');

const PORT = process.env.PORT || 3000;

const server = http.createServer((req, res) => {
  if (req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'ok' }));
    return;
  }

  if (req.url === '/env') {
    // Only show key names — never values
    const SYSTEM_KEYS = ['PATH', 'HOME', 'HOSTNAME', 'NODE_VERSION', 'YARN_VERSION', 'TERM', 'SHLVL', 'PWD'];
    const keys = Object.keys(process.env).filter(k => !SYSTEM_KEYS.includes(k));
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ loaded_keys: keys }, null, 2));
    return;
  }

  res.writeHead(200, { 'Content-Type': 'text/plain' });
  res.end('App running. Visit /health or /env\n');
});

server.listen(PORT, () => {
  console.log(`[app] Running on port ${PORT}`);
  console.log(`[app] Visit http://localhost:${PORT}/env to verify SSM keys are loaded`);
});