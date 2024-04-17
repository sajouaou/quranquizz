import React, { useState, useEffect, useRef } from 'react';
import Game from '../components/Game';
import './ExploreContainer.css';
import Settings from './user/Settings';
import InputGame from './user/InputGame'; // Import the InputGame component
import AudioSection from './user/AudioSection'; // Import the InputGame component


import queryString from "query-string";
import io from "socket.io-client";
import "./client/GameClient.css"
import { IonButton } from "@ionic/react";

import { 
  checkChoice, 
  getRandomChapterNumber, 
  getRandomVerseNumber, 
  recvGameSettingMSG, 
  setActiveLive, 
  setAllPReady, 
  setConfirmedChapter, 
  setConfirmedVerse, 
  setCurrentRound, 
  setLives, 
  setMaximumVerse, 
  setPreviousChapter, 
  setPreviousVerse, 
  setShowScore } from './game/Game';
import { faillure, makeGuess, next, setGameState, setGuessChapter, setGuessVerse, success } from './Player';

interface ContainerProps 
{
  mode: string;
  chapters: Chapter[];
  location:any;
}


interface Chapter {
  id: number;
  name_simple: string;
  verses_count: number;
}

interface Game {
  confirmedChapter: number | null;
  confirmedVerse: number;
  previousChapter: number| null;
  previousVerse: number;
  askVerse: boolean;
  filterVerse: boolean;
  verseDistribution: boolean;
  numberOfAyat: number;
  minSurah: number;
  maxSurah: number;
  minVerse: number;
  maxVerse: number;
  maximumVerse: number;
  isLimited: boolean;
  isSkip: boolean;
  round: number;
  currentRound: number;
  activeLive: boolean;
  lives: number;
  showScore: boolean;
  allPReady: boolean;
}

