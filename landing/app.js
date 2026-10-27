/* Eventa · landing page : mascottes, confettis, révélations, simulateur, démo. */
(() => {
  const reduce = matchMedia('(prefers-reduced-motion: reduce)').matches;
  const fcfa = (n) => Math.round(n).toLocaleString('fr-FR').replace(/ | /g, ' ');

  /* ── Mascottes ───────────────────────────────────────── */
  const tpl = document.getElementById('mascot-tpl');
  const shade = (hex, amt) => {
    const n = parseInt(hex.slice(1), 16);
    const mix = (c) => Math.round(amt < 0 ? c * (1 + amt) : c + (255 - c) * amt);
    const r = mix(n >> 16), g = mix((n >> 8) & 255), b = mix(n & 255);
    return `rgb(${r},${g},${b})`;
  };
  const mascots = [];
  document.querySelectorAll('[data-mascot]').forEach((host) => {
    const svg = tpl.content.firstElementChild.cloneNode(true);
    const c = host.dataset.mascot || '#FF8A3D';
    svg.style.setProperty('--mc', c);
    svg.style.setProperty('--ml', shade(c, .4));
    svg.style.setProperty('--md', shade(c, -.28));
    host.appendChild(svg);
    const m = { host, svg, pupils: svg.querySelectorAll('.m-pupil') };
    mascots.push(m);
    if (host.hasAttribute('data-interactive')) {
      host.setAttribute('role', 'button');
      host.tabIndex = 0;
      const jump = (e) => {
        svg.classList.remove('jump');
        void svg.offsetWidth;
        svg.classList.add('jump');
        const r = host.getBoundingClientRect();
        burst(r.left + r.width / 2, r.top + r.height * .3, 70);
      };
      host.addEventListener('click', jump);
      host.addEventListener('keydown', (e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); jump(); } });
      svg.addEventListener('animationend', () => svg.classList.remove('jump'));
    }
  });

  // Les yeux suivent le pointeur.
  let px = innerWidth / 2, py = innerHeight / 3, eyeQueued = false;
  const lookAt = () => {
    eyeQueued = false;
    mascots.forEach(({ svg, pupils }) => {
      const r = svg.getBoundingClientRect();
      if (r.bottom < 0 || r.top > innerHeight) return;
      const dx = px - (r.left + r.width / 2), dy = py - (r.top + r.height * .44);
      const d = Math.hypot(dx, dy) || 1, k = Math.min(1, d / 260) * 2.6;
      pupils.forEach((p) => p.setAttribute('transform', `translate(${(dx / d * k).toFixed(2)} ${(dy / d * k).toFixed(2)})`));
    });
  };
  if (!reduce) {
    addEventListener('pointermove', (e) => {
      px = e.clientX; py = e.clientY;
      if (!eyeQueued) { eyeQueued = true; requestAnimationFrame(lookAt); }
    }, { passive: true });
  }

  /* ── Confettis ───────────────────────────────────────── */
  const cv = document.querySelector('.confetti');
  const ctx = cv.getContext('2d');
  const colors = ['#E5484D', '#6246EA', '#E5A21A', '#0E9F8E', '#DB4F9E', '#FFC233'];
  let parts = [], running = false;
  const size = () => { const d = devicePixelRatio || 1; cv.width = innerWidth * d; cv.height = innerHeight * d; ctx.setTransform(d, 0, 0, d, 0, 0); };
  size(); addEventListener('resize', size);
  function burst(x, y, n = 90) {
    if (reduce) return;
    for (let i = 0; i < n; i++) {
      const a = Math.random() * Math.PI * 2, v = 4 + Math.random() * 8;
      parts.push({
        x, y, vx: Math.cos(a) * v, vy: Math.sin(a) * v - 6,
        w: 6 + Math.random() * 6, h: 4 + Math.random() * 8,
        r: Math.random() * 6, vr: (Math.random() - .5) * .4,
        c: colors[i % colors.length], life: 0, round: Math.random() < .3,
      });
    }
    if (!running) { running = true; requestAnimationFrame(tick); }
  }
  function tick() {
    ctx.clearRect(0, 0, innerWidth, innerHeight);
    parts = parts.filter((p) => p.life < 160 && p.y < innerHeight + 40);
    parts.forEach((p) => {
      p.life++; p.vy += .28; p.vx *= .985; p.vy *= .985;
      p.x += p.vx; p.y += p.vy; p.r += p.vr;
      ctx.save(); ctx.translate(p.x, p.y); ctx.rotate(p.r);
      ctx.globalAlpha = Math.min(1, (160 - p.life) / 40);
      ctx.fillStyle = p.c;
      if (p.round) { ctx.beginPath(); ctx.arc(0, 0, p.w / 2, 0, 7); ctx.fill(); }
      else ctx.fillRect(-p.w / 2, -p.h / 2, p.w, p.h * Math.abs(Math.cos(p.life / 8)));
      ctx.restore();
    });
    if (parts.length) requestAnimationFrame(tick); else { running = false; ctx.clearRect(0, 0, innerWidth, innerHeight); }
  }
  document.querySelectorAll('[data-confetti]').forEach((el) => el.addEventListener('click', (e) => {
    const r = el.getBoundingClientRect();
    burst(e.clientX || r.left + r.width / 2, e.clientY || r.top + r.height / 2);
  }));

  /* ── Ballons de l'ouverture ──────────────────────────── */
  const sky = document.querySelector('.balloons');
  if (sky && !reduce) {
    const hues = ['#DB4F9E', '#0E9F8E', '#FF9ACB', '#ffffff', '#EAE7F3'];
    for (let i = 0; i < 9; i++) {
      const b = document.createElement('span');
      b.className = 'balloon';
      const s = .6 + Math.random() * .7;
      b.style.cssText = `left:${(i / 9) * 100 + Math.random() * 6}%;background:${hues[i % hues.length]};` +
        `scale:${s};animation-duration:${14 + Math.random() * 12}s;animation-delay:${-Math.random() * 20}s;opacity:${.35 + s * .4}`;
      sky.appendChild(b);
    }
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

  /* ── Téléphone qui se redresse au défilement ─────────── */
  const phone = document.querySelector('.phone-tilt');
  if (phone && !reduce) {
    let q = false;
    addEventListener('scroll', () => {
      if (q) return; q = true;
      requestAnimationFrame(() => {
        q = false;
        const k = Math.min(1, scrollY / 600);
        phone.style.setProperty('--tilt', `${(7 - k * 9).toFixed(2)}deg`);
        phone.style.translate = `${innerWidth <= 980 ? '50%' : '0'} ${(-k * 40).toFixed(1)}px`;
      });
    }, { passive: true });
  }

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
