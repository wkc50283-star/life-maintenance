(() => {
  const loadFlutter = () => {
    const bootstrap = document.createElement('script');
    bootstrap.src = 'flutter_bootstrap.js';
    bootstrap.async = true;
    document.body.appendChild(bootstrap);
  };

  const retireLegacyServiceWorker = async () => {
    if (!('serviceWorker' in navigator)) {
      return false;
    }

    const appScope = new URL(document.baseURI).href;
    const registrations = await navigator.serviceWorker.getRegistrations();
    const appRegistrations = registrations.filter(
      (registration) => registration.scope === appScope,
    );
    const wasControlled = navigator.serviceWorker.controller !== null;
    const results = await Promise.all(
      appRegistrations.map((registration) => registration.unregister()),
    );

    return wasControlled && results.some(Boolean);
  };

  retireLegacyServiceWorker()
    .then((reloadRequired) => {
      if (reloadRequired) {
        window.location.reload();
        return;
      }
      loadFlutter();
    })
    .catch((error) => {
      console.warn('Unable to retire the legacy service worker.', error);
      loadFlutter();
    });
})();
