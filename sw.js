const CACHE = 'anamneseapp-v2';
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
      // App shell é obrigatório — falha se não conseguir
      await c.addAll(SHELL);
      // CDN é best-effort — não falha o install se offline
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
  if (e.request.url.includes('supabase.co')) return; // Supabase sempre via rede

  e.respondWith(
    caches.match(e.request).then(cached => {
      const fromNetwork = fetch(e.request).then(res => {
        if (res.ok) {
          const isLocal  = e.request.url.startsWith(self.location.origin);
          const isCDN    = CDN.some(u => e.request.url.startsWith(u.split('?')[0]));
          if (isLocal || isCDN) {
            caches.open(CACHE).then(c => c.put(e.request, res.clone()));
          }
        }
        return res;
      }).catch(() => cached);
      return cached || fromNetwork;
    })
  );
});
