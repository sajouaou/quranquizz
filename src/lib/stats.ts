import { readJSON, writeJSON } from './storage';

// Personal records of the solo modes, kept on the device.
const KEY = 'qq.best';

type Records = Record<string, number>;

export function getBestScore(mode: string): number | null {
  return readJSON<Records>(KEY, {})[mode] ?? null;
}

// Saves the score and tells whether it beats the previous record.
export function recordScore(mode: string, score: number): { best: number; isRecord: boolean } {
  const records = readJSON<Records>(KEY, {});
  const previous = records[mode];
  const isRecord = score > 0 && (previous === undefined || score > previous);
  if (isRecord) writeJSON(KEY, { ...records, [mode]: score });
  return { best: isRecord ? score : previous ?? score, isRecord };
}
