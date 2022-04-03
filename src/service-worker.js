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