interface Player {
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

let socket = null;


const ExploreContainer: React.FC<ContainerProps> = ({ mode, chapters ,location}) => {
  
  const [name, setName] = useState("");
  const [room, setRoom] = useState("");

  const [readCursor, setReadCursor] = useState(0);
  const [messages, setMessages] = useState([]);
  const [lastMessage, setLastMessages] = useState(null);
  const [message, setMessage] = useState("");
  const chatContainerRef = useRef(null);

  
  useEffect(() => {
    // Scroll to the bottom of the chat container whenever messages change
    if(lastMessage !== null){
        let i = readCursor;
        if( i < messages.length){
          parseMessage(messages[i].text);
          i++;
          setReadCursor(i);
        }
    }

  }, [lastMessage]);

  
  useEffect(() => {
    let i = readCursor;
    if( i < messages.length){
      parseMessage(messages[i].text);
      i++;
      setReadCursor(i);
    }
  }, [readCursor]);

  
  const [players,setPlayers] = useState([{
    playerName: "ME",
    guessChapter: 1,
    isHost: mode !== "Online",
    guessVerse: 0,
    streak: 0,
    ready: false,
    gameState: "not ready",
    found: false,
    correctChapter: -1,
    correctVerse: -1,
    showScore: false,
    score: 0,
    showLives: false,
    lives: 1
  }]);

  



  const ENDPOINT = "http://localhost:5000";
  
  useEffect(() => {
    // Scroll to the bottom of the chat container whenever messages change
    if(chatContainerRef.current !== null){
      chatContainerRef.current.scrollTop = chatContainerRef.current.scrollHeight;
    }
  }, [messages]);


  const  parseMessage = (message) => {
    //console.log("PARSE MESSAGE - " ,message);
    if (message.type === "CHAT") {
      //setMessages((messages) => [...messages, message]);
    }
    else if (message.type === "WELCOME") {
      if (message.users.length < 1) {
        const updatedPlayer = { ...players[0] };
        updatedPlayer.isHost = true;
        const updatedPlayers = [...players];
        updatedPlayers[0] = updatedPlayer;
        setPlayers(updatedPlayers);
      }
      else {
        message.users.forEach((x) => {
          console.log(x);
          setPlayers(prevPlayers => [...prevPlayers, { ...x.player }]);
        });
      }
    }
    else {
      switch (message.type) {
        case "GAMESETTING":
          recvGameSettingMessage(message);
          break;
        case "PLAYER":
          recvPlayerMessage(message);
          break;
        case "GAME":
          recvGameMessage(message);
          break;
        case "AUDIO":
          recvAudioMessage(message);
          break;
        default:
          break;
      }
    }
  }



  useEffect(() => {
    if(mode === "Online" && socket === null){
        console.log("Test test JOIN");
        const { name, room } = queryString.parse(location.search);
        socket = io(ENDPOINT);
        setRoom(room);
        setName(name);
        const updatedPlayers = [...players]; // Créer une copie du tableau players
        updatedPlayers[0].playerName = name; // Modifier la copie du tableau
        setPlayers(updatedPlayers); // Mettre à jour l'état avec la 
    
        socket.emit("join", { name, room, player:updatedPlayers[0] }, (error) => {
          if (error) {
            alert(error);
          }
        });

        socket.on("message", (message) => {
            setMessages((messages) => [...messages, message]);
            setLastMessages(message.text);
        });
    }
  }, [location.search]);

  const handleSubmit = (e) => {
    e.preventDefault();
    if (message) {
      socket.emit("sendMessage", { message :{ content :message, type:"CHAT"}});
      setMessage("");
    } else alert("empty input");
  };
  const sendScan = (e) => {
    e.preventDefault();
    setPlayers(prevPlayers => [...prevPlayers, { playerName: "Nouveau Joueur",
      guessChapter: 1,
      guessVerse: 0,
      isHost:false,
      streak: 0,
      ready: false,
      gameState: "not ready",
      found: false,
      correctChapter: -1,
      correctVerse: -1,
      showScore: false,
      score: 0,
      showLives: false,
      lives: 1
    } ]);
    socket.emit("sendMessage", { message :{ content :"SCAN", type:"GAME"}});
  };
  const [game,setGame] = useState<Game>({
    confirmedChapter: null,
    confirmedVerse: 0,
    previousChapter: null,
    previousVerse: 0,
    askVerse: false,
    filterVerse: false,
    verseDistribution: false,
    numberOfAyat: 1,
    minSurah: 1,
    maxSurah: 114,
    minVerse: 0,
    maxVerse: 286,
    maximumVerse: 286,
    isLimited: false,
    isSkip: false,
    round: 1,
    currentRound: 0,
    activeLive: false,
    lives: 1,
    showScore: false,
    allPReady: false,
  });
  

  const setAllLive = (nbLives) => {
    setLives(setGame,nbLives);

    const updatedPlayers = players.map(player => ({
      ...player,
      lives:nbLives
    }));
    // Mettre à jour l'état des joueurs avec la nouvelle liste mise à jour
    setPlayers(updatedPlayers);
  }
  const setAllActiveLive = (showA) => {
    setActiveLive(setGame,showA);

    const updatedPlayers = players.map(player => ({
      ...player,
      showLives: showA,
      lives:game.lives
    }));
    // Mettre à jour l'état des joueurs avec la nouvelle liste mise à jour
    setPlayers(updatedPlayers);
  }
  //Score
  const setAllShowScore = (showS) => {
    setShowScore(setGame,showS);

    const updatedPlayers = players.map(player => ({
      ...player,
      showScore: showS,
    }));
    // Mettre à jour l'état des joueurs avec la nouvelle liste mise à jour
    setPlayers(updatedPlayers);
  }
  
  const resetScore = () =>{    
    const updatedPlayers = players.map(player => ({
      ...player,
      score: 0,
      streak: 0
    }));
    // Mettre à jour l'état des joueurs avec la nouvelle liste mise à jour
    setPlayers(updatedPlayers);
  }
  

  const setNotReady = () => {

    const updatedPlayers = players.map(player => ({
      ...player,
      gameState: 'not ready',
    }));
    // Mettre à jour l'état des joueurs avec la nouvelle liste mise à jour
    setPlayers(updatedPlayers);
  }


  


  const checkPlayers = () => {
    let allReady = true;
    players.forEach(player => {
        if( ! (player.gameState === 'ready' ||  player.gameState === 'next' ) ) {
          allReady =  false;
        }
    });
    return allReady;
  }
  const isPlayersLost = () => {
    let allLost = true;
    players.forEach(player => {
        if( !player.showLives || player.lives > 0) {
          allLost =  false;
        }
    });
    return allLost;
  }
  const checkGuessAllPlayers = () => {
    if(players[0].isHost){
      if((!game.isLimited || game.currentRound  <= game.round) && (! isPlayersLost())){
        const allReady = checkPlayers();
        //setAllPReady(setGame,allReady);

        if(allReady){
          let fail = false;
          sendGameMessage({ content: `The correct  answer was chapter : ${game.confirmedChapter} verse : ${game.confirmedVerse}`, action: 'CORRECT', type: 'PLAYER', value:{surah:game.confirmedChapter,verse:game.confirmedVerse} });
          //correctAll(game.confirmedChapter,game.confirmedVerse);
          let endResult :any[] = [];
          players.forEach(player => {
            if(player.gameState !== 'next'){
              fail = checkGuess(player);
              if(fail){
                endResult.push({state:"win",player});
              }
              else {
                endResult.push({state:"lose",player});
              }
            }
            else{
              endResult.push({state:"next",player});
              fail = true;
              //next(players,setPlayers, player);

            }
          });
          
          console.log("Test Everything Read");
          sendGameMessage({ content: 'The round is finished', action: 'ENDROUND', type: 'GAME', value:endResult});
          sendGameMessage({ content: 'Everyone is ready the next round will start', action: 'READY', type: 'GAME', value:allReady});
          if(game.isSkip || fail){
            playNext(game.currentRound);
          }
          setTimeout(() => { handleEndofRound(); }, 1000); 
        }
        else{
          console.log("Test Everything Failed");
          sendGameMessage({ content: 'Not every one is ready', action: 'READY', type: 'GAME', value:allReady});

        }
        
      }
      else {
        setTimeout(() => { handleEndofRound(); }, 1000); 
      }
    }
  }
  const checkGuess = (player:Player) => {
    const found = checkChoice(game,player.guessChapter,player.guessVerse);
    return found;
  }

  const newSurah = (curRound: number) => {
    if( (!game.isLimited || curRound + 1 < game.round) &&  (! isPlayersLost()) ){
      const randomChap = getRandomChapterNumber(game,chapters);
      const {verse,maxtemp } = getRandomVerseNumber(game,chapters,randomChap);
      sendGameMessage({ content: 'New surah  selected', action: 'NEWSURAH', type: 'GAME', value:{randomChap,verse,maxtemp} });
      sendGameMessage({ content: 'Downloading the audio', action: 'AUDIOFETCH', type: 'AUDIO', value:{surah:randomChap,verse:verse} });
    }
    if(game.isLimited){
      sendGameMessage({ content: `The round ${curRound+1} will start now`, action: 'SETROUND', type: 'GAME', value:curRound+1 });
    }
  }

  const playNext = (curRound: number) => { 
    const rand = newSurah(curRound); // Attendre le chargement du fichier audio  
  }



  const [showInput, setShowInput] = useState(false);
  const [showEnd, setShowEnd] = useState(false);
  const [showSettings, setShowSettings] = useState(false);

  const audioSection = new AudioSection({ numberOfAyat: game.numberOfAyat, maximumVerse: game.maximumVerse,confirmedVerse: game.confirmedVerse, showInput});
  

  /*
  new LocalPlayer({
    name:playerHostName,
    replayAudio:audioSection.replayAudio,
    chapters:chapters,
    minSurah:minSurah,
    maxSurah:maxSurah,
    askVerse:askVerse,
    maxVerse:maxVerse,
    minVerse:minVerse,
    allReady:allPReady,
    checkGuessPlayer:checkGuessAllPlayers
  })
  */

  const handleEndofRound = () => {
    if((game.isLimited && game.currentRound >= game.round) || (isPlayersLost())){
      setCurrentRound(setGame,0);
      setNotReady();
      resetScore();
      setAllLive(game.lives);
      setShowEnd(true);
      setShowInput(false);
    }
  }


  const handleStartClick = async () => {
    sendGameMessage({ content: 'The game is starting', action: 'START', type: 'GAME'});
    playNext(0);
  };  

  const handleSaveSettings = () => {
    // Enregistrez les paramètres
    setShowSettings(false);
  };

  const recvGameSettingMessage = (message) => {
    const { action, value } =  message;
    recvGameSettingMSG(message,setGame);
    switch (action) {
      case "setShowScore":
        setAllShowScore(value);
        break;
      case "setActiveLive":
        setAllActiveLive(value);
        break;
      case "setLives":
        setAllLive(value);
        break;
      case "resetScore":
        resetScore();
        break;
      default:
        break;
    }
  }

  const handleEndRound = (value) => {
    const updatedPlayers = [...players];
    value.forEach(element => {
      const {state, player} = element;
      const playerIndex = players.findIndex(otherPlayer => otherPlayer.playerName === player.playerName);
      console.log(playerIndex, " - ", player.playerName);
      if (playerIndex !== -1) {
        const updatedPlayer = { ...players[playerIndex] };
        switch(state){
          case "win":
            updatedPlayer.ready = false ;
            updatedPlayer.gameState = 'win';
            updatedPlayer.score = updatedPlayer.score +1;
            updatedPlayer.streak = updatedPlayer.streak+1;
            break;
          case "lose":
            updatedPlayer.ready = false ;
            updatedPlayer.gameState = 'lose';
            updatedPlayer.streak = 0;
            updatedPlayer.lives = updatedPlayer.lives -1;
            break;
          case "next":
            updatedPlayer.ready = false ;
            updatedPlayer.gameState = 'next';
            updatedPlayer.streak = 0;
            updatedPlayer.lives = updatedPlayer.lives -1;
            break;
          default:
            break;
        }
        updatedPlayers[playerIndex] = updatedPlayer;
      }
    });
    console.log("VALUE ", value);
    console.log(updatedPlayers);
    setPlayers(updatedPlayers);
  }
  const recvGameMessage = (message) => {
    const { action, value } =  message;
    switch (action) {
      case "checkGuessPlayer":
        checkGuessAllPlayers();
        break;
        
      case "NEWSURAH":
        const {randomChap,verse,maxtemp} = value;
        setMaximumVerse(setGame,maxtemp);
        setConfirmedChapter(setGame,randomChap);
        setConfirmedVerse(setGame,verse);
        break;
      case "SETROUND":
        setCurrentRound(setGame,value);
        break;
      case "READY":
        setAllPReady(setGame,value);
        break;
      case "ENDROUND":
        handleEndRound(value);
        break;
      case "START":
        setShowInput(true);
        setShowEnd(false);
        break;
      default:
        break;
    }
  }
  
const correctAll = (surah,verse) => {  
  // Utiliser map pour créer une nouvelle liste de joueurs avec les mises à jour appliquées à chaque joueur
  setPreviousChapter(setGame,surah);
  setPreviousVerse(setGame,verse);

}

  const recvPlayerMessage = (message) => {
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
      case "CORRECT":
        correctAll(value.surah,value.verse);
      default:
        break;
    }
  }
  
