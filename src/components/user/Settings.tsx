import React from 'react';

interface SettingsProps {
  numberOfAyat: number;
  minSurah: number;
  maxSurah: number;
  minVerse: number;
  maxVerse: number;
  verseDistribustion: any; // Remplacez 'any' par le type correct si possible
  chapters: any[]; // Remplacez 'any[]' par le type correct si possible
  filterVerse: any; // Remplacez 'any' par le type correct si possible
  askVerse: boolean;
  volume: number;
  setNumberOfAyat: (value: number) => void; // Remplacez '(value: number) => void' par la signature correcte de la fonction si nécessaire
  setMinSurah: (value: number) => void; // Remplacez '(value: number) => void' par la signature correcte de la fonction si nécessaire
  setMaxSurah: (value: number) => void; // Remplacez '(value: number) => void' par la signature correcte de la fonction si nécessaire
  setMinVerse: (value: number) => void; // Remplacez '(value: number) => void' par la signature correcte de la fonction si nécessaire
  setMaxVerse: (value: number) => void; // Remplacez '(value: number) => void' par la signature correcte de la fonction si nécessaire
  setVerseDistribustion: (value: any) => void; // Remplacez '(value: any) => void' par la signature correcte de la fonction si nécessaire
  setVolume: (value: number) => void; // Remplacez '(value: number) => void' par la signature correcte de la fonction si nécessaire
  handleSaveSettings: () => void; // Remplacez '() => void' par la signature correcte de la fonction si nécessaire
  setFilterVerse: (value: any) => void; // Remplacez '(value: any) => void' par la signature correcte de la fonction si nécessaire
  setAskVerse: (value: boolean) => void; // Remplacez '(value: boolean) => void' par la signature correcte de la fonction si nécessaire
  resetscore: () => void; // Remplacez '() => void' par la signature correcte de la fonction si nécessaire
  showScore: boolean;
  setShowScore: (value: boolean) => void; // Remplacez '(value: boolean) => void' par la signature correcte de la fonction si nécessaire
  isLimited: boolean;
  setLimit: (value: boolean) => void; // Remplacez '(value: boolean) => void' par la signature correcte de la fonction si nécessaire
  round: number;
  setRound: (value: number) => void; // Remplacez '(value: number) => void' par la signature correcte de la fonction si nécessaire
  isSkip: boolean;
  setSkip: (value: boolean) => void; // Remplacez '(value: boolean) => void' par la signature correcte de la fonction si nécessaire
  activeLive: boolean;
  setActiveLive: (value: boolean) => void; // Remplacez '(value: boolean) => void' par la signature correcte de la fonction si nécessaire
  lives: number;
  setLives: (value: number) => void; // Remplacez '(value: number) => void' par la signature correcte de la fonction si nécessaire
}

