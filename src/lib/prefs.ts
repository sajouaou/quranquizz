import { useSyncExternalStore } from 'react';
import { readJSON, writeJSON } from './storage';

// Per-device preferences. They are never sent to the server, so each player
// can pick their own reciter/volume without affecting the others.
export interface Prefs {
  reciterId: number;
  volume: number;
  autoCache: boolean;
  playerName: string;
  lastRoom: string;
}

const KEY = 'qq.prefs';

export const DEFAULT_PREFS: Prefs = {
  reciterId: 10,
  volume: 0.8,
  autoCache: true,
  playerName: '',
  lastRoom: '',
};

let current: Prefs = { ...DEFAULT_PREFS, ...readJSON<Partial<Prefs>>(KEY, {}) };
const listeners = new Set<() => void>();

export function getPrefs(): Prefs {
  return current;
}

export function setPrefs(patch: Partial<Prefs>): void {
  current = { ...current, ...patch };
  writeJSON(KEY, current);
  listeners.forEach((l) => l());
}

function subscribe(listener: () => void) {
  listeners.add(listener);
  return () => listeners.delete(listener);
}

export function usePrefs(): Prefs {
  return useSyncExternalStore(subscribe, getPrefs, getPrefs);
}
