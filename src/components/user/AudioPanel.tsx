import { IonIcon, IonSpinner } from '@ionic/react';
import { play, refresh, volumeHigh } from 'ionicons/icons';
import type { AudioPlayer } from '../../hooks/useAudioPlayer';
import { findReciter, reciterLabel } from '../../lib/quranApi';
import { usePrefs } from '../../lib/prefs';

const LABELS: Record<AudioPlayer['status'], string> = {
  idle: 'En attente de la récitation',
  loading: 'Chargement…',
  playing: 'Écoute attentivement',
  ended: 'Appuie pour réécouter',
  blocked: 'Appuie pour écouter',
  error: 'Audio indisponible — réessayer',
};

const AudioPanel: React.FC<{ audio: AudioPlayer }> = ({ audio }) => {
  const { reciterId } = usePrefs();
  const { status, current, total } = audio;
  const icon = status === 'playing' ? volumeHigh : status === 'error' || status === 'ended' ? refresh : play;

  return (
    <div className={`audio-panel card status-${status}`}>
      <button
        type="button"
        className="audio-button"
        onClick={audio.replay}
        disabled={status === 'idle' || status === 'loading'}
        aria-label={status === 'playing' ? 'Réécouter depuis le début' : LABELS[status]}
      >
        {status === 'loading' ? <IonSpinner name="crescent" /> : <IonIcon icon={icon} />}
      </button>
      <div className="audio-info">
        <strong>{LABELS[status]}</strong>
        {total > 1 && (
          <span>Ayah {Math.min(current + 1, total)} / {total}</span>
        )}
        <small>{reciterLabel(findReciter(reciterId))}</small>
      </div>
    </div>
  );
};

export default AudioPanel;
