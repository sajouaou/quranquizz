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
  clientId: string;
}

const KEY = 'qq.prefs';

export const DEFAULT_PREFS: Prefs = {
  reciterId: 10,
  volume: 0.8,
  autoCache: true,
  playerName: '',
  lastRoom: '',
  clientId: '',
};

let current: Prefs = { ...DEFAULT_PREFS, ...readJSON<Partial<Prefs>>(KEY, {}) };

// Random id identifying this device, so the server lets it take its place back
// in a room after a network drop instead of refusing the (already used) name.
if (!current.clientId) {
  const id = typeof crypto !== 'undefined' && 'randomUUID' in crypto
    ? crypto.randomUUID()
    : `${Date.now().toString(36)}-${Math.random().toString(36).slice(2)}`;
  current = { ...current, clientId: id };
  writeJSON(KEY, current);
}
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
