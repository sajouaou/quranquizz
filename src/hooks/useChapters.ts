import { useEffect, useState } from 'react';
import type { Chapter } from '../components/game/Game';
import { fetchChapters, getStoredChapters } from '../lib/quranApi';

// Chapters are available immediately (bundled/stored copy) and refreshed from the API.
export function useChapters(): Chapter[] {
  const [chapters, setChapters] = useState<Chapter[]>(getStoredChapters);
  useEffect(() => {
    let cancelled = false;
    fetchChapters()
      .then((fresh) => { if (!cancelled) setChapters(fresh); })
      .catch(() => { /* offline: keep the stored list */ });
    return () => { cancelled = true; };
  }, []);
  return chapters;
}
