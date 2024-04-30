import { PlayerProps } from "./Player";

interface EndScreenProps {
    players:PlayerProps[];
}

const EndScreen: React.FC<EndScreenProps> = ({players}) => {
      // Trier les joueurs par score du plus bas au plus haut
      const sortedPlayers = [...players].sort((a, b) => b.score - a.score );

      return (
          <div>
              <h2>End of Game</h2>
              <div>
                  {sortedPlayers.map((player, index) => (
                      <div key={index}>
                          <p>{player.playerName} - Score: {player.score}</p>
                      </div>
                  ))}
              </div>
              <h3>Podium:</h3>
              <div>
                  {sortedPlayers.slice(0, 3).map((player, index) => (
                      <div key={index}>
                          <p>#{index + 1}: {player.playerName} - Score: {player.score}</p>
                      </div>
                  ))}
              </div>
          </div>
      );
}

export default EndScreen;