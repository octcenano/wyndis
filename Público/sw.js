const CACHE = 'wyndis-v2';
const ASSETS = [
  '/',
  '/index.html',
  '/css/variables.css',
  '/css/base.css',
  '/css/components.css',
  '/css/animations.css',
  '/css/layout.css',
  '/js/main.js',
  '/js/modules/downloader.js',
  '/js/modules/auditor.js',
  '/js/modules/charts.js',
  '/js/modules/terminal.js',
  '/js/modules/theme.js'
];

self.addEventListener('install', (e) => {
  e.waitUntil(
    caches.open(CACHE).then((cache) => cache.addAll(ASSETS))
  );
  self.skipWaiting();
});

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k)))
    )
  );
});

self.addEventListener('fetch', (e) => {
  if (e.request.method !== 'GET') return;
  e.respondWith(
    caches.match(e.request).then((cached) => cached || fetch(e.request).then((res) => {
      const clone = res.clone();
      caches.open(CACHE).then((cache) => cache.put(e.request, clone));
      return res;
    }))
  );
});
