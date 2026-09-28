import type { RoomLink } from './link';

// The peer-to-peer game in progress. It outlives page changes (lobby -> game)
// and is ended explicitly when leaving the game or coming back to the menu.
export interface P2PSession {
  link: RoomLink;
  name: string;
  hostName: string;
}

let session: P2PSession | null = null;

export const getSession = () => session;

export function startSession(next: P2PSession): void {
  endSession();
  session = next;
}

export function endSession(): void {
  session?.link.close();
  session = null;
}
