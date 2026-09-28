import { useSyncExternalStore } from 'react';
import { readJSON, writeJSON } from './storage';

// Progress of the story mode, kept on the device.
export interface StoryProgress {
  listened: boolean; // the whole story was listened to
  stars: number; // best result of the timeline challenge, 0-3
}

type ProgressMap = Record<string, StoryProgress>;

const KEY = 'qq.stories';
let current: ProgressMap = readJSON<ProgressMap>(KEY, {});
const listeners = new Set<() => void>();

function save(next: ProgressMap) {
  current = next;
  writeJSON(KEY, current);
  listeners.forEach((l) => l());
}

export function getStoryProgress(id: string): StoryProgress {
  return current[id] ?? { listened: false, stars: 0 };
}

export function markListened(id: string): void {
  if (getStoryProgress(id).listened) return;
  save({ ...current, [id]: { ...getStoryProgress(id), listened: true } });
}

export function recordStars(id: string, stars: number): boolean {
  const previous = getStoryProgress(id).stars;
  if (stars <= previous) return false;
  save({ ...current, [id]: { ...getStoryProgress(id), stars } });
  return true;
}

// Stars for the timeline challenge: 3 points max per ayah.
export function starsFor(points: number, max: number): number {
  const ratio = max > 0 ? points / max : 0;
  if (ratio >= 0.85) return 3;
  if (ratio >= 0.6) return 2;
  if (ratio >= 0.3) return 1;
  return 0;
}

// Points for placing an ayah on the story timeline: exact = 3, close = 2, near = 1.
export function timelinePoints(guess: number, actual: number, length: number): number {
  const distance = Math.abs(guess - actual);
  if (distance === 0) return 3;
  if (distance <= Math.max(1, Math.round(length * 0.05))) return 2;
  if (distance <= Math.max(2, Math.round(length * 0.15))) return 1;
  return 0;
}

function subscribe(listener: () => void) {
  listeners.add(listener);
  return () => listeners.delete(listener);
}

export function useStoryProgress(): ProgressMap {
  return useSyncExternalStore(subscribe, () => current, () => current);
}
