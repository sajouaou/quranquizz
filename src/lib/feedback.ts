import { Capacitor } from '@capacitor/core';
import { Haptics, NotificationType } from '@capacitor/haptics';

// Short vibration on round results (phones only; silently ignored elsewhere).
export function vibrateResult(result: 'win' | 'lose' | 'next'): void {
  if (!Capacitor.isNativePlatform()) {
    if (result !== 'win') navigator.vibrate?.(80);
    return;
  }
  const type = result === 'win' ? NotificationType.Success : result === 'lose' ? NotificationType.Error : NotificationType.Warning;
  Haptics.notification({ type }).catch(() => {});
}

export const PUBLIC_URL = 'https://quranquizz.onrender.com';

// Invite friends to a room: native share sheet when available, clipboard otherwise.
export async function shareRoom(room: string): Promise<'shared' | 'copied' | 'failed'> {
  const url = `${PUBLIC_URL}/online?room=${encodeURIComponent(room)}`;
  const text = `Rejoins-moi sur Quran Quizz, salon « ${room} »`;
  try {
    if (navigator.share) {
      await navigator.share({ title: 'Quran Quizz', text, url });
      return 'shared';
    }
    await navigator.clipboard.writeText(`${text} : ${url}`);
    return 'copied';
  } catch (error) {
    return (error as DOMException)?.name === 'AbortError' ? 'shared' : 'failed';
  }
}
