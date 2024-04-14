import React, { useState, useEffect, useRef } from 'react';
import Game from '../components/Game';
import './ExploreContainer.css';
import Settings from './Settings';
import InputGame from './InputGame'; // Import the InputGame component
import AudioSection from './AudioSection'; // Import the InputGame component

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
  
  const newSurah = () => {
    const randomChap = getRandomChapterNumber();
    const randomVerse = getRandomVerseNumber(randomChap);
    setConfirmedChapter(randomChap);
    setConfirmedVerse(randomVerse);
    return [randomChap,randomVerse];
  }



  const [showInput, setShowInput] = useState(false);
  const [showSettings, setShowSettings] = useState(false);

  const audioSection = new AudioSection({ numberOfAyat, maximumVerse,confirmedVerse, showInput});
  

  const handleStartClick = async () => {
    setShowInput(true);
    const rand = newSurah(); // Attendre le chargement du fichier audio  
    await audioSection.fetchAudioFile(rand[0], rand[1]);
  };  

  const handleSaveSettings = () => {
    // Enregistrez les paramètres
    setShowSettings(false);
  };


  useEffect(() => {
    if (audioSection ) {
      audioSection.playAudio();
    }
  }, [audioSection]);


  return (
    <div id="container">

      
      {showInput && (
        <>
          <InputGame
          replayAudio={audioSection.replayAudio}
          chapters={chapters}
          minSurah={minSurah}
          maxSurah={maxSurah}
          askVerse={askVerse}
          newSurah={newSurah}
          maxVerse={maxVerse}
          minVerse={minVerse}
          fetchAudioFile={audioSection.fetchAudioFile}
          confirmedChapter={confirmedChapter}
          confirmedVerse={confirmedVerse}
          checkChoice={checkChoice}
        />
        {audioSection && (audioSection.render())}
        </>
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
          />
      )}
    </div>
  );
};

export default ExploreContainer;
