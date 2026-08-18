const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');

const root = __dirname;
const state = {
  environments: [
    { name: 'development', branch: 'main', status: 'Healthy', revision: 'a42f1d8', updatedAt: '2 min ago', policy: 'Passed' },
    { name: 'staging', branch: 'release', status: 'Healthy', revision: 'a42f1d8', updatedAt: '24 min ago', policy: 'Passed' },
    { name: 'production', branch: 'production', status: 'Synced', revision: '3db42ae', updatedAt: '3 h ago', policy: 'Passed' }
  ],
  activity: [
    { action: 'Sync completed', target: 'development', actor: 'GitHub Actions', time: '2 min ago' },
    { action: 'Policy checks passed', target: 'staging', actor: 'GitHub Actions', time: '24 min ago' },
    { action: 'Production promotion approved', target: 'production', actor: 'platform-team', time: '3 h ago' }
  ]
};

function json(res, status, value) {
  res.writeHead(status, { 'Content-Type': 'application/json; charset=utf-8' });
  res.end(JSON.stringify(value));
}
function body(req) { return new Promise((resolve, reject) => { let raw = ''; req.on('data', c => raw += c); req.on('end', () => { try { resolve(raw ? JSON.parse(raw) : {}); } catch { reject(new Error('Invalid JSON')); } }); }); }
function contentType(file) { return file.endsWith('.css') ? 'text/css' : file.endsWith('.js') ? 'application/javascript' : 'text/html'; }

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, 'http://localhost');
  if (req.method === 'GET' && url.pathname === '/api/status') return json(res, 200, state);
  if (req.method === 'POST' && url.pathname === '/api/sync') {
    try {
      const { environment } = await body(req);
      const target = state.environments.find(e => e.name === environment);
      if (!target) return json(res, 404, { error: 'Unknown environment' });
      target.status = 'Synced'; target.updatedAt = 'just now';
      state.activity.unshift({ action: 'Manual sync requested', target: environment, actor: 'operator', time: 'just now' });
      return json(res, 202, { ok: true, environment });
    } catch (error) { return json(res, 400, { error: error.message }); }
  }
  const file = url.pathname === '/' ? 'public/index.html' : `public${url.pathname}`;
  const absolute = path.resolve(root, file);
  if (!absolute.startsWith(path.join(root, 'public')) || !fs.existsSync(absolute)) return json(res, 404, { error: 'Not found' });
  res.writeHead(200, { 'Content-Type': `${contentType(absolute)}; charset=utf-8` }); fs.createReadStream(absolute).pipe(res);
});
if (require.main === module) server.listen(process.env.PORT || 3000, () => console.log('GitOps Pilot running on http://localhost:3000'));
module.exports = { server, state };
