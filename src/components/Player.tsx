import { SetStateAction } from "react";




export interface PlayerProps {
  playerName: string;
  guessChapter: number;
  isHost: boolean;
  guessVerse: number;
  streak: number;
  ready: boolean;
  gameState: string;
  found: boolean;
  showScore: boolean;
  score: number;
  showLives: boolean;
  lives: number;
}


export const defaultPlayer: PlayerProps = {
  playerName: "ME",
  guessChapter: 1,
  isHost: false,
  guessVerse: 0,
  streak: 0,
  ready: false,
  gameState: "not ready",
  found: false,
  showScore: false,
  score: 0,
  showLives: false,
  lives: 1
};

export const setGuessChapter = (players: any[],setPlayers: { 
  (value: SetStateAction<PlayerProps[]>): void; (arg0: any[]): void; }
  , playerToUpdate: { playerName: any; }, surah: any) => {
    const playerIndex = players.findIndex((player: { playerName: any; }) => player.playerName === playerToUpdate.playerName);
    if (playerIndex !== -1) {
      const updatedPlayer = { ...players[playerIndex] };
      updatedPlayer.guessChapter = surah;
      const updatedPlayers = [...players];
      updatedPlayers[playerIndex] = updatedPlayer;
      setPlayers(updatedPlayers);
    }
  }
  
  export const setGuessVerse = (players: any[],setPlayers: { 
    (value: SetStateAction<PlayerProps[]>): void; (arg0: any[]): void; }, playerToUpdate: { playerName: any; }, verse: any) => {
    const playerIndex = players.findIndex((player: { playerName: any; }) => player.playerName === playerToUpdate.playerName);
    if (playerIndex !== -1) {
      const updatedPlayer = { ...players[playerIndex] };
      updatedPlayer.guessVerse = verse;
      const updatedPlayers = [...players];
      updatedPlayers[playerIndex] = updatedPlayer;
      setPlayers(updatedPlayers);
    }
  }
  
  
export const setGameState = (players: any[],setPlayers:{ (value: SetStateAction<PlayerProps[]>): void; (arg0: any[]): void; }, playerToUpdate: { playerName: any; }, state: any) => {
  const playerIndex = players.findIndex((player: { playerName: any; }) => player.playerName === playerToUpdate.playerName);
  if (playerIndex !== -1) {
    const updatedPlayer = { ...players[playerIndex] };
    updatedPlayer.gameState = state;
    const updatedPlayers = [...players];
    updatedPlayers[playerIndex] = updatedPlayer;
    setPlayers(updatedPlayers);
  }
}
  

export const makeGuess = (players: PlayerProps[],setPlayers: { 
  (value: SetStateAction<PlayerProps[]>): void; (arg0: any[]): void; },playerToUpdate: { playerName: any; },surah: number,verse: any) => {
  const playerIndex = players.findIndex((player: { playerName: any; }) => player.playerName === playerToUpdate.playerName);
  if (playerIndex !== -1) {
    const updatedPlayer = { ...players[playerIndex] };
    updatedPlayer.ready = true ;
    if(surah === -1){
      updatedPlayer.gameState = 'next';
    }
    else {
      updatedPlayer.guessChapter = surah;
      updatedPlayer.guessVerse = verse;
      updatedPlayer.gameState = 'ready';
    }
    const updatedPlayers = [...players];
    updatedPlayers[playerIndex] = updatedPlayer;
    setPlayers(updatedPlayers);
  }
} 

export const resetScore = (players: PlayerProps[],setPlayers: { 
  (value: SetStateAction<PlayerProps[]>): void; (arg0: any[]): void; }) => {
    const updatedPlayers = players.map(player => ({
      ...player,
      score: 0,
      streak: 0
    }));
    // Mettre à jour l'état des joueurs avec la nouvelle liste mise à jour
    setPlayers(updatedPlayers);
  }


export const setNotReady = (players: PlayerProps[],setPlayers: { 
  (value: SetStateAction<PlayerProps[]>): void; (arg0: any[]): void; }) => {
    const updatedPlayers = players.map(player => ({
      ...player,
      gameState: 'not ready',
      score: 0,
      streak: 0
    }));
    // Mettre à jour l'état des joueurs avec la nouvelle liste mise à jour
    setPlayers(updatedPlayers);
  }
  

  
export const isPlayersLost = (players: PlayerProps[]) => {
    let allLost = true;
    players.forEach(player => {
        if( !player.showLives || player.lives > 0) {
          allLost =  false;
        }
    });
    return allLost;
}

export const checkPlayers = (players:PlayerProps[]) => {
  let allReady = true;
  players.forEach(player => {
      if( ! (player.gameState === 'ready' ||  player.gameState === 'next' ) ) {
        allReady =  false;
      }
  });
  return allReady;
}



export const recvPlayerMSG = (message:any,players: PlayerProps[],setPlayers: { 
  (value: SetStateAction<PlayerProps[]>): void; (arg0: any[]): void; } ) => {
  const { action, value } =  message;
  switch (action) {
    case "NEW":
      setPlayers(prevPlayers => [...prevPlayers, {...value}]);
      break;
    case "makeGuess":
      // Traitement pour makeGuess
      makeGuess(players,setPlayers, value.player,value.surah,value.verse);
      break;
    case "setGuessChapter":
      // Traitement pour setGuessChapter
      setGuessChapter(players,setPlayers, value.player,value.surah);
      break;
    case "setGuessVerse":
      setGuessVerse(players,setPlayers, value.player,value.verse);
      // Traitement pour setGuessVerse
      break;
    case "setGameState":
      setGameState(players,setPlayers, value.player,value.state);
      break;
    case "resetScore":
      resetScore(players,setPlayers);
      break;
    default:
      break;
  }
}