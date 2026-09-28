import { beforeEach, describe, expect, it } from 'vitest';
import { getBestScore, recordScore } from './stats';

describe('best scores', () => {
  beforeEach(() => localStorage.clear());

  it('keeps the best score per mode', () => {
    expect(getBestScore('Arcade')).toBeNull();
    expect(recordScore('Arcade', 0)).toEqual({ best: 0, isRecord: false });
    expect(recordScore('Arcade', 4)).toEqual({ best: 4, isRecord: true });
    expect(recordScore('Arcade', 3)).toEqual({ best: 4, isRecord: false });
    expect(recordScore('Survie', 2).isRecord).toBe(true);
    expect(getBestScore('Arcade')).toBe(4);
  });
});
