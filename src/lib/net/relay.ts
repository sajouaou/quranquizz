import { CLOSE } from './link';

// In-app port of quranquizz_server: when a device hosts a peer-to-peer game,
// it runs the same relay rules itself (ordering, host election, late joins...).

export interface Hello {
  username?: unknown;
  player?: unknown;
  game?: unknown;
  clientId?: unknown;
}

export interface RelayMember {
  id: string;
  username: string;
  clientId: string;
  player: Record<string, unknown>;
  deliver: (msg: any) => void;
  disconnect: (code: number, reason: string) => void;
}

const clean = (value: unknown, max: number) => (typeof value === 'string' ? value.trim().slice(0, max) : '');
const asObject = (value: unknown): Record<string, unknown> =>
  value && typeof value === 'object' && !Array.isArray(value) ? (value as Record<string, unknown>) : {};

const randomId = () =>
  typeof crypto !== 'undefined' && 'randomUUID' in crypto
    ? crypto.randomUUID()
    : `${Date.now().toString(36)}-${Math.random().toString(36).slice(2)}`;

export class Relay {
  readonly members = new Map<string, RelayMember>();
  host: string | null = null;
  game: Record<string, unknown> = {};
  inProgress = false;
  current: unknown = null;

  constructor(private readonly maxPlayers = 8) {}

  // Returns the new member, or null when the connection is refused (disconnect already called).
  join(
    hello: Hello,
    deliver: (msg: any) => void,
    disconnect: (code: number, reason: string) => void,
  ): RelayMember | null {
    const username = clean(hello.username, 24);
    const clientId = clean(hello.clientId, 64);
    if (!username) {
      disconnect(CLOSE.INVALID, 'Missing username');
      return null;
    }
    const taken = [...this.members.values()].find((m) => m.username.toLowerCase() === username.toLowerCase());
    if (taken && clientId && taken.clientId === clientId) {
      this.leave(taken);
      taken.disconnect(1000, 'Replaced');
    } else if (taken) {
      disconnect(CLOSE.NAME_TAKEN, 'Name already taken');
      return null;
    }
    if (this.members.size >= this.maxPlayers) {
      disconnect(CLOSE.ROOM_FULL, 'Room is full');
      return null;
    }

    const id = randomId();
    const member: RelayMember = {
      id, username, clientId, deliver, disconnect,
      player: { ...asObject(hello.player), playerName: username, id, isHost: false },
    };
    if (this.members.size === 0) {
      this.host = id;
      this.game = asObject(hello.game);
      member.player.isHost = true;
    } else {
      this.broadcast({
        user: 'Admin',
        text: { content: `${username} has joined!`, type: 'PLAYER', action: 'NEW', value: member.player },
      });
    }
    this.members.set(id, member);
    member.deliver({
      user: 'Admin',
      text: {
        content: 'Welcome',
        type: 'WELCOME',
        players: [...this.members.values()].map((m) => m.player),
        game: this.game,
        inProgress: this.inProgress,
        current: this.current,
      },
    });
    return member;
  }

  receive(member: RelayMember, message: unknown): void {
    if (!this.members.has(member.id)) return;
    const payload = asObject(message);
    const text = asObject(payload.message);
    if (typeof text.type !== 'string') return;
    if (payload.game && typeof payload.game === 'object') this.game = asObject(payload.game);
    if (text.type === 'LEAVE') {
      this.leave(member);
      member.disconnect(1000, 'Bye');
      return;
    }
    if (text.type === 'GAMESETTING' && this.host !== member.id) return;
    if (text.type === 'GAMESETTING' && text.action === 'update' && text.value && typeof text.value === 'object') {
      this.game = asObject(text.value);
    }
    if (text.type === 'GAME') {
      if (text.action === 'START') { this.inProgress = true; this.current = null; }
      if (text.action === 'NEWSURAH') this.current = text.value ?? null;
      if (text.action === 'ENDGAME') { this.inProgress = false; this.current = null; }
    }
    this.broadcast({ user: member.username, text });
  }

  leave(member: RelayMember): void {
    if (!this.members.delete(member.id)) return;
    if (this.members.size === 0) {
      this.host = null;
      return;
    }
    if (this.host === member.id) {
      const next = this.members.values().next().value!;
      next.player.isHost = true;
      this.host = next.id;
    }
    this.broadcast({
      user: 'Admin',
      text: {
        content: `${member.username} has leaved!`,
        type: 'PLAYER',
        action: 'REMOVE',
        value: { player: { playerName: member.username, id: member.id }, newHost: this.host },
      },
    });
  }

  private broadcast(msg: any): void {
    this.members.forEach((m) => {
      try {
        m.deliver(msg);
      } catch {
        // A broken channel is cleaned up by its close handler.
      }
    });
  }
}
