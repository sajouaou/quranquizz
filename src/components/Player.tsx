import { SetStateAction } from "react";

export const setGuessChapter = (players: any[],setPlayers: { (value: SetStateAction<{ playerName: string; guessChapter: number; isHost: boolean; guessVerse: number; streak: number; ready: boolean; gameState: string; found: boolean; correctChapter: number; correctVerse: number; showScore: boolean; score: number; showLives: boolean; lives: number; }[]>): void; (arg0: any[]): void; }, playerToUpdate: { playerName: any; }, surah: any) => {
    const playerIndex = players.findIndex((player: { playerName: any; }) => player.playerName === playerToUpdate.playerName);
    if (playerIndex !== -1) {
      const updatedPlayer = { ...players[playerIndex] };
      updatedPlayer.guessChapter = surah;
      const updatedPlayers = [...players];
      updatedPlayers[playerIndex] = updatedPlayer;
      setPlayers(updatedPlayers);
    }
  }
  
  export const setGuessVerse = (players: any[],setPlayers: { (value: SetStateAction<{ playerName: string; guessChapter: number; isHost: boolean; guessVerse: number; streak: number; ready: boolean; gameState: string; found: boolean; correctChapter: number; correctVerse: number; showScore: boolean; score: number; showLives: boolean; lives: number; }[]>): void; (arg0: any[]): void; }, playerToUpdate: { playerName: any; }, verse: any) => {
    const playerIndex = players.findIndex((player: { playerName: any; }) => player.playerName === playerToUpdate.playerName);
    if (playerIndex !== -1) {
      const updatedPlayer = { ...players[playerIndex] };
      updatedPlayer.guessVerse = verse;
      const updatedPlayers = [...players];
      updatedPlayers[playerIndex] = updatedPlayer;
      setPlayers(updatedPlayers);
    }
  }
  
  
  export const setGameState = (players: any[],setPlayers: { (value: SetStateAction<{ playerName: string; guessChapter: number; isHost: boolean; guessVerse: number; streak: number; ready: boolean; gameState: string; found: boolean; correctChapter: number; correctVerse: number; showScore: boolean; score: number; showLives: boolean; lives: number; }[]>): void; (arg0: any[]): void; }, playerToUpdate: { playerName: any; }, state: any) => {
    const playerIndex = players.findIndex((player: { playerName: any; }) => player.playerName === playerToUpdate.playerName);
    if (playerIndex !== -1) {
      const updatedPlayer = { ...players[playerIndex] };
      updatedPlayer.gameState = state;
      const updatedPlayers = [...players];
      updatedPlayers[playerIndex] = updatedPlayer;
      setPlayers(updatedPlayers);
    }
  }
  

  export const next = (players: any[],setPlayers: (arg0: any[]) => void, playerToUpdate: { playerName: any; }) => {
    const playerIndex = players.findIndex((player: { playerName: any; }) => player.playerName === playerToUpdate.playerName);
    if (playerIndex !== -1) {
      const updatedPlayer = { ...players[playerIndex] };
      updatedPlayer.ready = false ;
      updatedPlayer.gameState = 'next';
      updatedPlayer.streak = 0;
      updatedPlayer.lives = updatedPlayer.lives -1;
      const updatedPlayers = [...players];
      updatedPlayers[playerIndex] = updatedPlayer;
      setPlayers(updatedPlayers);
    }
  } 
  
  export const success = (players: any[],setPlayers: (arg0: any[]) => void, playerToUpdate: { playerName: any; }) => {
    const playerIndex = players.findIndex((player: { playerName: any; }) => player.playerName === playerToUpdate.playerName);
    if (playerIndex !== -1) {
      const updatedPlayer = { ...players[playerIndex] };
      updatedPlayer.ready = false ;
      updatedPlayer.gameState = 'win';
      updatedPlayer.score = updatedPlayer.score +1;
      updatedPlayer.streak = updatedPlayer.streak+1;
      const updatedPlayers = [...players];
      updatedPlayers[playerIndex] = updatedPlayer;
      setPlayers(updatedPlayers);
    }
  
  } 
  export  const faillure = (players: any[],setPlayers: (arg0: any[]) => void, playerToUpdate: { playerName: any; }) => {
    const playerIndex = players.findIndex((player: { playerName: any; }) => player.playerName === playerToUpdate.playerName);
    console.log("TEST FIND - ",playerToUpdate);
    console.log("TEST FOUND - ",playerIndex);
    if (playerIndex !== -1) {
      const updatedPlayer = { ...players[playerIndex] };
      console.log("UPDATED FOUND - ",updatedPlayer);
      updatedPlayer.ready = false ;
      updatedPlayer.gameState = 'lose';
      updatedPlayer.streak = 0;
      updatedPlayer.lives = updatedPlayer.lives -1;
      const updatedPlayers = [...players];
      updatedPlayers[playerIndex] = updatedPlayer;
      console.log("UPDATED  ff FOUND - ",updatedPlayers);
      setPlayers(updatedPlayers);
    }
  
  } 

export const makeGuess = (players: any[],setPlayers: { (value: SetStateAction<{ playerName: string; guessChapter: number; isHost: boolean; guessVerse: number; streak: number; ready: boolean; gameState: string; found: boolean; correctChapter: number; correctVerse: number; showScore: boolean; score: number; showLives: boolean; lives: number; }[]>): void; (arg0: any[]): void; }, playerToUpdate: { playerName: any; },surah: number,verse: any) => {
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

