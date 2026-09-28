import { describe, expect, it } from 'vitest';
import { CLOSE } from './link';
import { DataChannelLike, GuestLink, HostLink } from './p2p';
import { decodeSignal, encodeSignal, trimSdp } from './signal';

// Two connected fake data channels (what RTCPeerConnection gives each side).
function channelPair(): [DataChannelLike, DataChannelLike] {
  const make = (): DataChannelLike & { other?: any; readyState: string } => ({
    readyState: 'open',
    onopen: null,
    onmessage: null,
    onclose: null,
    send(data: string) {
      const other = (this as any).other;
      queueMicrotask(() => other.readyState === 'open' && other.onmessage?.({ data }));
    },
    close() {
      [this, (this as any).other].forEach((c: any) => {
        if (c.readyState !== 'closed') { c.readyState = 'closed'; queueMicrotask(() => c.onclose?.({})); }
      });
    },
  });
  const a = make();
  const b = make();
  a.other = b;
  b.other = a;
  return [a, b];
}

const flush = () => new Promise((r) => setTimeout(r, 0));
const texts = (msgs: any[]) => msgs.map((m) => m.text);

function collect(link: HostLink | GuestLink) {
  const received: any[] = [];
  link.subscribe((msgs, reset) => { if (reset) received.length = 0; received.push(...msgs); });
  return received;
}

function joinGuest(host: HostLink, username: string, clientId = username) {
  const [hostSide, guestSide] = channelPair();
  host.attach(hostSide);
  const guest = new GuestLink(guestSide, { username, player: { playerName: username }, clientId });
  return { guest, received: collect(guest), channel: guestSide };
}

describe('peer-to-peer relay', () => {
  it('host and guests share the same ordered messages', async () => {
    const host = new HostLink({ username: 'Amine', player: { playerName: 'Amine' }, game: { round: 1 } });
    const hostMsgs = collect(host);
    expect(texts(hostMsgs)[0].type).toBe('WELCOME');
    expect(texts(hostMsgs)[0].players[0].isHost).toBe(true);

    const sara = joinGuest(host, 'Sara');
    await flush();
    expect(texts(sara.received)[0].type).toBe('WELCOME');
    expect(texts(sara.received)[0].players).toHaveLength(2);
    expect(texts(hostMsgs).at(-1).action).toBe('NEW');

    host.send({ message: { type: 'GAME', action: 'START' } });
    sara.guest.send({ message: { type: 'CHAT', content: 'salam' } });
    await flush(); await flush();
    const order = (msgs: any[]) => texts(msgs).filter((t) => t.type !== 'WELCOME' && t.action !== 'NEW').map((t) => t.action ?? t.content);
    expect(order(hostMsgs)).toEqual(['START', 'salam']);
    expect(order(sara.received)).toEqual(['START', 'salam']);
  });

  it('late joiners enter the running round with the latest settings', async () => {
    const host = new HostLink({ username: 'Amine', player: {}, game: {} });
    host.send({ message: { type: 'GAMESETTING', action: 'update', value: { round: 10 } } });
    host.send({ message: { type: 'GAME', action: 'START' } });
    host.send({ message: { type: 'GAME', action: 'NEWSURAH', value: { randomChap: 18, verse: 9, maxtemp: 110 } } });
    const sara = joinGuest(host, 'Sara');
    await flush();
    const welcome = texts(sara.received)[0];
    expect(welcome.game.round).toBe(10);
    expect(welcome.inProgress).toBe(true);
    expect(welcome.current.randomChap).toBe(18);
  });

  it('refuses duplicate names but lets the same device reconnect', async () => {
    const host = new HostLink({ username: 'Amine', player: {}, clientId: 'h' });
    const sara = joinGuest(host, 'Sara', 'device-1');
    await flush();
    const other = joinGuest(host, 'sara', 'device-2');
    await flush(); await new Promise((r) => setTimeout(r, 150));
    expect(other.guest.status).toBe('closed');
    expect(other.guest.closeReason).toMatch(/déjà utilisé/);
    const again = joinGuest(host, 'Sara', 'device-1');
    await flush(); await new Promise((r) => setTimeout(r, 150));
    expect(again.guest.status).toBe('open');
    expect(sara.guest.status).toBe('closed');
    expect(host.playerCount).toBe(2);
  });

  it('guests cannot change settings, only the host can', async () => {
    const host = new HostLink({ username: 'Amine', player: {} });
    const hostMsgs = collect(host);
    const sara = joinGuest(host, 'Sara');
    await flush();
    sara.guest.send({ message: { type: 'GAMESETTING', action: 'setRound', value: 3 } });
    host.send({ message: { type: 'GAMESETTING', action: 'setRound', value: 5 } });
    await flush();
    expect(texts(hostMsgs).filter((t) => t.type === 'GAMESETTING').map((t) => t.value)).toEqual([5]);
  });

  it('a guest leaving is announced, the host leaving ends the game for everyone', async () => {
    const host = new HostLink({ username: 'Amine', player: {} });
    const hostMsgs = collect(host);
    const sara = joinGuest(host, 'Sara');
    const yusuf = joinGuest(host, 'Yusuf');
    await flush();
    sara.guest.send({ message: { type: 'LEAVE' } });
    await flush(); await new Promise((r) => setTimeout(r, 150));
    expect(texts(hostMsgs).some((t) => t.action === 'REMOVE' && t.value.player.playerName === 'Sara')).toBe(true);
    expect(host.playerCount).toBe(2);

    host.send({ message: { type: 'LEAVE' } });
    await flush(); await new Promise((r) => setTimeout(r, 150));
    expect(host.status).toBe('closed');
    expect(yusuf.guest.status).toBe('closed');
    expect(yusuf.guest.closeReason).toBe("L'hôte a mis fin à la partie.");
    expect(CLOSE.HOST_LEFT).toBe(4003);
  });

  it('ignores garbage sent by a peer', async () => {
    const host = new HostLink({ username: 'Amine', player: {} });
    const [hostSide, guestSide] = channelPair();
    host.attach(hostSide);
    guestSide.send('not json');
    guestSide.send(JSON.stringify({ message: { type: 'CHAT' } })); // before hello
    guestSide.send(JSON.stringify({ hello: { username: '' } }));
    await flush();
    expect(host.playerCount).toBe(1);
    expect(host.status).toBe('open');
  });
});

describe('pairing codes', () => {
  it('round-trips and survives being pasted inside a message', async () => {
    const sdp = trimSdp('v=0\r\na=extmap:1 x\r\na=ice-ufrag:abcd\r\na=candidate:1 1 udp 1 192.168.1.2 5000 typ host\r\n');
    expect(sdp).not.toContain('extmap');
    const code = await encodeSignal({ t: 'o', s: sdp, h: 'Amine' });
    expect(code).toMatch(/^QQ1\.[zj][A-Za-z0-9_-]+$/);
    const decoded = await decodeSignal(`Rejoins ma partie : ${code} (Quran Quizz)`);
    expect(decoded).toEqual({ t: 'o', s: sdp, h: 'Amine' });
  });

  it('rejects anything else', async () => {
    await expect(decodeSignal('hello')).rejects.toThrow();
    await expect(decodeSignal('QQ1.j' + btoa('{"t":"x"}').replace(/=/g, ''))).rejects.toThrow();
  });
});
