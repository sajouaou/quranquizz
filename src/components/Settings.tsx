import React from 'react';

const Settings = ({
  numberOfAyat,
  minSurah,
  maxSurah,
  minVerse,
  maxVerse,
  chapters,
  filterVerse,
  askVerse,
  volume,
  setNumberOfAyat,
  setMinSurah,
  setMaxSurah,
  setMinVerse,
  setMaxVerse,
  setVolume,
  handleSaveSettings,
  setFilterVerse,
  setAskVerse
}) => {

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
    const handleVolumeChange = (event: React.ChangeEvent<HTMLInputElement>) => {
        setVolume(parseFloat(event.target.value));
    };
  return (
    <div className="settings-container">
      { numberOfAyat && (
      <>
      <label htmlFor="numberOfAyat">Number of Ayat:</label><input
                  type="number"
                  id="numberOfAyat"
                  min="1"
                  max="286"
                  step="1"
                  value={numberOfAyat}
                  onChange={handleChangeNumberOfAyat} /><br />
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

      <button onClick={handleSaveSettings}>Save</button>
    </div>
  );
};

export default Settings;