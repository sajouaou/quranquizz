import { describe, expect, it } from 'vitest';
import { filterChapters } from '../components/user/SurahPicker';
import { FALLBACK_CHAPTERS } from '../data/chapters';
import { normalizeAudioUrl } from './quranApi';

describe('normalizeAudioUrl', () => {
  it('handles relative, protocol-relative and absolute urls', () => {
    expect(normalizeAudioUrl('Shuraym/mp3/001001.mp3')).toBe('https://verses.quran.com/Shuraym/mp3/001001.mp3');
    expect(normalizeAudioUrl('//mirrors.quranicaudio.com/a.mp3')).toBe('https://mirrors.quranicaudio.com/a.mp3');
    expect(normalizeAudioUrl('https://x.org/a.mp3')).toBe('https://x.org/a.mp3');
  });
});

describe('filterChapters', () => {
  it('finds surahs by number or loosely typed name', () => {
    expect(filterChapters(FALLBACK_CHAPTERS, '18').map((c) => c.id)).toEqual([18]);
    expect(filterChapters(FALLBACK_CHAPTERS, "ali imran").map((c) => c.id)).toEqual([3]);
    expect(filterChapters(FALLBACK_CHAPTERS, 'kahf').map((c) => c.id)).toEqual([18]);
    expect(filterChapters(FALLBACK_CHAPTERS, '')).toHaveLength(114);
  });
});
