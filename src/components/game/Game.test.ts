import { describe, expect, it, vi } from 'vitest';
import { FALLBACK_CHAPTERS } from '../../data/chapters';
import { checkChoice, defaultGame, getRandomChapterNumber, getRandomVerseNumber, verseBounds } from './Game';
import { checkPlayers, defaultPlayer, isEliminated, isPlayersLost } from './Player';

describe('fallback chapters', () => {
  it('lists the 114 surahs and 6236 verses', () => {
    expect(FALLBACK_CHAPTERS).toHaveLength(114);
    expect(FALLBACK_CHAPTERS.reduce((sum, c) => sum + c.verses_count, 0)).toBe(6236);
  });
});

describe('getRandomVerseNumber', () => {
  const extremes = (game: typeof defaultGame, surah: number) => {
    const spy = vi.spyOn(Math, 'random');
    spy.mockReturnValue(0);
    const low = getRandomVerseNumber(game, FALLBACK_CHAPTERS, surah);
    spy.mockReturnValue(0.999999);
    const high = getRandomVerseNumber(game, FALLBACK_CHAPTERS, surah);
    spy.mockRestore();
    return { low, high };
  };

  it('covers the whole surah', () => {
    const { low, high } = extremes({ ...defaultGame }, 1);
    expect(low.verse).toBe(0);
    expect(high.verse).toBe(6);
  });

  it('keeps a sequence of ayat inside the surah', () => {
    const { high } = extremes({ ...defaultGame, numberOfAyat: 3 }, 1);
    expect(high.verse + 3).toBeLessThanOrEqual(7);
  });

  it('respects the verse filter', () => {
    const game = { ...defaultGame, filterVerse: true, minSurah: 2, maxSurah: 2, minVerse: 10, maxVerse: 20 };
    const { low, high } = extremes(game, 2);
    expect(low.verse).toBe(10);
    expect(high.verse).toBe(20);
  });
});

describe('getRandomChapterNumber', () => {
  it('stays in the configured range', () => {
    const game = { ...defaultGame, minSurah: 78, maxSurah: 114 };
    for (let i = 0; i < 200; i++) {
      const surah = getRandomChapterNumber(game, FALLBACK_CHAPTERS);
      expect(surah).toBeGreaterThanOrEqual(78);
      expect(surah).toBeLessThanOrEqual(114);
    }
  });
});

describe('answers and players', () => {
  it('checks the verse only when asked', () => {
    const game = { ...defaultGame, confirmedChapter: 2, confirmedVerse: 254 };
    expect(checkChoice(game, 2, 0)).toBe(true);
    expect(checkChoice({ ...game, askVerse: true }, 2, 0)).toBe(false);
    expect(checkChoice({ ...game, askVerse: true }, 2, 254)).toBe(true);
    expect(checkChoice(game, 3, 254)).toBe(false);
  });

  it('knows when everybody answered or lost', () => {
    const p = { ...defaultPlayer };
    expect(checkPlayers([{ ...p, gameState: 'ready' }, { ...p, gameState: 'next' }])).toBe(true);
    expect(checkPlayers([{ ...p, gameState: 'ready' }, { ...p, gameState: 'not ready' }])).toBe(false);
    expect(isPlayersLost([{ ...p, showLives: true, lives: 0 }])).toBe(true);
    expect(isPlayersLost([{ ...p, showLives: true, lives: 1 }])).toBe(false);
    expect(isPlayersLost([{ ...p, showLives: false, lives: 0 }])).toBe(false);
  });
});

describe('verse bounds and leftover settings', () => {
  const chapter = (id: number) => FALLBACK_CHAPTERS[id - 1];

  it('clamps verse limits left over from another surah', () => {
    const game = { ...defaultGame, filterVerse: true, minSurah: 1, maxSurah: 114, minVerse: 200, maxVerse: 286 };
    expect(verseBounds(game, chapter(1))).toEqual([6, 6]);
    expect(verseBounds(game, chapter(114))).toEqual([0, 5]);
    expect(verseBounds(game, chapter(2))).toEqual([0, 285]);
  });

  it('falls back to the whole surah when the range is inverted', () => {
    const game = { ...defaultGame, filterVerse: true, minSurah: 2, maxSurah: 2, minVerse: 50, maxVerse: 10 };
    expect(verseBounds(game, chapter(2))).toEqual([0, 285]);
  });

  it('never throws with weighted distribution and odd settings', () => {
    const odd = [
      { ...defaultGame, verseDistribution: true, filterVerse: true, minSurah: 1, maxSurah: 3, minVerse: 250, maxVerse: 0 },
      { ...defaultGame, verseDistribution: true, minSurah: 10, maxSurah: 5 },
      { ...defaultGame, numberOfAyat: 20, minSurah: 108, maxSurah: 108 },
    ];
    odd.forEach((game) => {
      for (let i = 0; i < 100; i++) {
        const surah = getRandomChapterNumber(game, FALLBACK_CHAPTERS);
        const { verse, maxtemp } = getRandomVerseNumber(game, FALLBACK_CHAPTERS, surah);
        const count = FALLBACK_CHAPTERS[surah - 1].verses_count;
        expect(verse).toBeGreaterThanOrEqual(0);
        expect(verse).toBeLessThan(count);
        expect(maxtemp).toBeLessThanOrEqual(count);
      }
    });
  });

  it('weights surahs by their number of verses', () => {
    const game = { ...defaultGame, verseDistribution: true, minSurah: 1, maxSurah: 2 };
    let baqarah = 0;
    for (let i = 0; i < 2000; i++) if (getRandomChapterNumber(game, FALLBACK_CHAPTERS) === 2) baqarah++;
    expect(baqarah / 2000).toBeGreaterThan(0.9); // 286 of 293 verses
  });
});

describe('eliminated players', () => {
  it('do not block the round', () => {
    const p = { ...defaultPlayer };
    const out = { ...p, showLives: true, lives: 0, gameState: 'not ready' };
    expect(isEliminated(out)).toBe(true);
    expect(checkPlayers([{ ...p, gameState: 'ready' }, out])).toBe(true);
  });
});
