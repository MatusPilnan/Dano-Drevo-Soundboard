import {manifest, version} from '@parcel/service-worker';

import sounds from '../content/index.json'
import flags from './flags.json'

async function install() {
  const cache = await caches.open(version);
  for (const sound of sounds) {
    const url = new URL(flags.apiBase + sound.sound);
    await cache.add(url.pathname)
    if (sound.icon) {
      const iconUrl = new URL(flags.apiBase + sound.icon);
      await cache.add(iconUrl.pathname)
    }
  }
  await cache.addAll(manifest);
}
addEventListener('install', e => e.waitUntil(install()));

async function activate() {
  const keys = await caches.keys();
  await Promise.all(
    keys.map(key => key !== version && caches.delete(key))
  );
}

addEventListener('activate', e => e.waitUntil(activate()));

async function fetchHandler(request) {
  console.log('Fetch event for ', request.url);
  const cached = await caches.match(request);
  if (cached) {
    console.log('Found ', request.url, ' in cache');
    return cached;
  } else {
    console.log('Network request for ', request.url);
    return await  fetch(request)
  }
}

addEventListener('fetch', event => event.respondWith(fetchHandler(event.request)))

// addEventListener('fetch', event => {
//   event.respondWith(
//     caches.match(event.request)
//     .then(response => {
//       if (response) {
//         console.log('Found ', event.request.url, ' in cache');
//         return response;
//       }
//       console.log('Network request for ', event.request.url);
//       return fetch(event.request)

//       // TODO 4 - Add fetched files to the cache

//     }).catch(error => {

//       // TODO 6 - Respond with custom offline page

//     })
//   );
// });