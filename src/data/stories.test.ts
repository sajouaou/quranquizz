import { describe, expect, it } from 'vitest';
import { FALLBACK_CHAPTERS } from './chapters';
import { STORIES, STORY_GROUPS, storyLength } from './stories';
import { pickAyat } from '../pages/stories/TimelineChallenge';
import { buildQuiz } from '../pages/stories/StoryQuiz';
import { starsFor, timelinePoints } from '../lib/storyProgress';

describe('story catalog', () => {
  it('has unique ids and known groups', () => {
    expect(new Set(STORIES.map((s) => s.id)).size).toBe(STORIES.length);
    STORIES.forEach((s) => expect(STORY_GROUPS.map((g) => g.id)).toContain(s.group));
  });

  it('only references ayat that exist', () => {
    STORIES.forEach((s) => {
      const count = FALLBACK_CHAPTERS[s.surah - 1].verses_count;
      expect(s.from, s.id).toBeGreaterThanOrEqual(1);
      expect(s.to, s.id).toBeLessThanOrEqual(count);
      expect(s.from, s.id).toBeLessThanOrEqual(s.to);
      const [surah, verses] = s.lesson.ref.split(':');
      const [first, last = first] = verses.split('-').map(Number);
      expect(Number(surah), s.id).toBeGreaterThanOrEqual(1);
      expect(last, s.id).toBeLessThanOrEqual(FALLBACK_CHAPTERS[Number(surah) - 1].verses_count);
      expect(first, s.id).toBeLessThanOrEqual(last);
    });
  });

  it('stories sharing a surah do not overlap', () => {
    STORIES.forEach((a) => STORIES.forEach((b) => {
      if (a.id !== b.id && a.surah === b.surah) expect(a.to < b.from || b.to < a.from, `${a.id}/${b.id}`).toBe(true);
    }));
  });
});

describe('timeline challenge', () => {
  it('picks distinct ayat inside the story when possible', () => {
    const yusuf = STORIES.find((s) => s.id === 'yusuf')!;
    const ayat = pickAyat(yusuf);
    expect(new Set(ayat).size).toBe(5);
    ayat.forEach((a) => { expect(a).toBeGreaterThanOrEqual(yusuf.from); expect(a).toBeLessThanOrEqual(yusuf.to); });
  });

  it('still works for stories shorter than the number of rounds', () => {
    const ayyub = STORIES.find((s) => s.id === 'ayyub')!;
    const ayat = pickAyat(ayyub);
    expect(ayat).toHaveLength(5);
    expect(new Set(ayat.slice(0, storyLength(ayyub))).size).toBe(storyLength(ayyub));
  });

  it('scores closeness and stars', () => {
    expect(timelinePoints(50, 50, 98)).toBe(3);
    expect(timelinePoints(54, 50, 98)).toBe(2);
    expect(timelinePoints(62, 50, 98)).toBe(1);
    expect(timelinePoints(90, 50, 98)).toBe(0);
    expect(timelinePoints(42, 43, 4)).toBe(2);
    expect(starsFor(15, 15)).toBe(3);
    expect(starsFor(9, 15)).toBe(2);
    expect(starsFor(5, 15)).toBe(1);
    expect(starsFor(2, 15)).toBe(0);
  });
});

describe('which story quiz', () => {
  it('always offers the right story among 4 distinct choices', () => {
    for (let i = 0; i < 20; i++) {
      buildQuiz().forEach((q) => {
        expect(q.choices).toHaveLength(4);
        expect(new Set(q.choices.map((c) => c.id)).size).toBe(4);
        expect(q.choices.map((c) => c.id)).toContain(q.story.id);
        expect(q.ayah).toBeGreaterThanOrEqual(q.story.from);
        expect(q.ayah).toBeLessThanOrEqual(q.story.to);
      });
    }
  });

  it('does not repeat a story within a game', () => {
    const quiz = buildQuiz();
    expect(new Set(quiz.map((q) => q.story.id)).size).toBe(quiz.length);
  });
});
