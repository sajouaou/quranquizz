import React, { useState, useEffect, useCallback } from 'react';
import { ReadyState } from 'react-use-websocket';
// Named import: the package's CJS default export isn't picked up by Vite's interop.
import { useWebSocket } from 'react-use-websocket/dist/lib/use-websocket';
import { IonBadge, IonButton, IonButtons, IonContent, IonHeader, IonIcon, IonProgressBar, IonTitle, IonToolbar } from '@ionic/react';
import { arrowBack, chatbubbles, heart, play, settingsOutline, stopCircleOutline } from 'ionicons/icons';
import Settings from './user/Settings';
import InputGame from './user/InputGame';
import AudioPanel from './user/AudioPanel';
import Chat from './client/Chat';
import EndScreen from './game/EndScreen';
import PlayerList from './game/PlayerList';
import {
  Chapter,
  GameProps,
  checkChoice,
  defaultGame,
  getRandomChapterNumber,
  getRandomVerseNumber,
  recvGameMSG,
  recvGameSettingMSG } from './game/Game';
import { PlayerProps, checkPlayers, defaultPlayer, isPlayersLost, recvPlayerMSG } from './game/Player';
import { getSettingsGameMode, setGameMode } from './game/GameMode';
import { useAudioPlayer } from '../hooks/useAudioPlayer';
import './GameContainer.css';

export const MODE_LABELS: Record<string, string> = {
  Training: 'Entraînement',
  Arcade: 'Arcade',
  Survie: 'Survie',
  Online: 'En ligne',
};

const MODE_INTRO: Record<string, string> = {
  Training: 'Écoute une récitation et retrouve la sourate. Personnalise la plage de sourates dans les réglages.',
  Arcade: '10 manches, un point par bonne réponse. Vise le score parfait !',
  Survie: 'Tu as 3 vies. Chaque erreur en coûte une : tiens le plus longtemps possible.',
  Online: "Partage le nom du salon à tes amis. L'hôte règle la partie puis la lance.",
};

interface ContainerProps {
  mode: string;
  chapters: Chapter[];
  name: string;
  room?: string;
  endpoint?: string;
  leave: () => void;
}

