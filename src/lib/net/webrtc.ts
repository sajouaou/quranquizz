import { decodeSignal, encodeSignal, trimSdp } from './signal';

// Public STUN servers only help when both devices have Internet access (to cross
// routers). On a local network or a phone hotspot, devices connect directly and
// none of this is needed: gathering simply times out and local candidates are used.
const ICE_SERVERS: RTCIceServer[] = [{ urls: ['stun:stun.l.google.com:19302', 'stun:stun.cloudflare.com:3478'] }];

export const isWebRtcSupported = () => typeof RTCPeerConnection !== 'undefined';

function gatheringComplete(pc: RTCPeerConnection, timeoutMs = 2500): Promise<void> {
  if (pc.iceGatheringState === 'complete') return Promise.resolve();
  return new Promise((resolve) => {
    const done = () => {
      pc.removeEventListener('icegatheringstatechange', check);
      clearTimeout(timer);
      resolve();
    };
    const check = () => { if (pc.iceGatheringState === 'complete') done(); };
    const timer = setTimeout(done, timeoutMs);
    pc.addEventListener('icegatheringstatechange', check);
  });
}

export function waitOpen(channel: RTCDataChannel, timeoutMs = 45000): Promise<RTCDataChannel> {
  if (channel.readyState === 'open') return Promise.resolve(channel);
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error('La connexion a expiré. Réessaie en étant sur le même réseau Wi-Fi.')), timeoutMs);
    channel.addEventListener('open', () => { clearTimeout(timer); resolve(channel); }, { once: true });
    channel.addEventListener('close', () => { clearTimeout(timer); reject(new Error('Connexion refusée.')); }, { once: true });
  });
}

// Closes the channel when the peer connection dies, so the game sees the player leave.
function watch(pc: RTCPeerConnection, channel: () => RTCDataChannel | null) {
  pc.addEventListener('connectionstatechange', () => {
    if (pc.connectionState === 'failed' || pc.connectionState === 'closed') channel()?.close();
  });
}

// Host side, step 1: a code to show to the guest.
export async function createOffer(hostName: string) {
  const pc = new RTCPeerConnection({ iceServers: ICE_SERVERS });
  const channel = pc.createDataChannel('quranquizz', { ordered: true });
  watch(pc, () => channel);
  await pc.setLocalDescription(await pc.createOffer());
  await gatheringComplete(pc);
  const code = await encodeSignal({ t: 'o', s: trimSdp(pc.localDescription!.sdp), h: hostName });
  return { pc, channel, code };
}

// Host side, step 2: the guest's answer code.
export async function acceptAnswer(pc: RTCPeerConnection, text: string): Promise<string> {
  const signal = await decodeSignal(text);
  if (signal.t !== 'a') throw new Error("Ce code est une invitation d'hôte, pas une réponse de joueur.");
  await pc.setRemoteDescription({ type: 'answer', sdp: signal.s });
  return signal.n;
}

// Guest side: reads the host's code and produces the answer code.
export async function answerOffer(text: string, guestName: string) {
  const signal = await decodeSignal(text);
  if (signal.t !== 'o') throw new Error("Ce code est une réponse de joueur : scanne le code affiché par l'hôte.");
  const pc = new RTCPeerConnection({ iceServers: ICE_SERVERS });
  let channel: RTCDataChannel | null = null;
  watch(pc, () => channel);
  const channelReady = new Promise<RTCDataChannel>((resolve) => {
    pc.ondatachannel = (event) => { channel = event.channel; resolve(event.channel); };
  });
  await pc.setRemoteDescription({ type: 'offer', sdp: signal.s });
  await pc.setLocalDescription(await pc.createAnswer());
  await gatheringComplete(pc);
  const code = await encodeSignal({ t: 'a', s: trimSdp(pc.localDescription!.sdp), n: guestName });
  return { pc, code, hostName: signal.h, channel: channelReady };
}
