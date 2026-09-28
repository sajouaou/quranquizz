import { IonButton, IonIcon } from '@ionic/react';
import { refresh, trophy } from 'ionicons/icons';
import { PlayerProps } from './Player';

interface EndScreenProps {
  players: PlayerProps[];
  canRestart: boolean;
  onRestart: () => void;
  onLeave: () => void;
}

const MEDALS = ['🥇', '🥈', '🥉'];

const EndScreen: React.FC<EndScreenProps> = ({ players, canRestart, onRestart, onLeave }) => {
  const sortedPlayers = [...players].sort((a, b) => b.score - a.score);
  const solo = players.length === 1;

  return (
    <div className="end-screen card">
      <IonIcon icon={trophy} className="end-trophy" />
      <h2>Partie terminée</h2>
      {solo ? (
        <p className="end-score">
          <strong>{sortedPlayers[0].score}</strong> bonne{sortedPlayers[0].score > 1 ? 's' : ''} réponse
          {sortedPlayers[0].score > 1 ? 's' : ''}
        </p>
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
