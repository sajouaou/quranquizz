import React from 'react';

const Settings = ({
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
  setShowScore
}) => {

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