const GameContainer: React.FC<ContainerProps> = ({ mode, chapters, name, room, endpoint, leave }) => {
  const online = mode === 'Online';

  //////////////////////////////
  //  ONLINE SECTION
  //////////////////////////////
  // The server relays every message to every player of the room (sender included)
  // and always sends back the whole history, which is replayed through `readCursor`.
  const { sendJsonMessage, lastJsonMessage, readyState } = useWebSocket(
    online && endpoint ? endpoint : null,
    {
      queryParams: {
        username: name,
        room: room ?? '',
        player: JSON.stringify({ ...defaultPlayer, playerName: name }),
        game: JSON.stringify({ ...defaultGame }),
      },
      share: true,
      shouldReconnect: () => false,
    },
  );

  useEffect(() => {
    if (lastJsonMessage !== null) {
      const typedMessage = lastJsonMessage as { messages: any[] };
      setMessages([...typedMessage.messages]);
    }
  }, [lastJsonMessage]);

  const sendMessage = useCallback((msg: any) => sendJsonMessage(msg), [sendJsonMessage]);

  const handleSubmit = (e: { preventDefault: () => void; }) => {
    e.preventDefault();
    if (message.trim() && online) {
      sendMessage({ message: { content: message.trim(), type: "CHAT" } });
      setMessage("");
    }
  };

  const sendGameMessage = (message: any) => {
    if (online) {
      sendMessage({ message, game, players });
    } else {
      setMessages((messages) => [...messages, { user: "LOCAL", text: message }]);
    }
  };

  //////////////////////////////
  //  MESSAGE MANAGMENT
  //////////////////////////////
  const [readCursor, setReadCursor] = useState(0);
  const [messages, setMessages] = useState<any[]>([]);
  const [message, setMessage] = useState("");
  const [showChat, setShowChat] = useState(false);
  const [seenChat, setSeenChat] = useState(0);

  useEffect(() => {
    if (readCursor < messages.length) {
      parseMessage(messages[readCursor].text);
      setReadCursor(readCursor + 1);
    }
  }, [readCursor, messages]);

  const recvGameMessage = (message: any) => {
    const { action, value } = message;
    recvGameMSG(message, setGame, setPlayers, players, game);
    switch (action) {
      case "ENDGAME":
        audio.stop();
        setShowEnd(true);
        setShowInput(false);
        break;
      case "ENDROUND":
        handleEndRound(value);
        break;
      case "NEWSURAH": {
        const { randomChap, verse, maxtemp } = value;
        audio.load(randomChap, verse, Math.min(game.numberOfAyat, maxtemp - verse));
        break;
      }
      case "START":
        if (players[0].isHost) {
          // Scores and lives are being reset by this same message: don't check the old ones.
          newSurah(0, true);
        }
        setShowInput(true);
        setShowEnd(false);
        break;
      default:
        break;
    }
  };

  const recvAudioMessage = (message: { action: any; value: any; }) => {
    const { action, value } = message;
    if (action === "AUDIOFETCH") {
      audio.load(value.surah, value.verse, game.numberOfAyat);
    }
  };

  const recvWelcomeMessage = (message: { game: GameProps, players: any[]; }) => {
    const { game, players: pls } = message;
    setGame({ ...game });
    setPlayers([...pls.filter((player) => player.playerName === players[0].playerName), ...pls.filter((player) => player.playerName !== players[0].playerName)]);
  };

  const parseMessage = (message: any) => {
    switch (message.type) {
      case "GAMESETTING":
        recvGameSettingMSG(message, setGame, setPlayers, players, game);
        break;
      case "PLAYER":
        recvPlayerMSG(message, players, setPlayers);
        // The server only knows the settings the room was created with:
        // the host shares the current ones with whoever joins.
        if (message.action === "NEW" && online && players[0].isHost) {
          sendGameMessage({ content: 'Game settings synced', action: 'update', type: 'GAMESETTING', value: game });
        }
        break;
      case "GAME":
        recvGameMessage(message);
        break;
      case "AUDIO":
        recvAudioMessage(message);
        break;
      case "WELCOME":
        recvWelcomeMessage(message);
        break;
      default:
        break;
    }
  };

  //////////////////////////////
  //  GAME MANAGMENT
  //////////////////////////////
  const [game, setGame] = useState<GameProps>({ ...defaultGame });
  const [players, setPlayers] = useState<PlayerProps[]>([{ ...defaultPlayer, playerName: name, isHost: !online }]);
  const audio = useAudioPlayer();

  useEffect(() => {
    setGameMode(mode, setGame, setPlayers, players);
  }, [mode]);

  const checkGuessAllPlayers = () => {
    if (!players[0].isHost || !showInput) return;
    const allReady = checkPlayers(players);
    if (!allReady) {
      sendGameMessage({ content: 'Not every one is ready', action: 'READY', type: 'GAME', value: allReady });
      return;
    }

    let everyoneFail = true;
    sendGameMessage({ content: `The correct  answer was chapter : ${game.confirmedChapter} verse : ${game.confirmedVerse}`, action: 'CORRECT', type: 'GAME', value: { surah: game.confirmedChapter, verse: game.confirmedVerse } });
    const endResult: any[] = [];
    players.forEach(player => {
      if (player.gameState !== 'next') {
        if (checkChoice(game, player.guessChapter, player.guessVerse)) {
          everyoneFail = false;
          endResult.push({ state: "win", player });
        } else {
          endResult.push({ state: "lose", player });
        }
      } else {
        everyoneFail = false;
        endResult.push({ state: "next", player });
      }
    });

    sendGameMessage({ content: 'The round is finished', action: 'ENDROUND', type: 'GAME', value: endResult });
    sendGameMessage({ content: 'The next round will start', action: 'READY', type: 'GAME', value: allReady });

    // Lives after this round (the players state is only updated once ENDROUND is processed).
    const livesAfter = endResult.map(({ state, player }) => ({
      ...player,
      lives: state === 'win' ? player.lives : player.lives - 1,
    }));
    const moveOn = game.isSkip || !everyoneFail;
    const nextRound = moveOn ? game.currentRound + 1 : game.currentRound;
    if (moveOn) {
      sendGameMessage({ content: `Round ${nextRound + 1}`, action: 'SETROUND', type: 'GAME', value: nextRound });
    }
    const finished = (game.isLimited && nextRound >= game.round) || isPlayersLost(livesAfter);
    if (finished) {
      setTimeout(() => sendGameMessage({ content: 'The game is finished', action: 'ENDGAME', type: 'GAME' }), 1500);
    } else if (moveOn) {
      setTimeout(() => newSurah(nextRound, true), 1200);
    }
  };

  const handleEndRound = (value: any[]) => {
    const updatedPlayers = [...players];
    value.forEach((element: { state: any; player: any; }) => {
      const { state, player } = element;
      const playerIndex = players.findIndex(otherPlayer => otherPlayer.playerName === player.playerName);
      if (playerIndex !== -1) {
        const updatedPlayer = { ...players[playerIndex] };
        switch (state) {
          case "win":
            updatedPlayer.ready = false;
            updatedPlayer.gameState = 'win';
            updatedPlayer.score = updatedPlayer.score + 1;
            updatedPlayer.streak = updatedPlayer.streak + 1;
            break;
          case "lose":
          case "next":
            updatedPlayer.ready = false;
            updatedPlayer.gameState = state;
            updatedPlayer.streak = 0;
            updatedPlayer.lives = updatedPlayer.lives - 1;
            break;
          default:
            break;
        }
        updatedPlayers[playerIndex] = updatedPlayer;
      }
    });
    setPlayers(updatedPlayers);
  };

  const newSurah = (curRound: number, skipLivesCheck = false) => {
    if ((!game.isLimited || curRound < game.round) && (skipLivesCheck || !isPlayersLost(players))) {
      const randomChap = getRandomChapterNumber(game, chapters);
      const { verse, maxtemp } = getRandomVerseNumber(game, chapters, randomChap);
      sendGameMessage({ content: 'New surah  selected', action: 'NEWSURAH', type: 'GAME', value: { randomChap, verse, maxtemp } });
    }
  };

  //////////////////////////////
  //  START/END CONTROL
  //////////////////////////////
  const handleStartClick = () => {
    sendGameMessage({ content: 'The game is starting', action: 'START', type: 'GAME' });
  };

  const handleLeave = () => {
    audio.stop();
    if (online) sendGameMessage({ content: "Bye", type: "LEAVE", id: players[0].id });
    leave();
  };

  //////////////////////////////
  //  USER INTERFACE
  //////////////////////////////
  const [showInput, setShowInput] = useState(false);
  const [showEnd, setShowEnd] = useState(false);
  const [showSettings, setShowSettings] = useState(false);

  const isHost = players[0].isHost;
  const chatCount = messages.filter((m) => m.text?.type === 'CHAT').length;
  const unread = showChat ? 0 : chatCount - seenChat;
  useEffect(() => {
    if (showChat) setSeenChat(chatCount);
  }, [showChat, chatCount]);

  const connecting = online && readyState === ReadyState.CONNECTING;
  const disconnected = online && (readyState === ReadyState.CLOSED || readyState === ReadyState.CLOSING);
  const me = players[0];

  return (
    <>
      <IonHeader>
        <IonToolbar>
          <IonButtons slot="start">
            <IonButton onClick={handleLeave} aria-label="Quitter">
              <IonIcon slot="icon-only" icon={arrowBack} />
            </IonButton>
          </IonButtons>
          <IonTitle>
            {MODE_LABELS[mode] ?? mode}
            {online && room ? <span className="room-name"> · {room}</span> : null}
          </IonTitle>
          <IonButtons slot="end">
            {online && (
              <IonButton onClick={() => setShowChat(true)} aria-label="Discussion" className="badge-button">
                <IonIcon slot="icon-only" icon={chatbubbles} />
                {unread > 0 && <IonBadge color="danger">{unread}</IonBadge>}
              </IonButton>
            )}
            <IonButton onClick={() => setShowSettings(true)} aria-label="Réglages">
              <IonIcon slot="icon-only" icon={settingsOutline} />
            </IonButton>
          </IonButtons>
        </IonToolbar>
        {showInput && game.isLimited && (
          <IonProgressBar value={Math.min(game.currentRound / game.round, 1)} />
        )}
        {connecting && <IonProgressBar type="indeterminate" />}
      </IonHeader>

      <IonContent className="game-content">
        <div className="GameContainer">
          {connecting && (
            <div className="notice card">
              Connexion au salon… Le serveur peut mettre jusqu'à une minute à se réveiller.
            </div>
          )}
          {disconnected && (
            <div className="notice card notice-error">
              Connexion perdue avec le serveur.
              <IonButton size="small" fill="clear" onClick={leave}>Revenir au menu</IonButton>
            </div>
          )}

          {showInput && (
            <>
              <div className="round-info">
                {game.isLimited && <span>Manche {Math.min(game.currentRound + 1, game.round)} / {game.round}</span>}
                {game.showScore && <span>Score {me.score}</span>}
                {me.showLives && (
                  <span className="lives" aria-label={`${me.lives} vies`}>
                    {me.lives <= 5
                      ? Array.from({ length: Math.max(me.lives, 0) }, (_, i) => <IonIcon key={i} icon={heart} />)
                      : <><IonIcon icon={heart} /> {me.lives}</>}
                  </span>
                )}
              </div>

              <AudioPanel audio={audio} />

              {players.map((player, index) => (
                <InputGame
                  key={player.id ?? index}
                  isPlayer={index === 0}
                  chapters={chapters}
                  minSurah={game.minSurah}
                  maxSurah={game.maxSurah}
                  askVerse={game.askVerse}
                  filterVerse={game.filterVerse}
                  maxVerse={game.maxVerse}
                  minVerse={game.minVerse}
                  allReady={game.allPReady}
                  correctChapter={game.previousChapter}
                  correctVerse={game.previousVerse}
                  sendGameMessage={sendGameMessage}
                  checkGuessAllPlayers={checkGuessAllPlayers}
                  player={player}
                />
              ))}

              {online && <PlayerList players={players} showScore={game.showScore} inGame />}

              {isHost && !game.isLimited && (
                <IonButton fill="clear" color="danger" className="end-button"
                  onClick={() => sendGameMessage({ content: 'The game is finished', action: 'ENDGAME', type: 'GAME' })}>
                  <IonIcon slot="start" icon={stopCircleOutline} />
                  Terminer la partie
                </IonButton>
              )}
            </>
          )}

          {!showInput && !showEnd && (
            <div className="lobby">
              <div className="card intro">
                <h2>{MODE_LABELS[mode] ?? mode}</h2>
                <p>{MODE_INTRO[mode]}</p>
                <p className="range">
                  Sourates {game.minSurah} à {game.maxSurah}
                  {game.askVerse ? ' · verset demandé' : ''}
                  {game.numberOfAyat > 1 ? ` · ${game.numberOfAyat} ayat` : ''}
                </p>
              </div>
              {online && (
                <>
                  <h3 className="section-title">Joueurs ({players.length})</h3>
                  <PlayerList players={players} showScore={game.showScore} inGame={false} />
                </>
              )}
              {isHost ? (
                <IonButton expand="block" size="large" className="start-button" disabled={connecting || disconnected} onClick={handleStartClick}>
                  <IonIcon slot="start" icon={play} />
                  Commencer
                </IonButton>
              ) : (
                <p className="waiting-host">En attente du lancement par l'hôte…</p>
              )}
              <IonButton expand="block" fill="outline" onClick={() => setShowSettings(true)}>
                <IonIcon slot="start" icon={settingsOutline} />
                Réglages
              </IonButton>
            </div>
          )}

          {showEnd && (
            <EndScreen players={players} canRestart={isHost} onRestart={handleStartClick} onLeave={handleLeave} />
          )}
        </div>
      </IonContent>

      {online && (
        <Chat
          messages={messages}
          name={name}
          message={message}
          showChat={showChat}
          handleSubmit={handleSubmit}
          setMessage={setMessage}
          setShowChat={setShowChat}
          isHost={(playerName: string) => players.find((player) => player.playerName === playerName)?.isHost ?? false}
        />
      )}

      <Settings
        isOpen={showSettings}
        onClose={() => setShowSettings(false)}
        readOnlyNotice={online && !isHost ? "Seul l'hôte peut modifier les règles de la partie." : undefined}
        settingsParameters={getSettingsGameMode(mode, players, showInput, game, sendGameMessage, chapters, audio)}
      />
    </>
  );
};

export default GameContainer;