const Settings: React.FC<SettingsProps> = ({
  numberOfAyat,
  minSurah,
  maxSurah,
  minVerse,
  maxVerse,
  verseDistribustion,
  chapters,
  filterVerse,
  askVerse,
  volume,
  setNumberOfAyat,
  setMinSurah,
  setMaxSurah,
  setMinVerse,
  setMaxVerse,
  setVerseDistribustion,
  setVolume,
  handleSaveSettings,
  setFilterVerse,
  setAskVerse,
  resetscore,
  showScore,
  setShowScore,
  isLimited,
  setLimit,
  round,
  setRound,
  isSkip,
  setSkip,
  activeLive,
  setActiveLive,
  lives,
  setLives
}) => {

  const handleChangeNumberOfRound = (event: React.ChangeEvent<HTMLSelectElement>) => {
    setRound(parseInt(event.target.value));
  };
  const handleChangeNumberOfLives = (event: React.ChangeEvent<HTMLSelectElement>) => {
    setLives(parseInt(event.target.value));
  };
    const handleChangeNumberOfAyat = (event: React.ChangeEvent<HTMLSelectElement>) => {
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
    const handleVolumeChange = (event: React.ChangeEvent<HTMLInputElement>) => {
        setVolume(parseFloat(event.target.value));
    };
  return (
    <div className="settings-container">
      { numberOfAyat && (
      <>
      <label htmlFor="numberOfAyat">Number of Ayat:</label>
      
      <select id="minSurah" value={numberOfAyat || ''} onChange={handleChangeNumberOfAyat}>
        { [...Array(286).keys()].map((x, i) => (
                <option key={x} value={x + 1}>
                  {x + 1} 
                </option>
              ))
        } 

      </select>
      <br />
      </>
    )}

    { minSurah && (
      <>
    
      <label htmlFor="minSurah">Minimum Surah:</label>
      <select id="minSurah" value={minSurah || ''} onChange={handleChangeMinSurah}>
        <option value="">Select a chapter</option>
        {chapters
          .filter((chapter) => chapter.id <= maxSurah)
          .map((chapter) => (
            <option key={chapter.id} value={chapter.id}>
              {chapter.name_simple}
            </option>
          ))}
      </select>
      {filterVerse && minVerse != null  && (
        <select id="verseMinSelect" value={minVerse || ''} onChange={handleChangeMinVerse}>
          {chapters
            .filter((chapter) => chapter.id === minSurah)
            .map((chapter) =>
              [...Array(chapter.verses_count).keys()]
                .filter((x, i) => minSurah !== maxSurah || x <= maxVerse)
                .map((x, i) => (
                  <option key={x} value={x}>
                    {x + 1} 
                  </option>
                ))
            )}
        </select>
      )}
      <br />
      </>
    )}

    
    { maxSurah && (
      <>
      <label htmlFor="maxSurah">Maximum Surah:</label>
      <select id="maxSurah" value={maxSurah || ''} onChange={handleChangeMaxSurah}>
        <option value="">Select a chapter</option>
        {chapters
          .filter((chapter) => minSurah <= chapter.id)
          .map((chapter) => (
            <option key={chapter.id} value={chapter.id}>
              {chapter.name_simple} 
            </option>
          ))}
      </select>
      {filterVerse && maxVerse != null && (
        <select id="verseMaxSelect" value={maxVerse || ''} onChange={handleChangeMaxVerse}>
          {chapters
            .filter((chapter) => chapter.id === maxSurah)
            .map((chapter) =>
              [...Array(chapter.verses_count).keys()]
                .filter((x, i) => minSurah !== maxSurah || minVerse  <= x)
                .map((x, i) => (
                  <option key={x} value={x}>
                    {x + 1}
                  </option>
                ))
            )}
        </select>
      )}
      <br />
      </>
    )}

    
    { askVerse != null && (
      <>
      <label htmlFor="switch">Ask Verses:</label>
      <label className="switch">
        <input type="checkbox" checked={askVerse} onChange={() => setAskVerse(!askVerse)} />
        <span className="slider round"></span>
      </label>
      <br />
      </>
    )}
    
    { filterVerse != null && (
      <>
      <label htmlFor="switchF">Filter Verses:</label>
      <label className="switchF">
        <input type="checkbox" checked={filterVerse} onChange={() => setFilterVerse(!filterVerse)} />
        <span className="slider round"></span>
      </label>
      <br />
      </>
    )}

    

    
  { verseDistribustion != null && (
      <>
      <label htmlFor="switchFs">Random Verses Distribution:</label>
      <label className="switchFs">
        <input type="checkbox" checked={verseDistribustion} onChange={() => setVerseDistribustion(!verseDistribustion)} />
        <span className="slider round"></span>
      </label>
      <br />
      </>
    )}
    
    { isLimited != null && (
        <>
        <label htmlFor="switchFsd">Limit :</label>
        <label className="switchFsd">
          <input type="checkbox" checked={isLimited} onChange={() => setLimit(!isLimited)} />
          <span className="slider round"></span>
        </label>
        <br />
        </>
      )}

      
    {round != null  && (isLimited == null || isLimited) && (
      <>
      <label htmlFor="numberOfRound">Number of Round:</label>
      
      <select id="round" value={round || ''} onChange={handleChangeNumberOfRound}>
        { [...Array(50).keys()].map((x, i) => (
                <option key={x} value={x + 1}>
                  {x + 1} 
                </option>
              ))
        } 

      </select>
      <br />
      </>
    )}

    { isSkip != null && (
          <>
          <label htmlFor="switchFdc">Skip if fail :</label>
          <label className="switchFdc">
            <input type="checkbox" checked={isSkip} onChange={() => setSkip(!isSkip)} />
            <span className="slider round"></span>
          </label>
          <br />
          </>
    )}

  

    { showScore != null && (
          <>
          <label htmlFor="switchFd">Show Score :</label>
          <label className="switchFd">
            <input type="checkbox" checked={showScore} onChange={() => setShowScore(!showScore)} />
            <span className="slider round"></span>
          </label>
          <br />
          </>
    )}

    { activeLive != null && (
        <>
        <label htmlFor="switchActiveLive">Active Lives :</label>
        <label className="switchActiveLive">
          <input type="checkbox" checked={activeLive} onChange={() => setActiveLive(!activeLive)} />
          <span className="slider round"></span>
        </label>
        <br />
        </>
      )}

      
    {lives != null  && (activeLive == null || activeLive) && (
      <>
      <label htmlFor="numberOfLives">Number of Lives:</label>
      
      <select id="lives" value={lives || ''} onChange={handleChangeNumberOfLives}>
        { [...Array(50).keys()].map((x, i) => (
                <option key={x} value={x + 1}>
                  {x + 1} 
                </option>
              ))
        } 

      </select>
      <br />
      </>
    )}
    
    {resetscore != null  && (showScore == null || showScore) && (
      <>
      <button className="menu-button settings"  onClick={resetscore}>Reset Score</button>
      <br />
      </>
    )}

    
    { volume != null && (
      <>
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
      </>
    )}

      <button className="menu-button settings"  onClick={handleSaveSettings}>Save</button>
    </div>
  );
};

export default Settings;