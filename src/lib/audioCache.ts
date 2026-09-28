import { Capacitor, CapacitorHttp } from '@capacitor/core';
import { getStoredSurahAudioUrls, getSurahAudioUrls } from './quranApi';
import { readJSON, writeJSON } from './storage';

// Offline storage of recitations, based on the Cache Storage API
// (available in browsers over https and in the Capacitor WebView).

const CACHE_NAME = 'qq-audio-v1';
const INDEX_KEY = 'qq.offline';

type OfflineIndex = Record<string, number[]>; // reciterId -> downloaded surahs

export const isCacheSupported = () => typeof caches !== 'undefined';

function readIndex(): OfflineIndex {
  return readJSON<OfflineIndex>(INDEX_KEY, {});
}

export function getDownloadedSurahs(reciterId: number): number[] {
  return readIndex()[reciterId] ?? [];
}

function markSurah(reciterId: number, surah: number, downloaded: boolean) {
  const index = readIndex();
  const set = new Set(index[reciterId] ?? []);
  if (downloaded) set.add(surah);
  else set.delete(surah);
  index[reciterId] = [...set].sort((a, b) => a - b);
  writeJSON(INDEX_KEY, index);
}

function base64ToBlob(base64: string, type: string): Blob {
  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return new Blob([bytes], { type });
}

async function downloadBlob(url: string, signal?: AbortSignal): Promise<Blob> {
  try {
    const response = await fetch(url, { signal });
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    return await response.blob();
  } catch (error) {
    // On device, fall back to the native HTTP stack which is not subject to CORS.
    if (signal?.aborted || !Capacitor.isNativePlatform()) throw error;
    const response = await CapacitorHttp.get({ url, responseType: 'blob' });
    if (response.status >= 400) throw new Error(`HTTP ${response.status}`, { cause: error });
    const data = response.data as unknown;
    return data instanceof Blob ? data : base64ToBlob(String(data), 'audio/mpeg');
  }
}

export async function getCachedAudio(url: string): Promise<Blob | null> {
  if (!isCacheSupported()) return null;
  try {
    const cache = await caches.open(CACHE_NAME);
    const response = await cache.match(url);
    return response ? await response.blob() : null;
  } catch {
    return null;
  }
}

export async function cacheAudio(url: string, signal?: AbortSignal): Promise<void> {
  if (!isCacheSupported()) throw new Error('Cache Storage indisponible');
  const cache = await caches.open(CACHE_NAME);
  if (await cache.match(url)) return;
  const blob = await downloadBlob(url, signal);
  await cache.put(url, new Response(blob, { headers: { 'Content-Type': blob.type || 'audio/mpeg' } }));
}

export async function downloadSurah(
  reciterId: number,
  surah: number,
  onProgress?: (done: number, total: number) => void,
  signal?: AbortSignal,
): Promise<void> {
  const urls = (await getSurahAudioUrls(reciterId, surah)).filter(Boolean);
  let done = 0;
  let next = 0;
  let failed = false;
  onProgress?.(0, urls.length);
  const worker = async () => {
    while (next < urls.length && !failed) {
      if (signal?.aborted) throw new DOMException('Aborted', 'AbortError');
      const url = urls[next++];
      try {
        await cacheAudio(url, signal);
      } catch (error) {
        if (signal?.aborted) throw error;
        // One retry for flaky mobile connections, then stop the other workers too.
        try {
          await cacheAudio(url, signal);
        } catch (retryError) {
          failed = true;
          throw retryError;
        }
      }
      onProgress?.(++done, urls.length);
    }
  };
  await Promise.all(Array.from({ length: 4 }, worker));
  markSurah(reciterId, surah, true);
}

export async function deleteSurah(reciterId: number, surah: number): Promise<void> {
  const urls = getStoredSurahAudioUrls(reciterId, surah) ?? [];
  if (isCacheSupported()) {
    const cache = await caches.open(CACHE_NAME);
    await Promise.all(urls.filter(Boolean).map((url) => cache.delete(url)));
  }
  markSurah(reciterId, surah, false);
}

export async function clearAudioCache(): Promise<void> {
  if (isCacheSupported()) await caches.delete(CACHE_NAME);
  writeJSON(INDEX_KEY, {});
}

export async function getStorageEstimate(): Promise<{ usage: number; quota: number } | null> {
  try {
    if (!navigator.storage?.estimate) return null;
    const { usage = 0, quota = 0 } = await navigator.storage.estimate();
    return { usage, quota };
  } catch {
    return null;
  }
}

export async function requestPersistentStorage(): Promise<void> {
  try {
    await navigator.storage?.persist?.();
  } catch {
    // Not supported everywhere; the cache still works, it may just be evicted under pressure.
  }
}

export function formatBytes(bytes: number): string {
  if (bytes < 1024 * 1024) return `${Math.round(bytes / 1024)} Ko`;
  if (bytes < 1024 * 1024 * 1024) return `${(bytes / 1024 / 1024).toFixed(1)} Mo`;
  return `${(bytes / 1024 / 1024 / 1024).toFixed(2)} Go`;
}
