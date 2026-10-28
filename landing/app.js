/* Eventa · landing page : mascottes, confettis, révélations, simulateur, démo. */
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
    // Dimensions déclarées et chargement différé (pas de saut de mise en page).
    img.width = 384;
    img.height = 384;
    img.loading = 'lazy';
    img.decoding = 'async';
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
      // Saut, nouvelle pose, pluie de confettis.
      const list = poses[m.team];
      const next = list[(list.indexOf(m.img.src.split('/').pop().replace('.webp', '')) + 1) % list.length];
      m.img.classList.remove('jump');
      void m.img.offsetWidth;
      m.img.classList.add('jump');
      setTimeout(() => { m.img.src = src(next); }, 220);
      const r = host.getBoundingClientRect();
      burst(r.left + r.width / 2, r.top + r.height * .35, 60);
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
  // Les mots mis en avant (<em class="script">) gardent leur balise.
  document.querySelectorAll('.split').forEach((h) => {
    const words = [];
    h.childNodes.forEach((n) => {
      const open = n.nodeType === 1 ? `<${n.tagName.toLowerCase()}${n.className ? ` class="${n.className}"` : ''}>` : '';
      const close = n.nodeType === 1 ? `</${n.tagName.toLowerCase()}>` : '';
      n.textContent.split(/(\s+)/).forEach((w) => {
        if (!w.trim()) { if (words.length) words.push(null); return; }
        words.push(open + w + close);
      });
    });
    h.setAttribute('aria-label', h.textContent.trim());
    let i = 0, out = '';
    words.forEach((w) => {
      if (w === null) { out += ' '; return; }
      out += `<span class="w" aria-hidden="true"><span style="--i:${i++}">${w}</span></span>`;
    });
    h.innerHTML = out.replace(/\s+/g, ' ').trim();
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
    if (el.matches('[data-duo]')) setTimeout(() => {
      // Le duo se retrouve au centre puis saute de joie.
      el.querySelectorAll('.m-img').forEach((img) => { img.classList.add('jump'); });
      const r = el.getBoundingClientRect();
      burst(r.left + r.width / 2, r.top + r.height * .4, 110);
    }, reduce ? 0 : 950);
    io.unobserve(el);
  }), { threshold: .2, rootMargin: '0px 0px -8% 0px' });
  document.querySelectorAll('.reveal, .split, [data-chat], [data-duo]').forEach((el, i) => {
    if (el.matches('.reveal')) el.style.transitionDelay = `${(i % 4) * 70}ms`;
    io.observe(el);
  });

  // Mascottes des bordures : déclenchées par l'arrivée de leur section
  // (elles-mêmes démarrent hors champ).
  const peekIO = new IntersectionObserver((entries) => entries.forEach((en) => {
    if (!en.isIntersecting) return;
    en.target.querySelectorAll(':scope > [data-peek]').forEach((p) => p.classList.add('in'));
    peekIO.unobserve(en.target);
  }), { threshold: .15 });
  document.querySelectorAll('[data-peek]').forEach((p) => peekIO.observe(p.parentElement));

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

  /* ── Téléphones : un tour complet sur eux-mêmes, une seule fois ── */
  const spinIO = new IntersectionObserver((entries) => entries.forEach((en) => {
    if (!en.isIntersecting) return;
    if (!reduce) en.target.classList.add('spin');
    spinIO.unobserve(en.target);
  }), { threshold: .35 });
  document.querySelectorAll('[data-spin]').forEach((ph) => spinIO.observe(ph));

  /* ── Budget : petite démonstration du simulateur ─────── */
  const budget = document.getElementById('budget');
  if (budget && sb && !reduce) {
    const card = budget.querySelector('.budget-card');
    const bIO = new IntersectionObserver((entries) => {
      if (!entries[0].isIntersecting) return;
      bIO.disconnect();
      // Le curseur glisse de 3,5 à 6 millions puis revient, une fois.
      const from = +sb.value, to = 6000000, t0 = performance.now(), dur = 2600;
      const step = (t) => {
        const k = Math.min(1, (t - t0) / dur);
        const e = Math.sin(k * Math.PI);
        sb.value = Math.round((from + (to - from) * e) / 100000) * 100000;
        sim();
        if (k < 1) requestAnimationFrame(step); else { card.classList.add('pulse'); }
      };
      setTimeout(() => requestAnimationFrame(step), 700);
    }, { threshold: .45 });
    bIO.observe(budget);
  }

  /* ── Retour en haut ──────────────────────────────────── */
  const toTop = document.querySelector('.to-top');
  if (toTop) {
    let tq = false;
    const check = () => { tq = false; toTop.classList.toggle('show', scrollY > innerHeight * 1.2); };
    addEventListener('scroll', () => { if (!tq) { tq = true; requestAnimationFrame(check); } }, { passive: true });
    toTop.addEventListener('click', () => scrollTo({ top: 0, behavior: reduce ? 'auto' : 'smooth' }));
    check();
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

  /* ── Petit message en bas d'écran ──────────────────────── */
  const toast = (msg) => {
    let t = document.querySelector('.toast');
    if (!t) { t = document.createElement('div'); t.className = 'toast'; t.setAttribute('role', 'status'); document.body.append(t); }
    t.textContent = msg;
    t.classList.add('show');
    clearTimeout(t._h);
    t._h = setTimeout(() => t.classList.remove('show'), 2600);
  };

  /* ── Partage : feuille native, sinon copie du lien ───── */
  document.querySelectorAll('[data-share]').forEach((b) => b.addEventListener('click', async () => {
    const data = { title: 'Eventa', text: 'Le budget parfait pour célébrer, en Côte d’Ivoire.', url: document.querySelector('link[rel=canonical]')?.href || location.href };
    try {
      if (navigator.share) { await navigator.share(data); return; }
      await navigator.clipboard.writeText(data.url);
      toast('Lien copié, il ne reste qu’à le partager !');
    } catch (e) { /* partage annulé */ }
  }));

  /* ── Accès anticipé : envoi à Netlify Forms ──────────── */
  const early = document.querySelector('[data-early]');
  if (early) {
    const msg = early.querySelector('.form-msg');
    early.addEventListener('submit', async (e) => {
      e.preventDefault();
      if (!early.reportValidity()) return;
      const btn = early.querySelector('button[type=submit]');
      btn.disabled = true;
      msg.className = 'form-msg';
      msg.textContent = 'Envoi…';
      try {
        const body = new URLSearchParams(new FormData(early)).toString();
        const r = await fetch('/', { method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, body });
        // En local (démo), le serveur ne gère pas les formulaires : on simule.
        if (!r.ok && !local) throw new Error(r.status);
        early.reset();
        msg.className = 'form-msg ok';
        msg.textContent = 'Merci ! On vous écrit sur WhatsApp dès l’ouverture.';
      } catch (err) {
        msg.className = 'form-msg err';
        msg.textContent = 'L’envoi n’a pas abouti. Réessayez dans un instant.';
      } finally {
        btn.disabled = false;
      }
    });
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
