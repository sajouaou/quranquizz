// Transport between the game screen and the other players of a room.
//
// Whatever the transport (WebSocket server, or a peer-to-peer host / guest),
// the game sees the same thing: an ordered list of relayed messages
// ({ user, text }) and a way to send its own ({ message, game, players }).

export type LinkStatus = 'connecting' | 'open' | 'closed';
export type LinkKind = 'server' | 'host' | 'guest';

export const CLOSE = {
  INVALID: 4000,
  NAME_TAKEN: 4001,
  ROOM_FULL: 4002,
  HOST_LEFT: 4003,
} as const;

export const CLOSE_REASONS: Record<number, string> = {
  [CLOSE.INVALID]: 'Pseudo ou salon invalide.',
  [CLOSE.NAME_TAKEN]: 'Ce pseudo est déjà utilisé dans ce salon. Choisis-en un autre.',
  [CLOSE.ROOM_FULL]: 'Ce salon est complet.',
  [CLOSE.HOST_LEFT]: "L'hôte a mis fin à la partie.",
};

// Server/host payloads: only new messages (v2) or the whole history (v1 server).
export interface RelayPayload {
  append?: any[];
  messages?: any[];
  close?: { code: number; reason?: string };
}

type Listener = (messages: any[], reset: boolean) => void;

export abstract class RoomLink {
  abstract readonly kind: LinkKind;
  status: LinkStatus = 'connecting';
  closeReason: string | null = null;
  private log: any[] = [];
  private listeners = new Set<Listener>();
  private statusListeners = new Set<(status: LinkStatus) => void>();

  abstract send(payload: object): void;
  abstract close(): void;

  // New subscribers first receive everything already received (reset = true).
  subscribe(listener: Listener): () => void {
    this.listeners.add(listener);
    listener([...this.log], true);
    return () => { this.listeners.delete(listener); };
  }

  onStatus(listener: (status: LinkStatus) => void): () => void {
    this.statusListeners.add(listener);
    listener(this.status);
    return () => { this.statusListeners.delete(listener); };
  }

  protected receive(payload: RelayPayload): void {
    if (Array.isArray(payload.append)) {
      this.log.push(...payload.append);
      this.listeners.forEach((l) => l([...payload.append!], false));
    } else if (Array.isArray(payload.messages)) {
      this.log = [...payload.messages];
      this.listeners.forEach((l) => l([...this.log], true));
    }
    if (payload.close) {
      this.closeReason = CLOSE_REASONS[payload.close.code] ?? payload.close.reason ?? null;
    }
  }

  protected setStatus(status: LinkStatus, reason?: string | null): void {
    if (this.status === 'closed') return;
    if (reason !== undefined && this.closeReason === null) this.closeReason = reason;
    this.status = status;
    this.statusListeners.forEach((l) => l(status));
  }
}

export function parsePayload(data: unknown): RelayPayload | null {
  if (typeof data !== 'string') return null;
  try {
    const value = JSON.parse(data);
    return value && typeof value === 'object' ? value : null;
  } catch {
    return null;
  }
}

export class WebSocketLink extends RoomLink {
  readonly kind = 'server' as const;
  private socket: WebSocket;
  private queue: string[] = [];

  constructor(endpoint: string, params: Record<string, string>) {
    super();
    this.socket = new WebSocket(`${endpoint}?${new URLSearchParams(params).toString()}`);
    this.socket.onopen = () => {
      this.queue.forEach((data) => this.socket.send(data));
      this.queue = [];
      this.setStatus('open');
    };
    this.socket.onmessage = (event) => {
      const payload = parsePayload(event.data);
      if (payload) this.receive(payload);
    };
    this.socket.onclose = (event) => this.setStatus('closed', CLOSE_REASONS[event.code] ?? null);
    this.socket.onerror = () => {};
  }

  send(payload: object): void {
    const data = JSON.stringify(payload);
    if (this.socket.readyState === WebSocket.OPEN) this.socket.send(data);
    else if (this.socket.readyState === WebSocket.CONNECTING) this.queue.push(data);
  }

  close(): void {
    this.socket.close(1000);
  }
}
