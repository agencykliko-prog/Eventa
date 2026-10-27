/* Eventa · landing page : mascottes, révélations, simulateur, démo. */
(() => {
  const reduce = matchMedia('(prefers-reduced-motion: reduce)').matches;
  const fcfa = (n) => Math.round(n).toLocaleString('fr-FR').replace(/ | /g, ' ');

  /* ── Mascottes ─────────────────────────────────────────
     data-mascot="red_jump" : rouge = organisateurs, verte = créateurs. */
  const poses = {
    red: ['red_jump', 'red_thumbs', 'red_peace', 'red_cheeks'],
    green: ['green_jump', 'green_thumbs', 'green_peace', 'green_wave'],
  };
  const src = (name) => `img/mascots/${name}.webp`;
  const mascots = [];
  document.querySelectorAll('[data-mascot]').forEach((host) => {
    const name = host.dataset.mascot;
    const img = new Image();
    img.className = 'm-img';
    img.src = src(name);
    img.alt = '';
    img.draggable = false;
    img.style.animationDelay = `${-Math.random() * 3}s`;
    host.appendChild(img);
    const m = { host, img, name, team: name.split('_')[0] };
    mascots.push(m);
    if (!host.hasAttribute('data-interactive')) return;
    host.setAttribute('role', 'button');
    host.setAttribute('aria-label', 'Mascotte Eventa');
    host.tabIndex = 0;
    const jump = () => {
      // Petit saut et nouvelle pose.
      const list = poses[m.team];
      const next = list[(list.indexOf(m.img.src.split('/').pop().replace('.webp', '')) + 1) % list.length];
      m.img.classList.remove('jump');
      void m.img.offsetWidth;
      m.img.classList.add('jump');
      setTimeout(() => { m.img.src = src(next); }, 220);
    };
    host.addEventListener('click', jump);
    host.addEventListener('keydown', (e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); jump(); } });
    img.addEventListener('animationend', () => img.classList.remove('jump', 'swap'));
  });
  // Toutes les poses en cache : les changements sont instantanés.
  Object.values(poses).flat().forEach((n) => { const i = new Image(); i.src = src(n); });

  // Les mascottes se penchent vers le pointeur.
  let px = innerWidth / 2, py = innerHeight / 3, leanQueued = false;
  const lean = () => {
    leanQueued = false;
    mascots.forEach(({ host }) => {
      const r = host.getBoundingClientRect();
      if (r.bottom < 0 || r.top > innerHeight) return;
      const dx = px - (r.left + r.width / 2);
      const k = Math.max(-1, Math.min(1, dx / 400));
      host.style.setProperty('--lean', `${(k * 8).toFixed(1)}deg`);
    });
  };
  if (!reduce) {
    addEventListener('pointermove', (e) => {
      px = e.clientX; py = e.clientY;
      if (!leanQueued) { leanQueued = true; requestAnimationFrame(lean); }
    }, { passive: true });
  }

  /* ── Bandeau défilant : contenu doublé pour une boucle sans couture ── */
  const track = document.querySelector('.marquee-track');
  if (track) track.innerHTML += track.innerHTML.replace(/<span>/g, '<span aria-hidden="true">');

  /* ── Titres découpés en mots ─────────────────────────── */
  document.querySelectorAll('.split').forEach((h) => {
    const words = h.textContent.trim().split(/\s+/);
    h.setAttribute('aria-label', h.textContent.trim());
    h.innerHTML = words.map((w, i) => `<span class="w" aria-hidden="true"><span style="--i:${i}">${w}</span></span>`).join(' ');
  });

  /* ── Compteurs ───────────────────────────────────────── */
  const countTo = (el, to) => {
    const from = parseInt((el.textContent || '0').replace(/\D/g, ''), 10) || 0;
    if (reduce) { el.textContent = fcfa(to); return; }
    const t0 = performance.now(), dur = 1100;
    const step = (t) => {
      const k = Math.min(1, (t - t0) / dur), e = 1 - Math.pow(1 - k, 3);
      el.textContent = fcfa(from + (to - from) * e);
      if (k < 1) requestAnimationFrame(step);
    };
    requestAnimationFrame(step);
  };

  /* ── Révélations au défilement ───────────────────────── */
  const io = new IntersectionObserver((entries) => entries.forEach((en) => {
    if (!en.isIntersecting) return;
    const el = en.target;
    el.classList.add('in');
    el.querySelectorAll('[data-count]').forEach((c) => countTo(c, +c.dataset.count));
    if (el.matches('[data-chat]')) playChat(el);
    io.unobserve(el);
  }), { threshold: .2, rootMargin: '0px 0px -8% 0px' });
  document.querySelectorAll('.reveal, .split, [data-chat]').forEach((el, i) => {
    if (el.matches('.reveal')) el.style.transitionDelay = `${(i % 4) * 70}ms`;
    io.observe(el);
  });

  /* ── Conversation WhatsApp ───────────────────────────── */
  function playChat(chat) {
    const items = [...chat.querySelectorAll('.chat-body > *')];
    items.forEach((it, i) => setTimeout(() => it.classList.add('shown'), reduce ? 0 : 300 + i * 900));
  }

  /* ── Simulateur de budget ────────────────────────────── */
  const $ = (id) => document.getElementById(id);
  const sb = $('simBudget'), sg = $('simGuests');
  const shares = { lineVenue: .32, lineFood: .22, lineDeco: .18, lineMusic: .12 };
  const rest = document.querySelector('.donut-center b');
  const sim = () => {
    const b = +sb.value, g = +sg.value;
    $('simBudgetOut').textContent = `${fcfa(b)} FCFA`;
    $('simGuestsOut').textContent = g;
    $('simPerGuest').textContent = `${fcfa(b / g)} FCFA`;
    Object.entries(shares).forEach(([id, s]) => { $(id).textContent = fcfa(b * s); });
    rest.dataset.count = Math.round(b * .37);
    if (rest.closest('.in')) countTo(rest, b * .37);
  };
  if (sb && sg) { sb.addEventListener('input', sim); sg.addEventListener('input', sim); sim(); }

  /* ── Liens vers l'application de démo ────────────────── */
  // En ligne, l'application est servie sous /app/ ; en local, par le serveur de démo (port 8080).
  const local = !location.hostname || location.port === '8090';
  const base = local ? `http://${location.hostname || 'localhost'}:8080/#` : `${location.origin}/app/#`;
  const app = (path) => base + path;
  document.querySelectorAll('[data-demo]').forEach((a) => { a.href = app('/connexion'); a.target = '_blank'; a.rel = 'noopener'; });
  document.querySelectorAll('[data-demo-pro]').forEach((a) => { a.href = app('/connexion?profil=creator'); a.target = '_blank'; a.rel = 'noopener'; });
  document.querySelectorAll('[data-app-link]').forEach((a) => { a.href = app(a.dataset.appLink); a.target = '_blank'; a.rel = 'noopener'; });

  const frame = document.querySelector('[data-demo-frame]');
  if (frame) {
    const shell = frame.closest('.phone-live');
    fetch(base.replace('/#', '/'), { mode: 'no-cors', cache: 'no-store' })
      .then(() => { frame.src = app('/connexion'); })
      .catch(() => shell.classList.add('offline'));
  }

  /* ── Menu mobile ─────────────────────────────────────── */
  const burger = document.querySelector('.burger'), nav = document.querySelector('.pill-nav');
  burger.addEventListener('click', () => {
    const open = burger.getAttribute('aria-expanded') !== 'true';
    burger.setAttribute('aria-expanded', open);
    nav.classList.toggle('open', open);
  });
  nav.querySelectorAll('.nav-links a').forEach((a) => a.addEventListener('click', () => {
    burger.setAttribute('aria-expanded', 'false'); nav.classList.remove('open');
  }));
})();
