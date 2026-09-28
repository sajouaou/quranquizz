import { IonIcon } from '@ionic/react';
import { flame, heart, star } from 'ionicons/icons';
import { isEliminated, type PlayerProps } from './Player';

const STATE_LABEL: Record<string, string> = {
  'not ready': 'Réfléchit…',
  ready: 'A répondu',
  next: 'Passe',
  win: 'Correct',
  lose: 'Faux',
};

interface PlayerListProps {
  players: PlayerProps[];
  showScore: boolean;
  inGame: boolean;
}

const PlayerList: React.FC<PlayerListProps> = ({ players, showScore, inGame }) => (
  <ul className="player-list">
    {players.map((player, index) => (
      <li key={player.id ?? index} className={`player-chip state-${player.gameState.replace(' ', '-')}${index === 0 ? ' me' : ''}`}>
        <span className="avatar">{player.playerName?.charAt(0).toUpperCase() || '?'}</span>
        <span className="player-info">
          <span className="player-name">
            {player.playerName}
            {index === 0 && <small> (toi)</small>}
            {player.isHost && <span className="host-badge" title="Hôte">★</span>}
          </span>
          {inGame && (
            <span className="player-state">
              {isEliminated(player) ? 'Éliminé' : STATE_LABEL[player.gameState] ?? player.gameState}
            </span>
          )}
        </span>
        <span className="player-stats">
          {showScore && (
            <span title="Score"><IonIcon icon={star} />{player.score}</span>
          )}
          {showScore && player.streak > 1 && (
            <span title="Série" className="streak"><IonIcon icon={flame} />{player.streak}</span>
          )}
          {player.showLives && (
            <span title="Vies" className="lives"><IonIcon icon={heart} />{player.lives}</span>
          )}
        </span>
      </li>
    ))}
  </ul>
);

export default PlayerList;
