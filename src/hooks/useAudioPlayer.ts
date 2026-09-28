import { useCallback, useEffect, useRef, useState } from 'react';
import { cacheAudio, getCachedAudio } from '../lib/audioCache';
import { getPrefs, setPrefs, usePrefs } from '../lib/prefs';
import { getSurahAudioUrls } from '../lib/quranApi';

export type AudioStatus = 'idle' | 'loading' | 'playing' | 'ended' | 'blocked' | 'error';

interface Request {
  surah: number;
  verse: number; // 0-based verse index
  count: number;
}

// One audio element for the whole app. Mobile browsers only allow programmatic
// playback on an element that has been "unlocked" by a user gesture, so we
// unlock it once on the first tap and then reuse it for every ayah.
let sharedAudio: HTMLAudioElement | null = null;
const SILENCE =
  'data:audio/wav;base64,UklGRiQAAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQAAAAA=';

export function getSharedAudio(): HTMLAudioElement {
  if (!sharedAudio) {
    sharedAudio = new Audio();
    sharedAudio.preload = 'auto';
  }
  return sharedAudio;
}

export function installAudioUnlock(): void {
  const unlock = () => {
    const audio = getSharedAudio();
    if (!audio.src) {
      audio.src = SILENCE;
      audio.play().then(() => audio.pause()).catch(() => {});
    }
    window.removeEventListener('pointerdown', unlock);
    window.removeEventListener('keydown', unlock);
  };
  window.addEventListener('pointerdown', unlock);
  window.addEventListener('keydown', unlock);
}

export interface AudioPlayer {
  status: AudioStatus;
  current: number; // index of the ayah being played in the sequence
  total: number;
  volume: number;
  load: (surah: number, verse: number, count: number) => void;
  replay: () => void;
  stop: () => void;
  setVolume: (volume: number) => void;
}

export function useAudioPlayer(): AudioPlayer {
  const { reciterId, volume } = usePrefs();
  const [status, setStatus] = useState<AudioStatus>('idle');
  const [current, setCurrent] = useState(0);
  const [total, setTotal] = useState(0);

  const requestRef = useRef<Request | null>(null);
  // Incremented on every load/stop: any async work started for an older
  // generation is discarded, so late network responses can't play over the new ayah.
  const generationRef = useRef(0);
  const objectUrlRef = useRef<string | null>(null);

  const releaseObjectUrl = () => {
    if (objectUrlRef.current) {
      URL.revokeObjectURL(objectUrlRef.current);
      objectUrlRef.current = null;
    }
  };

  const playSequence = useCallback(async (urls: string[], index: number, generation: number) => {
    const audio = getSharedAudio();
    const url = urls[index];
    setCurrent(index);

    let src = url;
    const cached = await getCachedAudio(url);
    if (generation !== generationRef.current) return;
    releaseObjectUrl();
    if (cached) {
      src = URL.createObjectURL(cached);
      objectUrlRef.current = src;
    } else if (getPrefs().autoCache) {
      // Keep what was listened to, so it is available offline next time.
      cacheAudio(url).catch(() => {});
    }

    audio.onended = () => {
      if (generation !== generationRef.current) return;
      if (index + 1 < urls.length) playSequence(urls, index + 1, generation);
      else setStatus('ended');
    };
    audio.onerror = () => {
      if (generation === generationRef.current) setStatus('error');
    };
    audio.src = src;
    audio.volume = getPrefs().volume;
    try {
      await audio.play();
      if (generation === generationRef.current) setStatus('playing');
    } catch (error) {
      if (generation !== generationRef.current) return;
      setStatus((error as DOMException)?.name === 'NotAllowedError' ? 'blocked' : 'error');
    }
  }, []);

  const start = useCallback(
    async (request: Request) => {
      const generation = ++generationRef.current;
      const audio = getSharedAudio();
      audio.pause();
      setStatus('loading');
      setCurrent(0);
      setTotal(request.count);
      try {
        const all = await getSurahAudioUrls(reciterId, request.surah);
        if (generation !== generationRef.current) return;
        const urls = all.slice(request.verse, request.verse + Math.max(1, request.count)).filter(Boolean);
        if (urls.length === 0) throw new Error('No audio for this verse');
        setTotal(urls.length);
        // Fetch the following ayat in the background so the sequence doesn't stall.
        if (getPrefs().autoCache) urls.slice(1).forEach((u) => cacheAudio(u).catch(() => {}));
        await playSequence(urls, 0, generation);
      } catch {
        if (generation === generationRef.current) setStatus('error');
      }
    },
    [reciterId, playSequence],
  );

  const load = useCallback(
    (surah: number, verse: number, count: number) => {
      requestRef.current = { surah, verse, count };
      start(requestRef.current);
    },
    [start],
  );

  const replay = useCallback(() => {
    if (requestRef.current) start(requestRef.current);
  }, [start]);

  const stop = useCallback(() => {
    generationRef.current++;
    const audio = getSharedAudio();
    audio.pause();
    audio.onended = null;
    audio.onerror = null;
    releaseObjectUrl();
    setStatus('idle');
  }, []);

  const setVolume = useCallback((value: number) => {
    setPrefs({ volume: value });
    getSharedAudio().volume = value;
  }, []);

  // Stop playback when the game screen goes away.
  useEffect(() => stop, [stop]);

  return { status, current, total, volume, load, replay, stop, setVolume };
}
