import React, { useState, useEffect, useRef } from 'react';
import Game from '../components/Game';
import './ExploreContainer.css';
import Settings from './user/Settings';
import InputGame from './user/InputGame'; // Import the InputGame component
import AudioSection from './user/AudioSection'; // Import the InputGame component
import Player from './Player';

interface ContainerProps 
{
  mode: string;
  chapters: Chapter[]
}


interface Chapter {
  id: number;
  name_simple: string;
  verses_count: number;
}

const ExploreContainer: React.FC<ContainerProps> = ({ mode, chapters }) => {
  const [confirmedChapter, setConfirmedChapter] = useState<number | null>(null);
  const [confirmedVerse, setConfirmedVerse] = useState<number>(0);
  const [askVerse, setAskVerse] = useState(false);
  const [filterVerse, setFilterVerse] = useState(false);
  const [verseDistribustion, setVerseDistribustion] = useState(false);
  const [numberOfAyat, setNumberOfAyat] = useState(1); // Nombre d'ayat par défaut
  const [minSurah, setMinSurah] = useState(1); // 
  const [maxSurah, setMaxSurah] = useState(114); //
  const [minVerse, setMinVerse] = useState(0); // 
  const [maxVerse, setMaxVerse] = useState(286); //
  const [maximumVerse, setMaximumVerse] = useState(286); //
  const [isLimited, setLimit] = useState(false);
  const [isSkip, setSkip] = useState(false);
  const [round, setRound] = useState(1); // 
  const [currentRound,setCurrentRound] = useState(0);
  //Lives
  const [activeLive, setActiveLive] = useState(false);
  const [lives, setLives] = useState(1);
  const setAllLive = (nbLives) => {
    setLives(nbLives);
    players.forEach(player => {
      player.setLives(nbLives);
  });
  }
  const setAllActiveLive = (showA) => {
    setActiveLive(showA);
    players.forEach(player => {
      player.setShowLive(showA);
      player.setLives(lives);
  });
  }
  
  //Score
  const [showScore, setShowScore] = useState(false);
  const setAllShowScore = (showS) => {
    setShowScore(showS);
    players.forEach(player => {
      player.setShowScore(showS);
  });
  }

  const setNotReady = () => {
    players.forEach(player => {
      player.setGameState('not ready');
    });
  }


  
  const getRandomChapterNumber = () => {
    let res = Math.floor(Math.random() * (maxSurah - minSurah + 1)) + minSurah;
    if(verseDistribustion){
      let chapterArrays: number[] = [];
      chapters.filter(function(chapter) {
        return chapter.id <= maxSurah && chapter.id >= minSurah;
      }).forEach(chapter => {
        let length = chapter.verses_count;
        if(chapter.id === maxSurah && filterVerse){
          length = maxVerse;
        }
        if(chapter.id === minSurah && filterVerse){
          length = length - minVerse;
        }
        const array = Array.from({ length: length }, () => chapter.id);
        chapterArrays.push(...array);
      });
      res = Math.floor(Math.random() * (chapterArrays.length)) ;
      res = chapterArrays[res];
    }
    return res; // Generates a random number between 1 and 114
  };

  const getRandomVerseNumber = (chapterId: number) => {
    let maxtemp =  chapters.filter(function(chapter) {
      return chapter.id === chapterId;
    })[0].verses_count;
    if(filterVerse && chapterId === maxSurah && maxVerse + 1 <= maxtemp){
      maxtemp = maxVerse + 1 ;
    }
    let minimumVerse = 0;
    if(filterVerse && chapterId === minSurah && minVerse <= maxtemp){
      minimumVerse = minVerse;
    }
    let verse = Math.floor(Math.random() * maxtemp) + minimumVerse;
    if(verse + numberOfAyat >= maxtemp)
    {
      verse = maxtemp  - numberOfAyat;
      if(verse < minimumVerse){
        verse = minimumVerse;
      }
    }
    setMaximumVerse(maxtemp);
    return verse;
  };

  
  

  const checkChoice = (chapterId:number| null,verseId:number| null) => {
    const found = chapterId === confirmedChapter && (verseId === confirmedVerse || !askVerse);
    return found;
  }

  const checkPlayers = () => {
    let allReady = true;
    players.forEach(player => {
        if( ! player.isReady()) {
          allReady =  false;
        }
    });
    return allReady;
  }
  const isPlayersLost = () => {
    let allLost = true;
    players.forEach(player => {
        if( player.isAlive()) {
          allLost =  false;
        }
    });
    return allLost;
  }
  const checkGuessAllPlayers = async () => {
    if((!isLimited || currentRound  <= round) && (! isPlayersLost())){
      const allReady = checkPlayers();
      setallPReady(allReady);
      if(allReady){
        let fail = false;
        players.forEach(player => {
          if(player.gameState !== 'next'){
            fail = checkGuess(player);
          }
          else{
            fail = true;
            player.setLives(player.lives -1);
            player.setStreak(0);
          }

          if(!fail){
            player.setLives(player.lives -1);
          }
          player.correct(confirmedChapter,confirmedVerse);
        });
        if(isSkip || fail){
          await playNext(currentRound);
        }
        setTimeout(() => { handleEndofRound(); }, 1000); 
      }
      
    }
    else {
      setTimeout(() => { handleEndofRound(); }, 1000); 
    }
  }
  const checkGuess = (player:Player) => {
    const found = checkChoice(player.guessChapter,player.guessVerse);
    if(found){
      player.success();
    }
    else{
      player.fail();
    }
    return found;
  }

  const newSurah = (curRound: number) => {
    if(isLimited){
      setCurrentRound(curRound+1);
    }
    if( (!isLimited || curRound < round) &&  (! isPlayersLost()) ){
      const randomChap = getRandomChapterNumber();
      const randomVerse = getRandomVerseNumber(randomChap);
      setConfirmedChapter(randomChap);
      setConfirmedVerse(randomVerse);
      return [randomChap,randomVerse];
    }
    else {
      return [-1,-1];
    }
    
  }

  const playNext = async (curRound: number) => { 
    const rand = newSurah(curRound); // Attendre le chargement du fichier audio  
    if(rand[0] !== -1){
      await audioSection.fetchAudioFile(rand[0], rand[1]);

    }

  }



  const [showInput, setShowInput] = useState(false);
  const [showEnd, setShowEnd] = useState(false);
  const [showSettings, setShowSettings] = useState(false);

  const audioSection = new AudioSection({ numberOfAyat, maximumVerse,confirmedVerse, showInput});
  
  const [allPReady, setallPReady] = useState(false);
  let players = [new Player({name:"Me",}),new Player({name:"Other",})];
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
    if((isLimited && currentRound >= round) || (isPlayersLost())){
      setCurrentRound(0);
      setNotReady();
      resetScore();
      setAllLive(lives);
      setShowEnd(true);
      setShowInput(false);
    }
  }


  const handleStartClick = async () => {
    setShowInput(true);
    setShowEnd(false);
    await playNext(0);
  };  

  const handleSaveSettings = () => {
    // Enregistrez les paramètres
    setShowSettings(false);
  };

  const resetScore = () =>{
    players.forEach(player => {
      player.resetScore();
    });
  }



  useEffect(() => {
    if (audioSection ) {
      audioSection.playAudio();
    }
  }, [audioSection]);


  return (
    <div>

      
      {showInput && (
        <div>
        {isLimited && (
          <>
          <label> {currentRound}/{round} </label> 
          <br></br>
          </>
        )}
        <label>Which chapter does the recited ayah correspond to ? </label>

        <div className='player-container'>
        {
        players.map((player, index) => (
          <div className='control-container' key={index}>
          <React.Fragment key={index}>
            <InputGame
            replayAudio={audioSection.replayAudio}
            chapters={chapters}
            minSurah={minSurah}
            maxSurah={maxSurah}
            askVerse={askVerse}
            maxVerse={maxVerse}
            minVerse={minVerse}
            allReady={allPReady}
            checkGuessPlayer={checkGuessAllPlayers }
            player={player}
            />
          {player.render()}
          </React.Fragment>
          </div>
        ))
        }
        </div>


        {audioSection && (audioSection.render())}
        </div>
      
      )}

      {!showInput && (
        <button className="menu-button start"  onClick={handleStartClick}>Start</button>
      )}
      <button className="menu-button settings"  onClick={() => setShowSettings(!showSettings)}>Settings</button>
      
      {showSettings && (
          <Settings
          numberOfAyat={numberOfAyat}
          minSurah={minSurah}
          maxSurah={maxSurah}
          minVerse={minVerse}
          maxVerse={maxVerse}
          chapters={chapters}
          filterVerse={filterVerse}
          askVerse={askVerse}
          verseDistribustion={verseDistribustion}
          volume={audioSection.volume}
          setNumberOfAyat={setNumberOfAyat}
          setMinSurah={setMinSurah}
          setMaxSurah={setMaxSurah}
          setMinVerse={setMinVerse}
          setMaxVerse={setMaxVerse}
          setVerseDistribustion={setVerseDistribustion}
          setVolume={audioSection.setVolumeAudio}
          handleSaveSettings={handleSaveSettings}
          setFilterVerse={setFilterVerse}
          setAskVerse={setAskVerse}
          resetscore={resetScore}
          showScore={showScore}
          setShowScore={setAllShowScore}
          isLimited={isLimited}
          setLimit={setLimit}
          round={round}
          setRound={setRound}
          isSkip={isSkip}
          setSkip={setSkip}
          activeLive={activeLive}
          setActiveLive={setAllActiveLive}
          lives={lives}
          setLives={setAllLive}
          />
      )}
    </div>
  );
};

export default ExploreContainer;
