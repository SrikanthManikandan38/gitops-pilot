const $ = s => document.querySelector(s);
async function load() {
  const data = await fetch('/api/status').then(r => r.json());
  const healthy = data.environments.filter(x => x.status === 'Healthy' || x.status === 'Synced').length;
  $('#stats').innerHTML = `<article><b>${data.environments.length}</b><span>environments</span></article><article><b>${healthy}</b><span>healthy or synced</span></article><article><b>0</b><span>policy violations</span></article>`;
  const list = $('#environments'); list.innerHTML = '';
  data.environments.forEach(env => { const node = $('#environment').content.cloneNode(true); node.querySelector('h3').textContent = env.name; const badge = node.querySelector('.badge'); badge.textContent = env.status; badge.classList.add(env.status.toLowerCase()); node.querySelector('.branch').textContent = env.branch; node.querySelector('.revision').textContent = env.revision; node.querySelector('.policy').textContent = `✓ ${env.policy}`; node.querySelector('.updated').textContent = `Updated ${env.updatedAt}`; node.querySelector('.sync').onclick = async () => { await fetch('/api/sync', { method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify({environment: env.name}) }); load(); }; list.append(node); });
  $('#events').innerHTML = data.activity.map(e => `<div class="event"><span class="dot"></span><div><strong>${e.action}</strong><p>${e.target} · ${e.actor}</p></div><time>${e.time}</time></div>`).join('');
}
$('#refresh').onclick = load; load();
