const CACHE = 'anamneseapp-v3'; // bump para forçar invalidação do cache antigo
const SHELL = ['/', '/anamnese', '/dashboard', '/config.js', '/manifest.json', '/icon.svg'];
const CDN = [
  'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2',
  'https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js',
  'https://fonts.googleapis.com/css2?family=Instrument+Serif:ital@0;1&family=DM+Sans:opsz,wght@9..40,300;9..40,400;9..40,500;9..40,600&display=swap',
  'https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,400;0,500;0,600;1,400;1,500&family=Jost:wght@300;400;500;600&display=swap'
];

self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE).then(async c => {
      await c.addAll(SHELL);
      await Promise.all(CDN.map(url =>
        fetch(url).then(r => r.ok ? c.put(url, r) : null).catch(() => null)
      ));
      return self.skipWaiting();
    })
  );
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', e => {
  if (e.request.method !== 'GET') return;
  if (e.request.url.includes('supabase.co')) return;

  const isHTML = e.request.headers.get('accept')?.includes('text/html');
  const isLocal = e.request.url.startsWith(self.location.origin);
  const isCDN   = CDN.some(u => e.request.url.startsWith(u.split('?')[0]));

  if (isHTML || isLocal) {
    // Network-first para HTML e arquivos locais — garante versão sempre atualizada
    e.respondWith(
      fetch(e.request).then(res => {
        if (res.ok) {
          const clone = res.clone();
          caches.open(CACHE).then(c => c.put(e.request, clone));
        }
        return res;
      }).catch(() => caches.match(e.request))
    );
  } else if (isCDN) {
    // Cache-first para CDN — evita re-download de libs pesadas
    e.respondWith(
      caches.match(e.request).then(cached => {
        if (cached) return cached;
        return fetch(e.request).then(res => {
          if (res.ok) {
            const clone = res.clone();
            caches.open(CACHE).then(c => c.put(e.request, clone));
          }
          return res;
        }).catch(() => null);
      })
    );
  }
});
