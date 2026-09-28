import React, { useState, useEffect, useCallback, useRef } from 'react';
import { useIonToast, IonBadge, IonButton, IonButtons, IonContent, IonHeader, IonIcon, IonProgressBar, IonTitle, IonToolbar } from '@ionic/react';
import { arrowBack, chatbubbles, heart, qrCode, shareSocial, play, settingsOutline, stopCircleOutline } from 'ionicons/icons';
import Settings from './user/Settings';
import InputGame from './user/InputGame';
import AudioPanel from './user/AudioPanel';
import Chat from './client/Chat';
import EndScreen, { RoundResult } from './game/EndScreen';
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
import { PlayerProps, checkPlayers, defaultPlayer, isEliminated, isPlayersLost, recvPlayerMSG } from './game/Player';
import { getSettingsGameMode, setGameMode } from './game/GameMode';
import { useAudioPlayer } from '../hooks/useAudioPlayer';
import { getPrefs } from '../lib/prefs';
import { recordScore } from '../lib/stats';
import { shareRoom } from '../lib/feedback';
import { LinkStatus, RoomLink, WebSocketLink } from '../lib/net/link';
import HostPairing from './p2p/HostPairing';
import './GameContainer.css';

export const MODE_LABELS: Record<string, string> = {
  Training: 'Entraînement',
  Arcade: 'Arcade',
  Survie: 'Survie',
  Online: 'En ligne',
  Local: 'Partie locale',
};

export const isNetworked = (mode: string) => mode === 'Online' || mode === 'Local';

const MODE_INTRO: Record<string, string> = {
  Training: 'Écoute une récitation et retrouve la sourate. Personnalise la plage de sourates dans les réglages.',
  Arcade: '10 manches, un point par bonne réponse. Vise le score parfait !',
  Survie: 'Tu as 3 vies. Chaque erreur en coûte une : tiens le plus longtemps possible.',
  Online: "Partage le nom du salon à tes amis. L'hôte règle la partie puis la lance.",
  Local: "Sans serveur : chaque joueur se connecte à l'hôte en scannant un code. Idéal sur le même Wi-Fi ou via le partage de connexion d'un téléphone.",
};

// Either a WebSocket room on the server, or an already connected peer-to-peer link.
export type Connection =
  | { type: 'server'; endpoint: string; room: string }
  | { type: 'p2p'; link: RoomLink; label: string };

interface ContainerProps {
  mode: string;
  chapters: Chapter[];
  name: string;
  connection?: Connection;
  leave: () => void;
  retry?: () => void;
}

// Opens the server link for the lifetime of the screen, or uses the peer-to-peer one.
function useRoomLink(connection: Connection | undefined, name: string): RoomLink | null {
  const [link, setLink] = useState<RoomLink | null>(null);
  useEffect(() => {
    if (!connection) return;
    if (connection.type === 'p2p') {
      setLink(connection.link);
      return;
    }
    const socket = new WebSocketLink(connection.endpoint, {
      username: name,
      room: connection.room,
      player: JSON.stringify({ ...defaultPlayer, playerName: name }),
      game: JSON.stringify({ ...defaultGame }),
      proto: '2',
      clientId: getPrefs().clientId,
    });
    setLink(socket);
    return () => socket.close();
  }, [connection, name]);
  return link;
}

