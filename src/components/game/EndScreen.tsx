import { IonButton, IonIcon } from '@ionic/react';
import { checkmarkCircle, closeCircle, playSkipForward, refresh, trophy } from 'ionicons/icons';
import type { Chapter } from './Game';
import { PlayerProps } from './Player';

export interface RoundResult {
  surah: number;
  verse: number; // 0-based
  result: 'win' | 'lose' | 'next' | 'out';
}

interface EndScreenProps {
  players: PlayerProps[];
  mode: string;
  history: RoundResult[];
  chapters: Chapter[];
  record?: { best: number; isRecord: boolean } | null;
  canRestart: boolean;
  onRestart: () => void;
  onLeave: () => void;
}

const MEDALS = ['🥇', '🥈', '🥉'];
const RESULT_ICON = { win: checkmarkCircle, lose: closeCircle, next: playSkipForward, out: closeCircle };

const EndScreen: React.FC<EndScreenProps> = ({ players, history, chapters, record, canRestart, onRestart, onLeave }) => {
  const sortedPlayers = [...players].sort((a, b) => b.score - a.score);
  const solo = players.length === 1;
  const score = sortedPlayers[0]?.score ?? 0;

  return (
    <div className="end-screen card">
      <IonIcon icon={trophy} className="end-trophy" />
      <h2>Partie terminée</h2>
      {solo ? (
        <>
          <p className="end-score">
            <strong>{score}</strong> bonne{score > 1 ? 's' : ''} réponse{score > 1 ? 's' : ''}
          </p>
          {record?.isRecord && <p className="end-record">Nouveau record !</p>}
          {record && !record.isRecord && record.best > 0 && <p className="end-best">Record : {record.best}</p>}
        </>
      ) : (
        <ol className="ranking">
          {sortedPlayers.map((player, index) => (
            <li key={player.id ?? index} className={index < 3 ? 'podium' : ''}>
              <span className="rank">{MEDALS[index] ?? `#${index + 1}`}</span>
              <span className="name">{player.playerName}</span>
              <span className="score">{player.score} pts</span>
            </li>
          ))}
        </ol>
      )}

      {history.length > 0 && (
        <details className="round-history">
          <summary>Récapitulatif des {history.length} manche{history.length > 1 ? 's' : ''}</summary>
          <ol>
            {history.map((round, i) => {
              const chapter = chapters.find((c) => c.id === round.surah);
              return (
                <li key={i} className={`result-${round.result}`}>
                  <IonIcon icon={RESULT_ICON[round.result]} />
                  <span>{round.surah}. {chapter?.name_simple ?? ''}</span>
                  <small>v. {round.verse + 1}</small>
                </li>
              );
            })}
          </ol>
        </details>
      )}

      <div className="end-actions">
        {canRestart && (
          <IonButton expand="block" onClick={onRestart}>
            <IonIcon slot="start" icon={refresh} />
            Rejouer
          </IonButton>
        )}
        <IonButton expand="block" fill="outline" onClick={onLeave}>Retour au menu</IonButton>
      </div>
    </div>
  );
};

export default EndScreen;
