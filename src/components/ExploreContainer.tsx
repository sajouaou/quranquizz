import React, { useState, useEffect } from 'react';
import './ExploreContainer.css';

interface ContainerProps 
{
  mode: string;
}

interface Chapter {
  id: number;
  name_simple: string;
  verses_count: number;
}

const ExploreContainer: React.FC<ContainerProps> = ({ mode }) => {
  const [showInput, setShowInput] = useState(false);
  const [chapters, setChapters] = useState<Chapter[]>([]);
  const [selectedChapter, setSelectedChapter] = useState<number | null>(null);
  const [selectedVerse, setSelectedVerse] = useState<number | null>(null);
  
  const [confirmedChapter, setConfirmedChapter] = useState<number | null>(null);
  const [previousChapter, setPreviousChapter] = useState<number | null>(null);
  const [previousVerse, setPreviousVerse] = useState<number | null>(null);
  const [showSuccessAnimation, setShowSuccessAnimation] = useState(false);
  const [showFailureAnimation, setShowFailureAnimation] = useState(false);
  const [showNextAnimation, setShowNextAnimation] = useState(false);

  const [audioFile, setAudioFile] = useState<string | null>(null);
  const audioRef = React.useRef<HTMLAudioElement>(null);

  const [showSettings, setShowSettings] = useState(false);
  const [askVerse, setAskVerse] = useState(false);
  const [filterVerse, setFilterVerse] = useState(false);
  const [numberOfAyat, setNumberOfAyat] = useState(1); // Nombre d'ayat par défaut
  const [minSurah, setMinSurah] = useState(1); // 
  const [maxSurah, setMaxSurah] = useState(114); //

  const [minVerse, setMinVerse] = useState(0); // 
  const [maxVerse, setMaxVerse] = useState(286); //
  const [maximumVerse, setMaximumVerse] = useState(286); //

  const [volume, setVolume] = useState(0.5);

  const [confirmedVerse, setConfirmedVerse] = useState<number>(0);

  const [ayat, setAyat] = useState<number>(0);
  const [data, setData] = useState<Promise<any>>();

  const handleSuccess = async () => {
    setShowSuccessAnimation(true);
    setTimeout(() => setShowSuccessAnimation(false), 1000); // Masquer l'animation après 1 seconde
    //playAudio();
  };
  
  const handleNext = async () => {
    setShowNextAnimation(true);
    setTimeout(() => setShowNextAnimation(false), 1000); // Masquer l'animation après 1 seconde
    //playAudio();
  };

  const handleFailure = () => {
    setShowFailureAnimation(true);
    setTimeout(() => setShowFailureAnimation(false), 1000); // Masquer l'animation après 1 seconde

    // Echouer
  };

  useEffect(() => {
    if (audioFile && showInput) {
      playAudio();
    }
  }, [audioFile, showInput]);

  useEffect(() => {
    const fetchChapters = async () => {
      try {
        const response = await fetch('https://api.quran.com/api/v4/chapters');
        if (response.ok) {
          const data = await response.json();
          setChapters(data.chapters);
        } else {
          console.error('Failed to fetch chapters');
        }
      } catch (error) {
        console.error('Error fetching chapters:', error);
      }
    };

    fetchChapters();
  }, []);

  const getRandomChapterNumber = () => {
    return Math.floor(Math.random() * (maxSurah-minSurah + 1)) + minSurah; // Generates a random number between 1 and 114
  };

  const handleButtonClick = async () => {
    setShowInput(true);
    const randomChap = getRandomChapterNumber();
    await fetchAudioFile(randomChap); // Attendre le chargement du fichier audio
  };

  const handleNextButtonClick = async () => {
    setPreviousChapter(confirmedChapter);
    setPreviousVerse(confirmedVerse);
    await handleNext();
    await handleButtonClick(); // Attendre le chargement du fichier audio
  };

  const handleChapterSelect = (event: React.ChangeEvent<HTMLSelectElement>) => {
    const selectedChapterId = parseInt(event.target.value);
    setSelectedChapter(selectedChapterId);
  };

  
  const handleVerseSelect = (event: React.ChangeEvent<HTMLSelectElement>) => {
    const selectedVerseId = parseInt(event.target.value);
    setSelectedVerse(selectedVerseId);
  };

  const handleConfirmButtonClick = async () => {
    if (selectedChapter === confirmedChapter && ( confirmedVerse === selectedVerse || !askVerse) ) {
      await handleSuccess();
      const randomChap = getRandomChapterNumber();
      await fetchAudioFile(randomChap);
      //playAudio();
    }
    else {
      await handleFailure();
    }
  };

  const fetchAudioFile = async (chapterId: number) => {
    try {
      const response = await fetch(`https://api.quran.com/api/v4/recitations/10/by_chapter/${chapterId}?per_page=286`);
      if (response.ok) {
        const data = await response.json();
        if (data.audio_files.length > 0) {
          let maxtemp = data.audio_files.length;
          if(filterVerse && chapterId === maxSurah && maxVerse + 1 <= maxtemp){
            maxtemp = maxVerse + 1 ;
          }
          let minimumVerse = 0;
          if(filterVerse && chapterId === minSurah && minVerse <= maxtemp){
            minimumVerse = minVerse;
          }
          let verse = Math.floor(Math.random() * maxtemp) + minimumVerse;
          if(verse + numberOfAyat >= maximumVerse)
          {
            verse = maxtemp  - numberOfAyat;
            if(verse < minimumVerse){
              verse = minimumVerse;
            }
          }
          setAyat(0);
          setConfirmedChapter(chapterId);
          setConfirmedVerse(verse);
          setMaximumVerse(maxtemp);
          setData(data);
          setAudioFile(`https://verses.quran.com/${data.audio_files[verse].url}`);
          //playAudio();
        } else {
          console.error('No audio file found for chapter:', chapterId);
        }
      } else {
        console.error('Failed to fetch audio file for chapter:', chapterId);
      }
    } catch (error) {
      console.error('Error fetching audio file:', error);
    }
  };
  const handleChangeNumberOfAyat = (event: React.ChangeEvent<HTMLInputElement>) => {
    setNumberOfAyat(parseInt(event.target.value));
  };
  
  const handleChangeMinSurah = (event: React.ChangeEvent<HTMLSelectElement>) => {
    setMinSurah(parseInt(event.target.value));
  };
  
  const handleChangeMaxSurah = (event: React.ChangeEvent<HTMLSelectElement>) => {
    setMaxSurah(parseInt(event.target.value));
  };
  
  const handleChangeMaxVerse = (event: React.ChangeEvent<HTMLSelectElement>) => {
    setMaxVerse(parseInt(event.target.value));
  };
  
  const handleChangeMinVerse = (event: React.ChangeEvent<HTMLSelectElement>) => {
    setMinVerse(parseInt(event.target.value));
  };

  

  const handleSaveSettings = () => {
    // Enregistrez les paramètres
    setShowSettings(false);
  };

  const replayAudio = () => {
    setAyat(0);
    setAudioFile(`https://verses.quran.com/${data.audio_files[confirmedVerse].url}`);
    playAudio();
  };

  const playAudio = () => {
    if (audioFile && audioRef.current) {
      audioRef.current.src = audioFile;
      audioRef.current.volume = volume;
      audioRef.current.play();
      audioRef.current.onended = () => {
        if(ayat+1 < numberOfAyat && ayat+1 < maximumVerse){
          setAyat(ayat+1);
          setAudioFile(`https://verses.quran.com/${data.audio_files[confirmedVerse+ayat+1].url}`);
        }
      };
    }
  };

  const handleVolumeChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const newVolume = parseFloat(event.target.value);
    setVolume(newVolume);
    if (audioRef.current) {
      audioRef.current.volume = newVolume;
    }
  };

  return (
    <div id="container">
      {!showInput && (
        <button onClick={handleButtonClick}>Start</button>
      )}

      
      {showInput && (
        
        <div>
          <button className="menu-button replay" onClick={replayAudio}>Replay </button>
          <button className="menu-button confirm" onClick={handleConfirmButtonClick}>Confirm</button>
          <br />

          <label htmlFor="chapterSelect">Which chapter does the recited ayah correspond to ? </label>
          <select id="chapterSelect" value={selectedChapter || ''} onChange={handleChapterSelect}>
            <option value="">Select a chapter</option>
            {chapters.filter(function(chapter) {
              return minSurah <= chapter.id && chapter.id <= maxSurah;
            }).map((chapter) => (
              <option key={chapter.id} value={chapter.id}>
                {chapter.name_simple}
              </option>

            ))}
          </select>
          { askVerse && ( 
          <select id="verseSelect" value={selectedVerse || ''} onChange={handleVerseSelect}>
            {selectedChapter && chapters.filter(function(chapter) {
              return chapter.id == selectedChapter;
            }).map((chapter) => (
              
              [...Array(chapter.verses_count).keys()].filter(function(x,i) {
                return (maxSurah !== selectedChapter || i <= maxVerse) && (minSurah !== selectedChapter || minVerse <= i);
              }).map((x, i) =>
                
                <option key={x} value={x}>
                {x+1}
                </option>
              )


            ))}
          </select>)
          }


          <br />
          <button className="menu-button next"  onClick={handleNextButtonClick}>Next</button>

          {showSuccessAnimation && (
                  <div className="success-animation">Bien jouej</div>
                )}

          {showFailureAnimation && (
            <div className="failure-animation">Nope</div>
          )}
          {showNextAnimation && (
            <div className="next-animation">{chapters.filter(function(chapter) {return chapter.id === previousChapter;}).map((chapter) => (chapter.name_simple))} {askVerse?previousVerse+1:""}</div>
          )}
        </div>
        
      )}

      <button className="menu-button settings"  onClick={() => setShowSettings(!showSettings)}>Settings</button>
      
      {showSettings && (

        <div className="settings-container">
          <label htmlFor="numberOfAyat">Number of Ayat:</label>
          <input
            type="number"
            id="numberOfAyat"
            min="1"
            max="286"
            step="1"
            value={numberOfAyat}
            onChange={handleChangeNumberOfAyat}
          />
          <br />
          <label htmlFor="minSurah">Minimum Surah:</label>
          
          <select id="minSurah" value={minSurah || ''} onChange={handleChangeMinSurah}>
            <option value="">Select a chapter</option>
            {chapters.filter(function(chapter) {
              return chapter.id <= maxSurah;
            }).map((chapter) => (
              <option key={chapter.id} value={chapter.id}>
                {chapter.name_simple}
              </option>

            ))}
          </select>
          {filterVerse &&(
          <select id="verseMinSelect" value={minVerse || ''} onChange={handleChangeMinVerse}>
            {chapters.filter(function(chapter) {
              return chapter.id == minSurah;
            }).map((chapter) => (
              [...Array(chapter.verses_count).keys()].filter(function(x,i) {
                return minSurah !== maxSurah || i <= maxVerse;
              }).map((x, i) =>
                
                <option key={x} value={x}>
                {x+1}
                </option>
              )


            ))}
          </select>)}


          <br />
          <label htmlFor="maxSurah">Maximum Surah:</label>
          
          <select id="maxSurah" value={maxSurah || ''} onChange={handleChangeMaxSurah}>
            <option value="">Select a chapter</option>
            {chapters.filter(function(chapter) {
              return minSurah <= chapter.id;
            }).map((chapter) => (
              <option key={chapter.id} value={chapter.id}>
                {chapter.name_simple}
              </option>

            ))}
          </select>
          {filterVerse && (
          <select id="verseMaxSelect" value={maxVerse || ''} onChange={handleChangeMaxVerse}>
            {chapters.filter(function(chapter) {
              return chapter.id == maxSurah;
            }).map((chapter) => (
              [...Array(chapter.verses_count).keys()].filter(function(x,i) {
                return minSurah !== maxSurah || minVerse <= i;
              }).map((x, i) =>
                
                <option key={x} value={x}>
                {x+1}
                </option>
              )


            ))}
          </select>)}

          <br />
          
          <label htmlFor="switch">Ask Verses:</label>

          <label className="switch">
            <input type="checkbox" checked={askVerse} onChange={() => setAskVerse(!askVerse)}/>
            <span className="slider round"></span>
          </label>

          
          <br />
          <label htmlFor="switchF">Filter Verses:</label>

          <label className="switchF">
            <input type="checkbox" checked={filterVerse} onChange={() => setFilterVerse(!filterVerse)}/>
            <span className="slider round"></span>
          </label>

          <br />
          

          <label htmlFor="volumeSlider">Volume:</label>
          <input
            type="range"
            id="volumeSlider"
            min="0"
            max="1"
            step="0.01"
            value={volume}
            onChange={handleVolumeChange}
          />
          <br />
          
          <button onClick={handleSaveSettings}>Save</button>
        </div>
      )}

      <audio className='invisible' ref={audioRef}  controls />
    </div>
  );
};

export default ExploreContainer;
