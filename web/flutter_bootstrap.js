{{flutter_js}}
{{flutter_build_config}}

// Le service worker de Flutter est obsolète : on n'en installe plus, et on
// retire celui d'un ancien déploiement pour que chacun reçoive tout de suite
// la dernière version (les en-têtes « no-cache » de Netlify font le reste).
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.getRegistrations()
    .then((regs) => regs.forEach((r) => r.unregister()))
    .catch(() => {});
}
if ('caches' in window) {
  caches.keys()
    .then((keys) => keys.filter((k) => k.startsWith('flutter')).forEach((k) => caches.delete(k)))
    .catch(() => {});
}

_flutter.loader.load({
  onEntrypointLoaded: async (engineInitializer) => {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();
    // L'app est prête : l'écran de chargement s'efface.
    const splash = document.getElementById('splash');
    if (splash) {
      splash.classList.add('done');
      setTimeout(() => splash.remove(), 500);
    }
  },
});