  const recvAudioMessage = async (message) => {
    const { action, value } =  message;
    switch (action) {
      case "AUDIOFETCH":
        const {surah,verse} = value;
        await audioSection.fetchAudioFile(surah, verse);
        break;

    default:
      break;
  }
}
  const sendGameMessage = async (message) => {
    if(mode === "Online"){
      socket.emit("sendMessage", { message});
    }
    else {
      console.log("SEND - ",message);
      setMessages((messages) => [...messages, {user:"LOCAL", text:message}]);
      setLastMessages(message);
      //parseMessage(message);
    }
  }


  useEffect(() => {
    if (audioSection ) {
      audioSection.playAudio();
    }
  }, [audioSection]);


  return (
    <div>
    {mode === "Online" && (
        <div>
          <div className="chat-container" ref={chatContainerRef}>
            <div className="chat-messages">
          {messages.map((val, i) => {
            return (
            <div className={"message " + (val.user === name ? 'user-message' : 'other-message')} key={i}>
                <div className="message-user">{val.user} :  </div>
                <div className="message-text"> {val.text.content}</div>
            </div>
            );
          })}
          </div>
          </div>
          <form action="" onSubmit={handleSubmit}>
            <input
              type="text"
              value={message}
              onChange={(e) => setMessage(e.target.value)}
            />
            <input type="submit" />
          </form>
          <IonButton onClick={sendScan} >SCAN</IonButton>
        </div>
      )}

      
      {showInput && (
        <div>
        {game.isLimited && (
          <>
          <label> {game.currentRound}/{game.round} </label> 
          <br></br>
          </>
        )}
        <label>Which chapter does the recited ayah correspond to ? </label>

        <div className='player-container'>
        {
          players.map((player, index) => (
            <div className='control-container' key={index}>
              <InputGame
              replayAudio={audioSection.replayAudio}
              isPlayer={index === 0}
              chapters={chapters}
              minSurah={game.minSurah}
              maxSurah={game.maxSurah}
              askVerse={game.askVerse}
              maxVerse={game.maxVerse}
              minVerse={game.minVerse}
              allReady={game.allPReady}
              correctChapter={game.previousChapter}
              correctVerse={game.previousVerse}
              sendGameMessage={sendGameMessage}
              player={player}
              />
            
              <div className='player'>
              <p>Player : {player.playerName}</p>
              <p>{player.gameState}</p>
              { player.showScore && (
                  <>
                <p>Score: {player.score}</p>
                <p>Streak: {player.streak}</p>
                </>
              )
              }
              { player.showLives && (
                  <>
                <p>Lives: {player.lives}</p>
                </>
              )
              }
              </div>
            </div>
          ))
        }
        </div>


        {audioSection && (audioSection.render())}
        </div>
      
      )}

      {!showInput && (
        <button className="menu-button start"  onClick={handleStartClick}>Start {mode}</button>
      )}
      <button className="menu-button settings"  onClick={() => setShowSettings(!showSettings)}>Settings</button>
      
      {showSettings && (
          <Settings
          numberOfAyat={game.numberOfAyat}
          minSurah={game.minSurah}
          maxSurah={game.maxSurah}
          minVerse={game.minVerse}
          maxVerse={game.maxVerse}
          chapters={chapters}
          filterVerse={game.filterVerse}
          askVerse={game.askVerse}
          verseDistribustion={game.verseDistribution}
          volume={audioSection.volume}
          setNumberOfAyat={(value: number) => sendGameMessage({ content: `The number of ayat is set to ${value}`, action: 'setNumberOfAyat', type: 'GAMESETTING', value: value })}
          setMinSurah={(value: number) => sendGameMessage({ content: `The minimum surah is set to ${value}`, action: 'setMinSurah', type: 'GAMESETTING', value: value })}
          setMaxSurah={(value: number) => sendGameMessage({ content: `The maximum surah is set to ${value}`, action: 'setMaxSurah', type: 'GAMESETTING', value: value })}
          setMinVerse={(value: number) => sendGameMessage({ content: `The minimum verse is set to ${value+1}`, action: 'setMinVerse', type: 'GAMESETTING', value: value })}
          setMaxVerse={(value: number) => sendGameMessage({ content: `The maximum verse is set to ${value+1}`, action: 'setMaxVerse', type: 'GAMESETTING', value: value })}
          setVerseDistribustion={(value: boolean) => sendGameMessage({ content: 'The verse ditribution is ' + (value ? 'enabled' : 'disabled'), action: 'setVerseDistribution', type: 'GAMESETTING', value: value })}
          setVolume={audioSection.setVolumeAudio}
          handleSaveSettings={handleSaveSettings}
          setFilterVerse={(value: boolean) => sendGameMessage({ content: 'The verse filter is ' + (value ? 'enabled' : 'disabled'), action: 'setFilterVerse', type: 'GAMESETTING', value: value })}
          setAskVerse={(value: boolean) => sendGameMessage({ content: 'Asking verse for the answer is '+ (value ? 'enabled' : 'disabled'), action: 'setAskVerse', type: 'GAMESETTING', value: value })}
          resetscore={ () => sendGameMessage({ content: 'Scores are reset', action: 'resetScore', type: 'GAMESETTING'}) }
          showScore={game.showScore}
          setShowScore={(value: boolean) => sendGameMessage({ content: (value ? 'Scores are visible' : 'Scores are not visible'), action: 'setShowScore', type: 'GAMESETTING', value: value })}
          isLimited={game.isLimited}
          setLimit={(value: boolean) => sendGameMessage({ content: (value ? 'The game is limited in rounds' : 'The game is endless'), action: 'setIsLimited', type: 'GAMESETTING', value: value })}
          round={game.round}
          setRound={(value: number) => sendGameMessage({ content: `The number of rounds is set to  ${value}`, action: 'setRound', type: 'GAMESETTING', value: value })}
          isSkip={game.isSkip}
          setSkip={(value: boolean) => sendGameMessage({ content: 'Automatic skip if everyone has a wrong answer is ' + (value ? 'enabled' : 'disabled'), action: 'setIsSkip', type: 'GAMESETTING', value: value })}
          activeLive={game.activeLive}
          setActiveLive={(value: boolean) => sendGameMessage({ content: 'The survival mode is ' + (value ? 'enabled' : 'disabled'), action: 'setActiveLive', type: 'GAMESETTING', value: value })}
          lives={game.lives}
          setLives={(value: boolean) => sendGameMessage({ content: `The number of lives is set to ${value}`, action: 'setLives', type: 'GAMESETTING', value: value })}
        />
      )}

      


    </div>
  );
};

export default ExploreContainer;
