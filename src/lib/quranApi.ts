import type { Chapter } from '../components/game/Game';
import { FALLBACK_CHAPTERS } from '../data/chapters';
import { readJSON, writeJSON } from './storage';

const API = 'https://api.quran.com/api/v4';
const AUDIO_HOST = 'https://verses.quran.com/';

export interface Reciter {
  id: number;
  name: string;
  style?: string;
}

// Recitations served by quran.com (verse by verse audio).
export const RECITERS: Reciter[] = [
  { id: 7, name: 'Mishari Rashid al-Afasy' },
  { id: 10, name: "Sa'ud ash-Shuraym" },
  { id: 3, name: 'Abdur-Rahman as-Sudais' },
  { id: 4, name: 'Abu Bakr al-Shatri' },
  { id: 5, name: 'Hani ar-Rifai' },
  { id: 6, name: 'Mahmoud Khalil al-Husary' },
  { id: 12, name: 'Mahmoud Khalil al-Husary', style: 'Muallim' },
  { id: 2, name: 'AbdulBaset AbdulSamad', style: 'Murattal' },
  { id: 1, name: 'AbdulBaset AbdulSamad', style: 'Mujawwad' },
  { id: 9, name: 'Mohamed Siddiq al-Minshawi', style: 'Murattal' },
  { id: 8, name: 'Mohamed Siddiq al-Minshawi', style: 'Mujawwad' },
  { id: 11, name: 'Mohamed al-Tablawi' },
];

export function reciterLabel(r: Reciter | undefined): string {
  if (!r) return 'Récitateur inconnu';
  return r.style ? `${r.name} (${r.style})` : r.name;
}

export function findReciter(id: number): Reciter | undefined {
  return RECITERS.find((r) => r.id === id);
}

const CHAPTERS_KEY = 'qq.chapters';

export function getStoredChapters(): Chapter[] {
  const stored = readJSON<Chapter[] | null>(CHAPTERS_KEY, null);
  return stored && stored.length === 114 ? stored : FALLBACK_CHAPTERS;
}

export async function fetchChapters(): Promise<Chapter[]> {
  const response = await fetch(`${API}/chapters`);
  if (!response.ok) throw new Error(`HTTP ${response.status}`);
  const data = await response.json();
  const chapters: Chapter[] = data.chapters.map((c: Chapter) => ({
    id: c.id,
    name_simple: c.name_simple,
    name_arabic: c.name_arabic,
    verses_count: c.verses_count,
  }));
  if (chapters.length === 114) writeJSON(CHAPTERS_KEY, chapters);
  return chapters;
}

export function normalizeAudioUrl(url: string): string {
  if (url.startsWith('//')) return `https:${url}`;
  if (/^https?:\/\//.test(url)) return url;
  return AUDIO_HOST + url.replace(/^\/+/, '');
}

const urlsKey = (reciterId: number, surah: number) => `qq.urls.${reciterId}.${surah}`;

interface AudioFile {
  verse_key: string;
  url: string;
}

// Returns the audio url of every verse of a surah, indexed by verse index (0-based).
// The list is kept in localStorage so that cached audio can be played fully offline.
export async function getSurahAudioUrls(reciterId: number, surah: number): Promise<string[]> {
  const stored = readJSON<string[] | null>(urlsKey(reciterId, surah), null);
  if (stored && stored.length > 0) return stored;

  const urls: string[] = [];
  let page: number | null = 1;
  // The API is paginated: follow next_page instead of assuming everything fits in one page.
  while (page) {
    const response = await fetch(
      `${API}/recitations/${reciterId}/by_chapter/${surah}?per_page=300&page=${page}`,
    );
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    const data = await response.json();
    (data.audio_files as AudioFile[]).forEach((file) => {
      const verse = parseInt(file.verse_key.split(':')[1], 10);
      urls[verse - 1] = normalizeAudioUrl(file.url);
    });
    page = data.pagination?.next_page ?? null;
  }
  if (urls.length === 0) throw new Error(`No audio for surah ${surah}`);
  writeJSON(urlsKey(reciterId, surah), urls);
  return urls;
}

export function getStoredSurahAudioUrls(reciterId: number, surah: number): string[] | null {
  return readJSON<string[] | null>(urlsKey(reciterId, surah), null);
}