const GameContainer: React.FC<ContainerProps> = ({ mode, chapters, name, connection, leave, retry }) => {
  const online = isNetworked(mode);
  const room = connection?.type === 'server' ? connection.room : undefined;
  const [presentToast] = useIonToast();

  //////////////////////////////
  //  ONLINE SECTION
  //////////////////////////////
  // The server (or the peer-to-peer host) relays every message to every player of the
  // room, sender included. Messages are replayed in order through `readCursor`.
  const link = useRoomLink(connection, name);
  const [linkStatus, setLinkStatus] = useState<LinkStatus>(online ? 'connecting' : 'open');
  const [closeReason, setCloseReason] = useState<string | null>(null);
  const [pairingOpen, setPairingOpen] = useState(false);

  useEffect(() => {
    if (!link) return;
    const offMessages = link.subscribe((received, reset) => {
      setMessages((prev) => (reset ? received : [...prev, ...received]));
    });
    const offStatus = link.onStatus((status) => {
      setLinkStatus(status);
      setCloseReason(link.closeReason);
    });
    return () => { offMessages(); offStatus(); };
  }, [link]);

  const sendMessage = useCallback((msg: any) => link?.send(msg), [link]);

  const handleSubmit = (e: { preventDefault: () => void; }) => {
    e.preventDefault();
    if (message.trim() && online) {
      sendMessage({ message: { content: message.trim().slice(0, 500), type: "CHAT" } });
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

  // Delayed host actions (next surah, end of game): cancelled when the game stops or the screen closes.
  const timersRef = useRef<number[]>([]);
  const later = (fn: () => void, ms: number) => {
    timersRef.current.push(window.setTimeout(fn, ms));
  };
  const clearTimers = () => {
    timersRef.current.forEach((t) => clearTimeout(t));
    timersRef.current = [];
  };
  useEffect(() => clearTimers, []);

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
        clearTimers();
        audio.stop();
        if (!online && (mode === 'Arcade' || mode === 'Survie')) setRecord(recordScore(mode, players[0].score));
        setShowEnd(true);
        setShowInput(false);
        break;
      case "ENDROUND":
        handleEndRound(value);
        break;
      case "NEWSURAH": {
        const { randomChap, verse, maxtemp } = value;
        setRevealed(false);
        audio.load(randomChap, verse, Math.max(1, Math.min(game.numberOfAyat, maxtemp - verse)));
        break;
      }
      case "START":
        clearTimers();
        setHistory([]);
        setRevealed(false);
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

  const recvWelcomeMessage = (message: { game: GameProps, players: any[]; inProgress?: boolean; current?: any }) => {
    const { game: roomGame, players: pls, inProgress, current } = message;
    const merged = { ...defaultGame, ...roomGame };
    setGame(merged);
    setPlayers([...pls.filter((player) => player.playerName === players[0].playerName), ...pls.filter((player) => player.playerName !== players[0].playerName)]);
    // Joining a game that is already running: jump straight into the current round.
    if (inProgress) {
      setShowInput(true);
      setShowEnd(false);
      if (current) {
        recvGameMSG({ action: 'NEWSURAH', value: current }, setGame, setPlayers, players, merged);
        audio.load(current.randomChap, current.verse, Math.max(1, Math.min(merged.numberOfAyat, current.maxtemp - current.verse)));
      }
    }
  };

  const parseMessage = (message: any) => {
    switch (message.type) {
      case "GAMESETTING":
        recvGameSettingMSG(message, setGame, setPlayers, players, game);
        break;
      case "PLAYER":
        if (message.action === "NEW") {
          // Every client applies the room rules (lives, scores) to the newcomer the same way.
          const newcomer: PlayerProps = {
            ...defaultPlayer,
            ...message.value,
            showScore: game.showScore,
            showLives: game.activeLive,
            lives: game.activeLive ? game.lives : defaultPlayer.lives,
          };
          if (players.some((p) => p.id === newcomer.id)) break;
          setPlayers((prev) => [...prev, newcomer]);
          // The host shares the current settings and scores with whoever joins.
          if (online && players[0].isHost) {
            sendGameMessage({ content: 'Game settings synced', action: 'update', type: 'GAMESETTING', value: game });
            sendGameMessage({ content: 'Players synced', action: 'sync', type: 'PLAYER', value: [...players, newcomer] });
          }
          break;
        }
        recvPlayerMSG(message, players, setPlayers);
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
      if (isEliminated(player)) {
        endResult.push({ state: "out", player });
      } else if (player.gameState !== 'next') {
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
      lives: state === 'lose' || state === 'next' ? player.lives - 1 : player.lives,
    }));
    const moveOn = game.isSkip || !everyoneFail;
    const nextRound = moveOn ? game.currentRound + 1 : game.currentRound;
    if (moveOn) {
      sendGameMessage({ content: `Round ${nextRound + 1}`, action: 'SETROUND', type: 'GAME', value: nextRound });
    }
    const finished = (game.isLimited && nextRound >= game.round) || isPlayersLost(livesAfter);
    if (finished) {
      later(() => sendGameMessage({ content: 'The game is finished', action: 'ENDGAME', type: 'GAME' }), 1500);
    } else if (moveOn) {
      later(() => newSurah(nextRound, true), 1200);
    }
  };

  const handleEndRound = (value: any[]) => {
    // The answer is only shown when the game moves on: if everybody was wrong and
    // skipping is off, the same recitation is asked again.
    const moveOn = game.isSkip || value.some(({ state }) => state === 'win' || state === 'next');
    setRevealed(moveOn);
    if (moveOn && game.confirmedChapter !== null) {
      const me = value.find(({ player }) => player.playerName === players[0].playerName);
      setHistory((h) => [...h, { surah: game.confirmedChapter as number, verse: game.confirmedVerse, result: me?.state ?? 'out' }]);
    }
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
  // When someone leaves (or the host changes), the remaining players may all have
  // answered already: the host has to check again, nobody else will trigger it.
  const playerIds = players.map((p) => p.id).join('|');
  useEffect(() => {
    if (players[0].isHost && showInput) checkGuessAllPlayers();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [playerIds, players[0].isHost]);

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
  const [revealed, setRevealed] = useState(false);
  const [history, setHistory] = useState<RoundResult[]>([]);
  const [record, setRecord] = useState<{ best: number; isRecord: boolean } | null>(null);

  const isHost = players[0].isHost;
  const chatCount = messages.filter((m) => m.text?.type === 'CHAT' && m.user !== name).length;
  const unread = showChat ? 0 : chatCount - seenChat;
  useEffect(() => {
    if (showChat) setSeenChat(chatCount);
  }, [showChat, chatCount]);

  const connecting = online && linkStatus === 'connecting';
  const disconnected = online && !closeReason && linkStatus === 'closed';
  const p2p = connection?.type === 'p2p';
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
            {room ? <span className="room-name"> · {room}</span> : null}
            {connection?.type === 'p2p' && connection.label ? <span className="room-name"> · {connection.label}</span> : null}
          </IonTitle>
          <IonButtons slot="end">
            {p2p && link?.kind === 'host' && showInput && (
              <IonButton onClick={() => setPairingOpen(true)} aria-label="Ajouter un joueur">
                <IonIcon slot="icon-only" icon={qrCode} />
              </IonButton>
            )}
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
          {closeReason && (
            <div className="notice card notice-error">
              {closeReason}
              <IonButton size="small" fill="clear" onClick={leave}>Revenir au menu</IonButton>
            </div>
          )}
          {disconnected && (
            <div className="notice card notice-error">
              {p2p ? "La connexion avec l'hôte a été perdue." : 'Connexion perdue avec le serveur.'}
              <div>
                {retry && <IonButton size="small" onClick={retry}>Se reconnecter</IonButton>}
                <IonButton size="small" fill="clear" onClick={leave}>Revenir au menu</IonButton>
              </div>
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
                  revealed={revealed}
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
                  onClick={() => { clearTimers(); sendGameMessage({ content: 'The game is finished', action: 'ENDGAME', type: 'GAME' }); }}>
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
              {p2p && link?.kind === 'host' && (
                <IonButton expand="block" color="secondary" onClick={() => setPairingOpen(true)}>
                  <IonIcon slot="start" icon={qrCode} />
                  Ajouter un joueur
                </IonButton>
              )}
              {online && room && (
                <IonButton expand="block" fill="outline" color="secondary"
                  onClick={async () => {
                    const result = await shareRoom(room);
                    if (result === 'copied') presentToast({ message: "Lien d'invitation copié", duration: 1800 });
                    if (result === 'failed') presentToast({ message: `Nom du salon : ${room}`, duration: 2500 });
                  }}>
                  <IonIcon slot="start" icon={shareSocial} />
                  Inviter des amis
                </IonButton>
              )}
              {online && (
                <>
                  <h3 className="section-title">Joueurs ({players.length})</h3>
                  <PlayerList players={players} showScore={game.showScore} inGame={false} />
                </>
              )}
              {isHost ? (
                <IonButton expand="block" size="large" className="start-button" disabled={connecting || disconnected || !!closeReason} onClick={handleStartClick}>
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
            <EndScreen players={players} mode={mode} history={history} chapters={chapters} record={record}
              canRestart={isHost} onRestart={handleStartClick} onLeave={handleLeave} />
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

      {p2p && link?.kind === 'host' && (
        <HostPairing isOpen={pairingOpen} onClose={() => setPairingOpen(false)} link={link} hostName={name} />
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
