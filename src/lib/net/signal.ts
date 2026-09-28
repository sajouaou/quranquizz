// Pairing codes exchanged between devices (QR code or copy/paste) to open a
// WebRTC connection without any server: "QQ1." + mode + base64url(payload).

export interface OfferSignal { t: 'o'; s: string; h: string } // host name
export interface AnswerSignal { t: 'a'; s: string; n: string } // guest name
export type Signal = OfferSignal | AnswerSignal;

const PREFIX = 'QQ1.';

const toBase64Url = (bytes: Uint8Array) => {
  let binary = '';
  bytes.forEach((b) => { binary += String.fromCharCode(b); });
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
};

const fromBase64Url = (text: string) => {
  const base64 = text.replace(/-/g, '+').replace(/_/g, '/');
  const binary = atob(base64 + '='.repeat((4 - (base64.length % 4)) % 4));
  return Uint8Array.from(binary, (c) => c.charCodeAt(0));
};

async function transform(bytes: Uint8Array, stream: CompressionStream | DecompressionStream): Promise<Uint8Array> {
  const writer = stream.writable.getWriter();
  writer.write(bytes as Uint8Array<ArrayBuffer>);
  writer.close();
  return new Uint8Array(await new Response(stream.readable).arrayBuffer());
}

// Keep only what a data channel needs: smaller codes, easier QR scans.
export function trimSdp(sdp: string): string {
  return sdp
    .split(/\r?\n/)
    .filter((line) => line && !line.startsWith('a=extmap') && !line.startsWith('a=msid-semantic'))
    .join('\r\n') + '\r\n';
}

export async function encodeSignal(signal: Signal): Promise<string> {
  const bytes = new TextEncoder().encode(JSON.stringify(signal));
  if (typeof CompressionStream !== 'undefined') {
    return `${PREFIX}z${toBase64Url(await transform(bytes, new CompressionStream('deflate-raw')))}`;
  }
  return `${PREFIX}j${toBase64Url(bytes)}`;
}

// Accepts the code alone or pasted inside a longer message.
export async function decodeSignal(text: string): Promise<Signal> {
  const match = text.match(/QQ1\.([zj])([A-Za-z0-9_-]+)/);
  if (!match) throw new Error("Ce n'est pas un code Quran Quizz.");
  let bytes: Uint8Array = fromBase64Url(match[2]);
  if (match[1] === 'z') bytes = await transform(bytes, new DecompressionStream('deflate-raw'));
  const signal = JSON.parse(new TextDecoder().decode(bytes));
  if ((signal?.t !== 'o' && signal?.t !== 'a') || typeof signal.s !== 'string') throw new Error('Code invalide.');
  return signal as Signal;
}
