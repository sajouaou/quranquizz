import { play } from 'ionicons/icons';
import React, { useState, useEffect } from 'react';

const InputGame = ({
  replayAudio,
  chapters,
  minSurah,
  maxSurah,
  maxVerse,
  minVerse,
  askVerse,
  allReady,
  checkGuessPlayer,
  player
}) => {
    
  const [showSuccessAnimation, setShowSuccessAnimation] = useState(false);
  const [showFailureAnimation, setShowFailureAnimation] = useState(false);
  const [showNextAnimation, setShowNextAnimation] = useState(false);


  useEffect(() => {
    if (allReady ) {
      if(player.gameState === 'win'){
        handleSuccess();
      }
      
      if(player.gameState === 'next'){
        handleNext();
      }
      if(player.gameState === 'lose' ){
        handleFailure();
      }
      player.setGameState('not ready');
    }
  }, [allReady]);

  
  useEffect(() => {
    checkGuessPlayer();
  }, [player.gameState]);
    
    
  const handleSuccess = async () => {
    setShowSuccessAnimation(true);
    setTimeout(() => {setShowSuccessAnimation(false); }, 1000); // Masquer l'animation après 1 seconde
  };
  
  const handleNext = async () => {
    setShowNextAnimation(true);
    setTimeout(() => { setShowNextAnimation(false); }, 1000); // Masquer l'animation après 1 seconde
  };

  const handleFailure = async () => {
    setShowFailureAnimation(true);
    setTimeout(() => {setShowFailureAnimation(false); }, 1000); // Masquer l'animation après 1 seconde
  };

  const handleNextButtonClick =  () => {
    player.makeGuess(-1,-1);
  };
  
  const handleConfirmButtonClick =  () => {
    player.makeGuess(player.guessChapter,player.guessVerse);
  };


  const handleChapterSelect = (event: React.ChangeEvent<HTMLSelectElement>) => {
    const selectedChapterId = parseInt(event.target.value);
    //setChapter(player,selectedChapterId);
    player.setGuessChapter(selectedChapterId);
  };
  const handleVerseSelect = (event: React.ChangeEvent<HTMLSelectElement>) => {
    const selectedVerseId = parseInt(event.target.value);
    player.setGuessVerse(selectedVerseId);
  };


  return (
    <div>
      {replayAudio && (
      <button className="menu-button replay" onClick={replayAudio}>Replay </button>
      )}
      <button className="menu-button confirm" onClick={handleConfirmButtonClick}>Confirm</button>
      <br />
      <select id="chapterSelect" value={player.guessChapter} onChange={handleChapterSelect}>
        {chapters
          .filter((chapter) => minSurah <= chapter.id && chapter.id <= maxSurah)
          .map((chapter) => (
            <option key={chapter.id} value={chapter.id}>
              {chapter.name_simple}
            </option>
          ))}
      </select>
      {askVerse && (
        <select id="verseSelect" value={player.guessVerse} onChange={handleVerseSelect}>
          {player.guessChapter &&
            chapters
              .filter((chapter) => chapter.id === player.guessChapter)
              .map((chapter) =>
                [...Array(chapter.verses_count).keys()]
                  .filter((x, i) => (maxSurah !== player.guessChapter || i <= maxVerse) && (minSurah !== player.guessChapter || minVerse <= i))
                  .map((x, i) => (
                    <option key={x} value={x}>
                      {x + 1}
                    </option>
                  ))
              )}
        </select>
      )}

      <br />
      <button className="menu-button next" onClick={handleNextButtonClick}>Skip</button>

      {showSuccessAnimation && (
        <div className="success-animation">Bien jouej</div>
      )}

      {showFailureAnimation && (
        <div className="failure-animation"> Nope </div>
      )}
      {showNextAnimation && (
        <div className="next-animation">
          {chapters.filter((chapter) => chapter.id === player.correctChapter).map((chapter) => (chapter.name_simple))} {askVerse ? player.correctVerse + 1 : ""}
        </div>
      )}

    </div>
  );
};

export default InputGame;
