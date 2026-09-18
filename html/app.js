/* LXR-BUSINESS — the ledger on the LXR UI Kit | © 2026 iBoss21 / LXRCore
   Works on the server's ledger: { job, grades[], staff[], headcount, wageBill, book, perms, cash, maxMove } + near[] from the client. */
(function () {
  const $ = (id) => document.getElementById(id);
  const app = $('app');
  const RES = (typeof GetParentResourceName === 'function') ? GetParentResourceName() : 'lxr-business';
  let D = null, L = {}, near = [];
  const t = (k, vars) => { let s = L[k] || k.split('.').pop().replace(/_/g, ' '); if (vars) for (const v in vars) s = s.replace('%{' + v + '}', vars[v]); return s; };
  const money = (n) => (Math.round((Number(n) || 0) * 100) / 100).toFixed(2);
  const esc = (s) => String(s == null ? '' : s).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  const post = (name, body) => fetch(`https://${RES}/${name}`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body || {}) }).then(r => r.json()).catch(() => ({ ok: false }));
  const sound = (name, set) => post('sound', { name, set });
  const pad = (i) => String(i).padStart(2, '0');

  let toastEl;
  function toast(msg, bad) {
    if (!toastEl) { toastEl = document.createElement('div'); toastEl.className = 'lxr-toast bz-toast'; document.body.appendChild(toastEl); }
    toastEl.textContent = msg; toastEl.classList.toggle('is-bad', !!bad); toastEl.classList.toggle('is-ok', !bad); toastEl.classList.add('show');
    setTimeout(() => toastEl.classList.remove('show'), 2500);
  }
  function applyLocale() { document.querySelectorAll('[data-l]').forEach(el => { const k = 'ui.' + el.dataset.l; if (L[k]) el.textContent = L[k]; }); }
  const gradeOptions = (sel, maxExclusive) => D.grades.filter(g => D.perms.boss || g.level < D.job.level).filter(g => maxExclusive == null || g.level < maxExclusive).map(g => `<option value="${g.level}" ${sel === g.level ? 'selected' : ''}>${esc(g.name)}</option>`).join('');

  function render() {
    $('job-label').textContent = D.job.label;
    const s = $('staff'); s.innerHTML = ''; $('staff-count').textContent = pad(D.staff.length);
    if (!D.staff.length) s.innerHTML = `<div class="bz-empty">${esc(t('ui.no_staff'))}</div>`;
    D.staff.forEach((p, i) => {
      const row = document.createElement('div'); row.className = 'bz-row';
      const manageable = D.perms.boss || p.level < D.job.level;
      row.innerHTML = `<span class="bz-row__i">${pad(i + 1)}</span><div><div class="bz-row__name">${esc(p.name)}</div><div class="bz-row__sub">${esc(p.grade)} · ${p.online ? `<span class="on">${esc(t(p.onduty ? 'ui.on_duty' : 'ui.online'))}</span>` : esc(t('ui.last_seen')) + ' ' + esc(String(p.lastSeen || '').slice(0, 10))}</div></div><span class="bz-row__wage">$${money(p.wage)}</span><div class="bz-row__ctl">${manageable && D.perms.promote ? `<select class="bz-sel">${gradeOptions(p.level)}</select>` : ''}${manageable && D.perms.fire ? `<button class="lxr-btn lxr-btn-ghost lxr-btn-sm">${esc(t('ui.let_go'))}</button>` : ''}</div>`;
      const sel = row.querySelector('select'); if (sel) sel.addEventListener('change', () => act('grade', { citizenid: p.citizenid, level: Number(sel.value) }));
      const btn = row.querySelector('button'); if (btn) btn.addEventListener('click', () => act('fire', { citizenid: p.citizenid }));
      s.appendChild(row);
    });
    $('balance').textContent = D.book.bankOn ? '$' + money(D.book.balance) : t('ui.no_bank');
    $('wagebill').textContent = t('ui.wage_bill', { amount: money(D.wageBill), n: D.staff.length });
    const f = $('book-form'); f.innerHTML = '';
    if (D.perms.society && D.book.bankOn) {
      f.innerHTML = `<input class="bz-in" id="b-amt" type="number" min="0.01" step="0.01" placeholder="0.00"><button class="lxr-btn lxr-btn-sm" id="b-in">${esc(t('ui.deposit'))}</button><button class="lxr-btn lxr-btn-ghost lxr-btn-sm" id="b-out">${esc(t('ui.withdraw'))}</button>`;
      $('b-in').addEventListener('click', () => act('book', { amount: Number($('b-amt').value) }));
      $('b-out').addEventListener('click', () => act('book', { amount: -Number($('b-amt').value) }));
    }
    const h = $('hire'); h.innerHTML = '';
    if (!D.perms.hire) h.innerHTML = `<div class="bz-empty">${esc(t('ui.no_hire_perm'))}</div>`;
    else if (!near.length) h.innerHTML = `<div class="bz-empty">${esc(t('ui.nobody_at_desk'))}</div>`;
    else near.forEach(n => {
      const row = document.createElement('div'); row.className = 'lxr-row';
      row.innerHTML = `<span class="lxr-row-body"><span class="lxr-row-name">${esc(t('ui.stranger_id', { id: n.id }))}</span></span><span class="lxr-grow"></span><select class="bz-sel">${gradeOptions(0)}</select><button class="lxr-btn lxr-btn-sm">${esc(t('ui.hire'))}</button>`;
      row.querySelector('button').addEventListener('click', () => act('hire', { id: n.id, level: Number(row.querySelector('select').value) }));
      h.appendChild(row);
    });
    const g = $('grades'); g.innerHTML = '';
    D.grades.forEach(gr => { const row = document.createElement('div'); row.className = 'lxr-row'; row.innerHTML = `<span class="lxr-row-body"><span class="lxr-row-name">${esc(gr.name)}</span><span class="lxr-row-sub">${esc(t('ui.grade'))} ${gr.level}${gr.boss ? ' · ' + esc(t('ui.boss')) : ''} · ${D.headcount[gr.level] || 0}</span></span><span class="lxr-grow"></span><span class="bz-row__wage">$${money(gr.payment)}</span>`; g.appendChild(row); });
  }
  async function act(name, body) {
    const r = await post(name, body);
    if (!r.ok) { if (r.why) toast(t('error.' + r.why), true); return; }
    if (r.data) { D = r.data; render(); }
    sound('NAV_UP');
  }
  $('btn-close').addEventListener('click', () => post('close'));
  document.addEventListener('keydown', (e) => { if (D && (e.key === 'Backspace' || e.key === 'Escape') && e.target.tagName !== 'INPUT' && e.target.tagName !== 'SELECT') post('close'); });

  function open(m) {
    D = m.data; L = m.locale || {}; near = m.near || [];
    document.body.classList.toggle('lang-ka', m.lang === 'ka');
    applyLocale(); app.classList.remove('lxr-hidden'); render();
  }
  window.addEventListener('message', e => {
    const m = e.data || {};
    if (m.theme || (m.brand && m.brand.theme)) document.documentElement.dataset.theme = m.theme || m.brand.theme;
    if (m.action === 'open') open(m);
    if (m.action === 'close') { app.classList.add('lxr-hidden'); D = null; }
  });
  if (window.__LXR_MOCK__) open(window.__LXR_MOCK__);
})();
