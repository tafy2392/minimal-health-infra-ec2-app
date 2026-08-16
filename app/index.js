'use strict';

const http = require('node:http');

const PORT       = process.env.PORT         || 3000;
const APP_SECRET = process.env.APP_SECRET   || '';
const REGION     = process.env.AWS_REGION   || 'eu-central-1';
const COMMIT     = process.env.GIT_COMMIT   || 'unknown';
const SERVICE    = 'rewards';

function json(res, status, body) {
  const payload = JSON.stringify(body);
  res.writeHead(status, {
    'Content-Type':   'application/json',
    'Content-Length': Buffer.byteLength(payload),
  });
  res.end(payload);
}

function requireSecret(req, res) {
  const header = req.headers['x-app-secret'];
  if (!APP_SECRET || header !== APP_SECRET) {
    json(res, 401, { error: 'Unauthorized' });
    return false;
  }
  return true;
}

const server = http.createServer((req, res) => {
  const { pathname } = new URL(req.url, `http://${req.headers.host}`);

  // Public — used by ALB target group and readiness checks
  if (pathname === '/healthz') {
    json(res, 200, { service: SERVICE, status: 'ok', commit: COMMIT, region: REGION });
    return;
  }

  // All other routes require the shared secret via X-App-Secret header
  if (!requireSecret(req, res)) return;

  if (pathname === '/') {
    json(res, 200, { service: SERVICE, commit: COMMIT, region: REGION });
    return;
  }

  json(res, 404, { error: 'Not found' });
});

server.listen(PORT, () => {
  console.log(`[${SERVICE}] listening on :${PORT}  commit=${COMMIT}  region=${REGION}`);
});
