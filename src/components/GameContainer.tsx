import React, { useState, useEffect } from 'react';
import Settings from './user/Settings';
import InputGame from './user/InputGame'; // Import the InputGame component
import AudioSection from './user/AudioSection'; // Import the InputGame component



import { 
  Chapter,
  GameProps,
  checkChoice, 
  defaultGame, 
  getRandomChapterNumber, 
  getRandomVerseNumber, 
  recvGameMSG, 
  recvGameSettingMSG } from './game/Game';
import { PlayerProps, checkPlayers, defaultPlayer, isPlayersLost, recvPlayerMSG } from './Player';
import Chat from './client/GameClient';

import "./GameClient.css";
import './GameContainer.css';
import EndScreen from './game/EndScreen';

interface ContainerProps 
{
  mode: string;
  chapters: Chapter[];
  location:any;
}


//import io, { Socket } from "socket.io-client";
import socketIOClient from "socket.io-client"
//import { Socket } from 'ngx-socket-io';
//import useWebSocket, { ReadyState } from 'react-use-websocket';

let socket: any | null = null;


const ExploreContainer: React.FC<ContainerProps> = ({ mode, chapters ,location}) => {
  


  //////////////////////////////
  //
  //
  //  ONLINE SECTION
  //
  //
  //////////////////////////////////
  const [name, setName] = useState("");
  const [room, setRoom] = useState("");

  useEffect(() => {
    if(socket){
      socket.disconnect();
      socket = null;
    }
    if(mode === "Online" && (socket === null )){
        const { name, room, ENDPOINT } = location.search;
        
        socket = socketIOClient(ENDPOINT, {
          // WARNING: in that case, there is no fallback to long-polling
          transports: [ "websocket", "polling" ], // or [ "websocket", "polling" ] (the order matters)
          //rejectUnauthorized: false // Désactiver la vérification du certificat
        });
        
        //socket = new Socket({ url: ENDPOINT });
        console.log("IO ENDPOINT - ",ENDPOINT);
        setRoom(room);
        setName(name);
        const updatedPlayers = [...players]; // Créer une copie du tableau players
        updatedPlayers[0].playerName = name; // Modifier la copie du tableau
        setPlayers(updatedPlayers); // Mettre à jour l'état avec la 

        socket.emit("join", { name, room, player:updatedPlayers[0] }, (error: any) => {
          if (error) {
            alert(error);
          }
        });
        socket.on("message", (message:any) => {
            setMessages((prevMessages) => [...prevMessages, message]);
            setLastMessages(message.text);
        });
        
        console.log(socket);
    }
  }, [location.search]);
  
  const handleSubmit = (e: { preventDefault: () => void; }) => {
    e.preventDefault();
    if (message && socket) {
      socket.emit("sendMessage", { message :{ content :message, type:"CHAT"}});
      setMessage("");
    } else alert("empty input");
  };
  const sendScan = (e: { preventDefault: () => void; }) => {
    e.preventDefault();
    if(socket){
      socket.emit("sendMessage", { message :{ content :"SCAN", type:"GAME"}});
    }
  };
  
  const sendGameMessage = async (message: any) => {
    if(mode === "Online" && socket){
      socket.emit("sendMessage", { message});
    }
    else if(mode !== "Online"){
      console.log("SEND - ",message);
      setMessages((messages) => [...messages, {user:"LOCAL", text:message}]);
      setLastMessages(message);
      //parseMessage(message);
    }
  }


  
  //////////////////////////////
  //
  //
  //  MESSAGE MANAGMENT
  //
  //
  //////////////////////////////////
  const [readCursor, setReadCursor] = useState(0);
  const [messages, setMessages] = useState<any[]>([]);
  const [lastMessage, setLastMessages] = useState(null);
  const [message, setMessage] = useState("");
  const [showChat, setShowChat] = useState(false);

  
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
    
  const recvGameMessage = (message: any) => {
    const { action, value } =  message;
    recvGameMSG(message,setGame,setPlayers,players,game);
    switch (action) {
      case "ENDGAME":
        setShowEnd(true);
        setShowInput(false);
        break;
      case "ENDROUND":
        handleEndRound(value);
        break;
      case "START":
        if(players[0].isHost){
          playNext(0);
        }
        setShowInput(true);
        setShowEnd(false);
        break;
      default:
        break;
    }
  }

  
  const recvAudioMessage = async (message: { action: any; value: any; }) => {
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

const recvChatMessage = (message: { users: any[]; }) => {
    ; 
}

const recvWelcomeMessage = (message: { users: any[]; }) => {
  const { users } =  message;
  setPlayers([{...players[0], isHost:users.length < 1}, ...users.map(x => ({...x.player})) ]);
}


  const  parseMessage = (message: any) => {
    switch (message.type) {
      case "GAMESETTING":
        recvGameSettingMSG(message,setGame,setPlayers,players,game);
        break;
      case "PLAYER":
        recvPlayerMSG(message,players,setPlayers);
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
      case "CHAT":
        recvChatMessage(message);
        break;
      default:
        break;
    }
  }



  
  //////////////////////////////
  //
  //
  //  GAME MANAGMENT
  //
  //
  //////////////////////////////////
  const [game,setGame] = useState<GameProps>({...defaultGame});
  const [players,setPlayers] = useState<PlayerProps[]>([{...defaultPlayer,isHost: mode !== "Online"}]);

  
  useEffect(() => {
    switch(mode){
      case "Arcade":
        setGame((prevState: any) => ({ ...prevState, 
          round: 10,
          showScore: true,
          isLimited:true,
          isSkip: true 
        }));
        break;
      default:
        break;
    }
  }, [mode]);


  const checkGuessAllPlayers = () => {
    if(players[0].isHost){
      if((!game.isLimited || game.currentRound  <= game.round) && (! isPlayersLost(players))){
        const allReady = checkPlayers(players);

        if(allReady){
          let fail = false;
          let everyoneFail = true;
          sendGameMessage({ content: `The correct  answer was chapter : ${game.confirmedChapter} verse : ${game.confirmedVerse}`, action: 'CORRECT', type: 'GAME', value:{surah:game.confirmedChapter,verse:game.confirmedVerse} });
          let endResult :any[] = [];
          players.forEach(player => {
            if(player.gameState !== 'next'){
              fail = checkChoice(game,player.guessChapter,player.guessVerse);
              if(fail){
                everyoneFail=false;
                endResult.push({state:"win",player});
              }
              else {
                endResult.push({state:"lose",player});
              }
            }
            else{
              everyoneFail=false;
              endResult.push({state:"next",player});
              fail = true;
            }
          });
          
          console.log("Test Everything Read");
          sendGameMessage({ content: 'The round is finished', action: 'ENDROUND', type: 'GAME', value:endResult});
          sendGameMessage({ content: 'The next round will start', action: 'READY', type: 'GAME', value:allReady});
          if(game.isSkip || ! everyoneFail){
            playNext(game.currentRound);
          }
          setTimeout(() => { handleEndGame();    }, 1000); 
        }
        else{
          console.log("Test Everything Failed");
          sendGameMessage({ content: 'Not every one is ready', action: 'READY', type: 'GAME', value:allReady});

        }
        
      }
      else {
        setTimeout(() => { handleEndGame();  }, 1000); 
      }
    }
  }
  
  const handleEndRound = (value: any[]) => {
    const updatedPlayers = [...players];
    value.forEach((element: { state: any; player: any; }) => {
      const {state, player} = element;
      const playerIndex = players.findIndex(otherPlayer => otherPlayer.playerName === player.playerName);
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
    setPlayers(updatedPlayers);
  }


  const newSurah = (curRound: number) => {
    if( (!game.isLimited || curRound  < game.round) &&  (! isPlayersLost(players)) ){
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

  //////////////////////////////
  //
  //
  //  START/END CONTROL 
  //
  //
  //////////////////////////////////

  const handleStartClick = async () => {
    sendGameMessage({ content: 'The game is starting', action: 'START', type: 'GAME'});
  };  

  const handleEndGame = () => {
    if((game.isLimited && game.currentRound > game.round) || (isPlayersLost(players))){
      sendGameMessage({ content: 'The game is finished', action: 'ENDGAME', type: 'GAME'});
    }
  }

  
  //////////////////////////////
  //
  //
  //  USER INTERFACE
  //
  //
  //////////////////////////////////

  const [showInput, setShowInput] = useState(false);
  const [showEnd, setShowEnd] = useState(false);
  const [showSettings, setShowSettings] = useState(false);
  

  const handleSaveSettings = () => {
    // Enregistrez les paramètres
    setShowSettings(false);
  };

  const audioSection = new AudioSection({ numberOfAyat: game.numberOfAyat, maximumVerse: game.maximumVerse,confirmedVerse: game.confirmedVerse, showInput});
  
  useEffect(() => {
    if (audioSection ) {
      audioSection.playAudio();
    }
  }, [audioSection.audioFile]);
  
  return (
    <div>
    {mode === "Online" && showChat && (
          <Chat messages={messages}
          name={name}
          message={message}
          showChat={showChat}
          handleSubmit={handleSubmit}
          setMessage={setMessage}
          setShowChat={setShowChat}
          sendScan={sendScan} />
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
              checkGuessAllPlayers={checkGuessAllPlayers}
              player={player}
              />
            
              <div className='player'>
              <p>Player : {player.playerName}</p>
              <p>{player.gameState}</p>
              { game.showScore && (
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

      {showEnd && <EndScreen players={players} />}

      {!showInput && (
        <button className="menu-button start"  onClick={handleStartClick}>Start {mode}</button>
      )}
      <button className="menu-button settings"  onClick={() => setShowSettings(!showSettings)}>Settings</button>
      {mode === "Online" && (
        <button className="menu-button settings"  onClick={() => setShowChat(!showChat)}>Chat</button>
      )
      }
      
      {showSettings && (
          <Settings
          settingsParameters={
            mode === "Training" ? 
            [
            {type:"SELECT",
            condition:true,
            label:"Number of Ayat :",
            value:game.numberOfAyat,
            data:[...Array(286).keys()]
                  .map((x,i) =>({ id:x,value:x+1,label:x+1  })),
            set:(event: React.ChangeEvent<HTMLSelectElement>) => sendGameMessage({ content: `The number of ayat is set to ${parseInt(event.target.value)}`, action: 'setNumberOfAyat', type: 'GAMESETTING', value: parseInt(event.target.value) })
            },
            {type:"SELECT",
            condition:true,
            label:"Minimum Surah:",
            value:game.minSurah,
            data:chapters
                .filter((chapter) => chapter.id <= game.maxSurah)
                .map((x,i) =>({ id:x.id,value:x.id,label:x.name_simple  })),
            set:(event: React.ChangeEvent<HTMLSelectElement>) =>sendGameMessage({ content: `The minimum surah is set to ${parseInt(event.target.value) }`, action: 'setMinSurah', type: 'GAMESETTING', value: parseInt(event.target.value)  })
            },
            {type:"SELECT",
            condition:game.filterVerse,
            notNext:true,
            value:game.minVerse,
            data: [...Array(chapters
                            .filter((chapter) => chapter.id === game.minSurah)[0].verses_count).keys()
                  ]
                  .filter((x) => game.minSurah !== game.maxSurah || x <= game.maxVerse)
                  .map((x,i) =>({ id:x,value:x,label:x+1  })) 
            ,
            set:(event: React.ChangeEvent<HTMLSelectElement>) =>sendGameMessage({ content: `The minimum verse is set to ${parseInt(event.target.value)+1}`, action: 'setMinVerse', type: 'GAMESETTING', value: parseInt(event.target.value) })
            },
            {type:"SELECT",
            condition:true,
            label:"Maximum Surah:",
            value:game.maxSurah,
            data:chapters
                .filter((chapter) => game.minSurah <= chapter.id)
                .map((x,i) =>({ id:x.id,value:x.id,label:x.name_simple  })),
            set:(event: React.ChangeEvent<HTMLSelectElement>) => sendGameMessage({ content: `The maximum surah is set to ${parseInt(event.target.value)}`, action: 'setMaxSurah', type: 'GAMESETTING', value: parseInt(event.target.value) })  
            },
            {type:"SELECT",
            condition:game.filterVerse,
            notNext:true,
            value:game.maxVerse,
            data: [...Array(chapters
                            .filter((chapter) => chapter.id === game.maxSurah)[0].verses_count).keys()
                  ]
                  .filter((x) => game.minSurah !== game.maxSurah || game.minVerse  <= x)
                  .map((x,i) =>({ id:x,value:x,label:x+1  })) 
            ,
            set:(event: React.ChangeEvent<HTMLSelectElement>) =>sendGameMessage({ content: `The maximum verse is set to ${parseInt(event.target.value)+1}`, action: 'setMaxVerse', type: 'GAMESETTING', value: parseInt(event.target.value) })
            },

              {type:"CHECKBOX",
              label:"Ask Verses:",
              value:game.askVerse,
              set:(value: boolean) => sendGameMessage({ content: 'Asking verse for the answer is '+ (value ? 'enabled' : 'disabled'), action: 'setAskVerse', type: 'GAMESETTING', value: value })
              },
              {type:"CHECKBOX",
              label:"Filter Verses:",
              value:game.filterVerse,
              set:(value: boolean) => sendGameMessage({ content: 'The verse filter is ' + (value ? 'enabled' : 'disabled'), action: 'setFilterVerse', type: 'GAMESETTING', value: value })
            },
              {type:"CHECKBOX",
              label:"Random Verses Distribution:",
              value:game.verseDistribution,
              set:(value: boolean) => sendGameMessage({ content: 'The verse ditribution is ' + (value ? 'enabled' : 'disabled'), action: 'setVerseDistribution', type: 'GAMESETTING', value: value })
            },
              {type:"CHECKBOX",
              label:"Limit :",
              value:game.isLimited,
              set:(value: boolean) => sendGameMessage({ content: (value ? 'The game is limited in rounds' : 'The game is endless'), action: 'setIsLimited', type: 'GAMESETTING', value: value })
            },
              {type:"SELECT",
              condition:game.isLimited,
              label:"Number of Round :",
              value:game.round,
              data:[...Array(50).keys()]
              .map((x,i) =>({ id:x,value:x+1,label:x+1  })),
              set:(event: React.ChangeEvent<HTMLSelectElement>) => sendGameMessage({ content: `The number of rounds is set to  ${parseInt(event.target.value)}`, action: 'setRound', type: 'GAMESETTING', value: parseInt(event.target.value) })
            },
            {type:"CHECKBOX",
              label:"Skip if fail :",
              value:game.isSkip,
              set:(value: boolean) => sendGameMessage({ content: 'Automatic skip if everyone has a wrong answer is ' + (value ? 'enabled' : 'disabled'), action: 'setIsSkip', type: 'GAMESETTING', value: value })
            },
              {type:"CHECKBOX",
              label:"Show Score :",
              value:game.showScore,
              set:(value: boolean) => sendGameMessage({ content: (value ? 'Scores are visible' : 'Scores are not visible'), action: 'setShowScore', type: 'GAMESETTING', value: value })
            },
              {type:"CHECKBOX",
              label:"Active Lives :",
              value:game.activeLive,
              set:(value: boolean) => sendGameMessage({ content: 'The survival mode is ' + (value ? 'enabled' : 'disabled'), action: 'setActiveLive', type: 'GAMESETTING', value: value })
            },
              {type:"SELECT",
              condition:game.activeLive,
              label:"Number of Lives :",
              value:game.lives,
              data:[...Array(50).keys()]
              .map((x,i) =>({ id:x,value:x+1,label:x+1  })),
              set:(event: React.ChangeEvent<HTMLSelectElement>) => sendGameMessage({ content: `The number of lives is set to ${parseInt(event.target.value)}`, action: 'setLives', type: 'GAMESETTING', value: parseInt(event.target.value) })
            },
            { type:"BUTTON",
              condition:game.showScore,
              label:"Reset Score",
              class:"menu-button settings",
              click:() => sendGameMessage({ content: 'Scores are reset', action: 'resetScore', type: 'PLAYER'})
            },
            { type: "SLIDER",
              label:"Volume:",
              min:"0",
              max:"1",
              step:"0.01",
              value:audioSection.volume,
              set:(event: React.ChangeEvent<HTMLInputElement>) => {audioSection.setVolumeAudio(parseFloat(event.target.value))}
            },
            { type:"BUTTON",
              condition:true,
              label:"Save",
              class:"menu-button settings",
              click:handleSaveSettings
            }
            
            ] : (mode === "Arcade" && !showInput) ?
            [
              {type:"SELECT",
              condition:true,
              label:"Number of Ayat :",
              value:game.numberOfAyat,
              data:[...Array(286).keys()]
                    .map((x,i) =>({ id:x,value:x+1,label:x+1  })),
              set:(event: React.ChangeEvent<HTMLSelectElement>) => sendGameMessage({ content: `The number of ayat is set to ${parseInt(event.target.value)}`, action: 'setNumberOfAyat', type: 'GAMESETTING', value: parseInt(event.target.value) })
              },
              {type:"SELECT",
              condition:true,
              label:"Minimum Surah:",
              value:game.minSurah,
              data:chapters
                  .filter((chapter) => chapter.id <= game.maxSurah)
                  .map((x,i) =>({ id:x.id,value:x.id,label:x.name_simple  })),
              set:(event: React.ChangeEvent<HTMLSelectElement>) =>sendGameMessage({ content: `The minimum surah is set to ${parseInt(event.target.value) }`, action: 'setMinSurah', type: 'GAMESETTING', value: parseInt(event.target.value)  })
              },
              {type:"SELECT",
              condition:game.filterVerse,
              notNext:true,
              value:game.minVerse,
              data: [...Array(chapters
                              .filter((chapter) => chapter.id === game.minSurah)[0].verses_count).keys()
                    ]
                    .filter((x) => game.minSurah !== game.maxSurah || x <= game.maxVerse)
                    .map((x,i) =>({ id:x,value:x,label:x+1  })) 
              ,
              set:(event: React.ChangeEvent<HTMLSelectElement>) =>sendGameMessage({ content: `The minimum verse is set to ${parseInt(event.target.value)+1}`, action: 'setMinVerse', type: 'GAMESETTING', value: parseInt(event.target.value) })
              },
              {type:"SELECT",
              condition:true,
              label:"Maximum Surah:",
              value:game.maxSurah,
              data:chapters
                  .filter((chapter) => game.minSurah <= chapter.id)
                  .map((x,i) =>({ id:x.id,value:x.id,label:x.name_simple  })),
              set:(event: React.ChangeEvent<HTMLSelectElement>) => sendGameMessage({ content: `The maximum surah is set to ${parseInt(event.target.value)}`, action: 'setMaxSurah', type: 'GAMESETTING', value: parseInt(event.target.value) })  
              },
              {type:"SELECT",
              condition:game.filterVerse,
              notNext:true,
              value:game.maxVerse,
              data: [...Array(chapters
                              .filter((chapter) => chapter.id === game.maxSurah)[0].verses_count).keys()
                    ]
                    .filter((x) => game.minSurah !== game.maxSurah || game.minVerse  <= x)
                    .map((x,i) =>({ id:x,value:x,label:x+1  })) 
              ,
              set:(event: React.ChangeEvent<HTMLSelectElement>) =>sendGameMessage({ content: `The maximum verse is set to ${parseInt(event.target.value)+1}`, action: 'setMaxVerse', type: 'GAMESETTING', value: parseInt(event.target.value) })
              },
  
                {type:"CHECKBOX",
                label:"Ask Verses:",
                value:game.askVerse,
                set:(value: boolean) => sendGameMessage({ content: 'Asking verse for the answer is '+ (value ? 'enabled' : 'disabled'), action: 'setAskVerse', type: 'GAMESETTING', value: value })
                },
                {type:"CHECKBOX",
                label:"Filter Verses:",
                value:game.filterVerse,
                set:(value: boolean) => sendGameMessage({ content: 'The verse filter is ' + (value ? 'enabled' : 'disabled'), action: 'setFilterVerse', type: 'GAMESETTING', value: value })
              },
                {type:"CHECKBOX",
                label:"Random Verses Distribution:",
                value:game.verseDistribution,
                set:(value: boolean) => sendGameMessage({ content: 'The verse ditribution is ' + (value ? 'enabled' : 'disabled'), action: 'setVerseDistribution', type: 'GAMESETTING', value: value })
              },
              { type: "SLIDER",
                label:"Volume:",
                min:"0",
                max:"1",
                step:"0.01",
                value:audioSection.volume,
                set:(event: React.ChangeEvent<HTMLInputElement>) => {audioSection.setVolumeAudio(parseFloat(event.target.value))}
              },
              { type:"BUTTON",
                condition:true,
                label:"Save",
                class:"menu-button settings",
                click:handleSaveSettings
              }] : [{ type: "SLIDER",
              label:"Volume:",
              min:"0",
              max:"1",
              step:"0.01",
              value:audioSection.volume,
              set:(event: React.ChangeEvent<HTMLInputElement>) => {audioSection.setVolumeAudio(parseFloat(event.target.value))}
            },
            { type:"BUTTON",
              condition:true,
              label:"Save",
              class:"menu-button settings",
              click:handleSaveSettings
            }]
          }
        />
      )}

      


    </div>
  );
};

export default ExploreContainer;
