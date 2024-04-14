import React, { useState, useEffect } from 'react';

const InputGame = ({
  replayAudio,
  chapters,
  minSurah,
  maxSurah,
  maxVerse,
  minVerse,
  askVerse,
  confirmedChapter,
  confirmedVerse,
  newSurah,
  fetchAudioFile,
  checkChoice
}) => {
    
  const [showSuccessAnimation, setShowSuccessAnimation] = useState(false);
  const [showFailureAnimation, setShowFailureAnimation] = useState(false);
  const [showNextAnimation, setShowNextAnimation] = useState(false);
  const [selectedChapter, setSelectedChapter] = useState<number | null>(null);
  const [selectedVerse, setSelectedVerse] = useState<number | null>(null);
  const [previousChapter, setPreviousChapter] = useState<number | null>(null);
  const [previousVerse, setPreviousVerse] = useState<number | null>(null);


    
    
  const handleSuccess = async () => {
    setShowSuccessAnimation(true);
    setTimeout(() => setShowSuccessAnimation(false), 1000); // Masquer l'animation après 1 seconde
  };
  
  const handleNext = async () => {
    setShowNextAnimation(true);
    setTimeout(() => setShowNextAnimation(false), 1000); // Masquer l'animation après 1 seconde
  };

  const handleFailure = () => {
    setShowFailureAnimation(true);
    setTimeout(() => setShowFailureAnimation(false), 1000); // Masquer l'animation après 1 seconde
  };

  const handleNextButtonClick = async () => {
    setPreviousChapter(confirmedChapter);
    setPreviousVerse(confirmedVerse);
    await handleNext();
    const rand = newSurah(); // Attendre le chargement du fichier audio  
    await fetchAudioFile(rand[0], rand[1]);
  };
  
  const handleConfirmButtonClick = async () => {
    if (checkChoice(selectedChapter,selectedVerse) ) {
      await handleSuccess();
      const rand = newSurah(); // Attendre le chargement du fichier audio  
      await fetchAudioFile(rand[0], rand[1]);
    }
    else {
      await handleFailure();
    }

  };


  const handleChapterSelect = (event: React.ChangeEvent<HTMLSelectElement>) => {
    const selectedChapterId = parseInt(event.target.value);
    setSelectedChapter(selectedChapterId);
  };
  const handleVerseSelect = (event: React.ChangeEvent<HTMLSelectElement>) => {
    const selectedVerseId = parseInt(event.target.value);
    setSelectedVerse(selectedVerseId);
  };


  return (
    <div>
      {replayAudio && (
      <button className="menu-button replay" onClick={replayAudio}>Replay </button>
      )}
      <button className="menu-button confirm" onClick={handleConfirmButtonClick}>Confirm</button>
      <br />

      <label htmlFor="chapterSelect">Which chapter does the recited ayah correspond to ? </label>
      <select id="chapterSelect" value={selectedChapter || ''} onChange={handleChapterSelect}>
        <option value="">Select a chapter</option>
        {chapters
          .filter((chapter) => minSurah <= chapter.id && chapter.id <= maxSurah)
          .map((chapter) => (
            <option key={chapter.id} value={chapter.id}>
              {chapter.name_simple}
            </option>
          ))}
      </select>
      {askVerse && (
        <select id="verseSelect" value={selectedVerse || ''} onChange={handleVerseSelect}>
          {selectedChapter &&
            chapters
              .filter((chapter) => chapter.id === selectedChapter)
              .map((chapter) =>
                [...Array(chapter.verses_count).keys()]
                  .filter((x, i) => (maxSurah !== selectedChapter || i <= maxVerse) && (minSurah !== selectedChapter || minVerse <= i))
                  .map((x, i) => (
                    <option key={x} value={x}>
                      {x + 1}
                    </option>
                  ))
              )}
        </select>
      )}

      <br />
      <button className="menu-button next" onClick={handleNextButtonClick}>Next</button>

      {showSuccessAnimation && (
        <div className="success-animation">Bien jouej</div>
      )}

      {showFailureAnimation && (
        <div className="failure-animation">Nope</div>
      )}
      {showNextAnimation && (
        <div className="next-animation">
          {chapters.filter((chapter) => chapter.id === previousChapter).map((chapter) => (chapter.name_simple))} {askVerse ? previousVerse + 1 : ""}
        </div>
      )}

    </div>
  );
};

export default InputGame;
