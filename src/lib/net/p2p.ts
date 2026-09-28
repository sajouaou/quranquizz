import { CLOSE, RoomLink, parsePayload } from './link';
import { Hello, Relay, RelayMember } from './relay';

// Minimal part of RTCDataChannel we rely on (also implemented by test doubles).
export interface DataChannelLike {
  readonly readyState: string;
  send(data: string): void;
  close(): void;
  onopen: ((ev: any) => void) | null;
  onmessage: ((ev: any) => void) | null;
  onclose: ((ev: any) => void) | null;
}

interface Closable {
  close(): void;
}

const safeSend = (channel: DataChannelLike, payload: object) => {
  if (channel.readyState === 'open') {
    try {
      channel.send(JSON.stringify(payload));
    } catch {
      // closing
    }
  }
};

// The device hosting a peer-to-peer game: it is both the relay and a player.
export class HostLink extends RoomLink {
  readonly kind = 'host' as const;
  readonly relay = new Relay();
  private self: RelayMember | null;
  private guests = new Set<{ channel: DataChannelLike; peer?: Closable }>();

  constructor(hello: Hello) {
    super();
    this.self = this.relay.join(
      hello,
      (msg) => this.receive({ append: [msg] }),
      () => this.close(),
    );
    this.setStatus(this.self ? 'open' : 'closed');
  }

  get playerCount(): number {
    return this.relay.members.size;
  }

  send(payload: object): void {
    if (this.self && this.status === 'open') this.relay.receive(this.self, payload);
  }

  // Plugs a guest's data channel into the relay. The guest introduces itself with { hello }.
  attach(channel: DataChannelLike, peer?: Closable): void {
    const guest = { channel, peer };
    this.guests.add(guest);
    let member: RelayMember | null = null;
    const drop = () => {
      this.guests.delete(guest);
      if (member) this.relay.leave(member);
      member = null;
    };
    channel.onmessage = (event) => {
      const data = parsePayload(event.data) as ({ hello?: Hello } & Record<string, unknown>) | null;
      if (!data || this.status !== 'open') return;
      if (!member) {
        if (data.hello) {
          member = this.relay.join(
            data.hello,
            (msg) => safeSend(channel, { append: [msg] }),
            (code, reason) => {
              safeSend(channel, { close: { code, reason } });
              setTimeout(() => { channel.close(); peer?.close(); }, 100);
            },
          );
        }
        return;
      }
      this.relay.receive(member, data);
    };
    channel.onclose = drop;
  }

  close(): void {
    if (this.status === 'closed') return;
    this.self = null;
    this.guests.forEach(({ channel, peer }) => {
      safeSend(channel, { close: { code: CLOSE.HOST_LEFT, reason: 'Host left' } });
      setTimeout(() => { channel.close(); peer?.close(); }, 100);
    });
    this.guests.clear();
    this.setStatus('closed');
  }
}

// A player connected to a peer-to-peer host.
export class GuestLink extends RoomLink {
  readonly kind = 'guest' as const;

  constructor(private readonly channel: DataChannelLike, hello: Hello, private readonly peer?: Closable) {
    super();
    channel.onmessage = (event) => {
      const payload = parsePayload(event.data);
      if (payload) this.receive(payload);
    };
    channel.onclose = () => this.setStatus('closed', "La connexion avec l'hôte a été perdue.");
    const start = () => {
      channel.send(JSON.stringify({ hello }));
      this.setStatus('open');
    };
    if (channel.readyState === 'open') start();
    else channel.onopen = start;
  }

  send(payload: object): void {
    safeSend(this.channel, payload);
  }

  close(): void {
    this.channel.close();
    this.peer?.close();
    this.setStatus('closed');
  }
}
