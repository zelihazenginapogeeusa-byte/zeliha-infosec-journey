// Minimal offline cache for the flashcards PWA. Cache-first for the app
// shell/assets, falling back to network, so the deck still opens without a
// connection once it's been loaded at least once. Bump CACHE when the app
// files change so old installs pick up the new version.
const CACHE = "cybercards-v1";
const ASSETS = [
  "./cybersecurity-interview-flashcards.html",
  "./manifest.json",
  "./icon-192.png",
  "./icon-512.png",
];

self.addEventListener("install", function(event){
  event.waitUntil(
    caches.open(CACHE).then(function(cache){ return cache.addAll(ASSETS); }).catch(function(){})
  );
  self.skipWaiting();
});

self.addEventListener("activate", function(event){
  event.waitUntil(
    caches.keys().then(function(keys){
      return Promise.all(keys.filter(function(k){ return k !== CACHE; }).map(function(k){ return caches.delete(k); }));
    })
  );
  self.clients.claim();
});

self.addEventListener("fetch", function(event){
  if(event.request.method !== "GET") return;
  event.respondWith(
    caches.match(event.request).then(function(cached){
      const network = fetch(event.request).then(function(resp){
        if(resp && resp.ok){
          const copy = resp.clone();
          caches.open(CACHE).then(function(cache){ cache.put(event.request, copy); }).catch(function(){});
        }
        return resp;
      }).catch(function(){ return cached; });
      return cached || network;
    })
  );
});
