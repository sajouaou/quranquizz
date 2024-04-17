

// Fonction pour générer un numéro de chapitre aléatoire
export function getRandomChapterNumber(game, chapters) {
    let res = Math.floor(Math.random() * (game.maxSurah - game.minSurah + 1)) + game.minSurah;
    if (game.verseDistribution) {
      let chapterArrays = [];
      chapters
        .filter(function (chapter) {
          return chapter.id <= game.maxSurah && chapter.id >= game.minSurah;
        })
        .forEach((chapter) => {
          let length = chapter.verses_count;
          if (chapter.id === game.maxSurah && game.filterVerse) {
            length = game.maxVerse;
          }
          if (chapter.id === game.minSurah && game.filterVerse) {
            length = length - game.minVerse;
          }
          const array = Array.from({ length: length }, () => chapter.id);
          chapterArrays.push(...array);
        });
      res = Math.floor(Math.random() * chapterArrays.length);
      res = chapterArrays[res];
    }
    return res;
  }
  
  // Fonction pour générer un numéro de verset aléatoire
  export function getRandomVerseNumber(game, chapters, chapterId) {
    let maxtemp = chapters.filter(function (chapter) {
      return chapter.id === chapterId;
    })[0].verses_count;
    if (game.filterVerse && chapterId === game.maxSurah && game.maxVerse + 1 <= maxtemp) {
      maxtemp = game.maxVerse + 1;
    }
    let minimumVerse = 0;
    if (game.filterVerse && chapterId === game.minSurah && game.minVerse <= maxtemp) {
      minimumVerse = game.minVerse;
    }
    let verse = Math.floor(Math.random() * maxtemp) + minimumVerse;
    if (verse + game.numberOfAyat >= maxtemp) {
      verse = maxtemp - game.numberOfAyat;
      if (verse < minimumVerse) {
        verse = minimumVerse;
      }
    }
    return {verse, maxtemp};
  }

  export function  checkChoice(game,chapterId:number| null,verseId:number| null) : boolean {
    const found = chapterId === game.confirmedChapter && (verseId === game.confirmedVerse || !game.askVerse);
    return found;
  }

  export const setConfirmedChapter = (setGame, value: number | null) => {
    setGame(prevState => ({ ...prevState, confirmedChapter: value }));
  };
  
  export const setConfirmedVerse = (setGame, value: number) => {
    setGame(prevState => ({ ...prevState, confirmedVerse: value }));
  };

  export const setPreviousChapter = (setGame, value: number | null) => {
    setGame(prevState => ({ ...prevState, previousChapter: value }));
  };
  
  export const setPreviousVerse = (setGame, value: number) => {
    setGame(prevState => ({ ...prevState, previousVerse: value }));
  };
  
  export const setAskVerse = (setGame, value: boolean) => {
    setGame(prevState => ({ ...prevState, askVerse: value }));
  };
  
  export const setFilterVerse = (setGame, value: boolean) => {
    setGame(prevState => ({ ...prevState, filterVerse: value }));
  };
  
  export const setVerseDistribution = (setGame, value: boolean) => {
    setGame(prevState => ({ ...prevState, verseDistribution: value }));
  };
  
  export const setNumberOfAyat = (setGame, value: number) => {
    setGame(prevState => ({ ...prevState, numberOfAyat: value }));
  };
  
  export const setMinSurah = (setGame, value: number) => {
    setGame(prevState => ({ ...prevState, minSurah: value }));
  };
  
  export const setMaxSurah = (setGame, value: number) => {
    setGame(prevState => ({ ...prevState, maxSurah: value }));
  };
  
  export const setMinVerse = (setGame, value: number) => {
    setGame(prevState => ({ ...prevState, minVerse: value }));
  };
  
  export const setMaxVerse = (setGame, value: number) => {
    setGame(prevState => ({ ...prevState, maxVerse: value }));
  };
  
  export const setMaximumVerse = (setGame, value: number) => {
    setGame(prevState => ({ ...prevState, maximumVerse: value }));
  };
  
  export const setIsLimited = (setGame, value: boolean) => {
    setGame(prevState => ({ ...prevState, isLimited: value }));
  };
  
  export const setIsSkip = (setGame, value: boolean) => {
    setGame(prevState => ({ ...prevState, isSkip: value }));
  };
  
  export const setRound = (setGame, value: number) => {
    setGame(prevState => ({ ...prevState, round: value }));
  };
  
  export const setCurrentRound = (setGame, value: number) => {
    setGame(prevState => ({ ...prevState, currentRound: value }));
  };
  
  export const setActiveLive = (setGame, value: boolean) => {
    setGame(prevState => ({ ...prevState, activeLive: value }));
  };
  
  export const setLives = (setGame, value: number) => {
    setGame(prevState => ({ ...prevState, lives: value }));
  };
  
  export const setShowScore = (setGame, value: boolean) => {
    setGame(prevState => ({ ...prevState, showScore: value }));
  };
  
  export const setAllPReady = (setGame, value: boolean) => {
    setGame(prevState => ({ ...prevState, allPReady: value }));
  };


  export const recvGameSettingMSG = (message,setGame) => {
    const { action, value } =  message;
    switch (action) {
      case "update":
        setGame(value);
        break;
      case "setNumberOfAyat":
        setNumberOfAyat(setGame,value);
        break;
      case "setMinSurah":
        setMinSurah(setGame,value);
        break;
      case "setMaxSurah":
        setMaxSurah(setGame,value);
        break;
      case "setMinVerse":
        setMinVerse(setGame,value);
        break;
      case "setMaxVerse":
        setMaxVerse(setGame,value);
        break;
      case "setMaximumVerse":
        setMaximumVerse(setGame,value);
        break;
      case "setIsLimited":
        setIsLimited(setGame,value);
        break;
      case "setIsSkip":
        setIsSkip(setGame,value);
        break;
      case "setRound":
        setRound(setGame,value);
        break;
      case "setCurrentRound":
        setCurrentRound(setGame,value);
        break;
      case "setAllPReady":
        setAllPReady(setGame,value);
        break;
      case "setAskVerse":
        setAskVerse(setGame,value);
        break;
      case "setFilterVerse":
        setFilterVerse(setGame,value);
        break;
      case "setVerseDistribution":
        setVerseDistribution(setGame,value);
        break;
      default:
        break;
    }
}
  

  
