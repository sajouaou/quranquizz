

// Fonction pour générer un numéro de chapitre aléatoire
export function getRandomChapterNumber(game:any, chapters: any[]) {
    let res = Math.floor(Math.random() * (game.maxSurah - game.minSurah + 1)) + game.minSurah;
    if (game.verseDistribution) {
      let chapterArrays: any[] = [];
      chapters
        .filter(function (chapter: { id: number; }) {
          return chapter.id <= game.maxSurah && chapter.id >= game.minSurah;
        })
        .forEach((chapter: { verses_count: any; id: any; }) => {
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
  export function getRandomVerseNumber(game:any, chapters: any[], chapterId: any) {
    let maxtemp = chapters.filter(function (chapter: { id: any; }) {
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

  export function  checkChoice(game:any,chapterId:number| null,verseId:number| null) : boolean {
    const found = chapterId === game.confirmedChapter && (verseId === game.confirmedVerse || !game.askVerse);
    return found;
  }

  export const setConfirmedChapter = (setGame: (arg0: (prevState: any) => any) => void, value: number | null) => {
    setGame((prevState: any) => ({ ...prevState, confirmedChapter: value }));
  };
  
  export const setConfirmedVerse = (setGame: (arg0: (prevState: any) => any) => void, value: number) => {
    setGame((prevState: any) => ({ ...prevState, confirmedVerse: value }));
  };

  export const setPreviousChapter = (setGame: (arg0: (prevState: any) => any) => void, value: number | null) => {
    setGame((prevState: any) => ({ ...prevState, previousChapter: value }));
  };
  
  export const setPreviousVerse = (setGame: (arg0: (prevState: any) => any) => void, value: number) => {
    setGame((prevState: any) => ({ ...prevState, previousVerse: value }));
  };
  
  export const setAskVerse = (setGame: (arg0: (prevState: any) => any) => void, value: boolean) => {
    setGame((prevState: any) => ({ ...prevState, askVerse: value }));
  };
  
  export const setFilterVerse = (setGame: (arg0: (prevState: any) => any) => void, value: boolean) => {
    setGame((prevState: any) => ({ ...prevState, filterVerse: value }));
  };
  
  export const setVerseDistribution = (setGame: (arg0: (prevState: any) => any) => void, value: boolean) => {
    setGame((prevState: any) => ({ ...prevState, verseDistribution: value }));
  };
  
  export const setNumberOfAyat = (setGame: (arg0: (prevState: any) => any) => void, value: number) => {
    setGame((prevState: any) => ({ ...prevState, numberOfAyat: value }));
  };
  
  export const setMinSurah = (setGame: (arg0: (prevState: any) => any) => void, value: number) => {
    setGame((prevState: any) => ({ ...prevState, minSurah: value }));
  };
  
  export const setMaxSurah = (setGame: (arg0: (prevState: any) => any) => void, value: number) => {
    setGame((prevState: any) => ({ ...prevState, maxSurah: value }));
  };
  
  export const setMinVerse = (setGame: (arg0: (prevState: any) => any) => void, value: number) => {
    setGame((prevState: any) => ({ ...prevState, minVerse: value }));
  };
  
  export const setMaxVerse = (setGame: (arg0: (prevState: any) => any) => void, value: number) => {
    setGame((prevState: any) => ({ ...prevState, maxVerse: value }));
  };
  
  export const setMaximumVerse = (setGame: (arg0: (prevState: any) => any) => void, value: number) => {
    setGame((prevState: any) => ({ ...prevState, maximumVerse: value }));
  };
  
  export const setIsLimited = (setGame: (arg0: (prevState: any) => any) => void, value: boolean) => {
    setGame((prevState: any) => ({ ...prevState, isLimited: value }));
  };
  
  export const setIsSkip = (setGame: (arg0: (prevState: any) => any) => void, value: boolean) => {
    setGame((prevState: any) => ({ ...prevState, isSkip: value }));
  };
  
  export const setRound = (setGame: (arg0: (prevState: any) => any) => void, value: number) => {
    setGame((prevState: any) => ({ ...prevState, round: value }));
  };
  
  export const setCurrentRound = (setGame: (arg0: (prevState: any) => any) => void, value: number) => {
    setGame((prevState: any) => ({ ...prevState, currentRound: value }));
  };
  
  export const setActiveLive = (setGame: (arg0: (prevState: any) => any) => void, value: boolean) => {
    setGame((prevState: any) => ({ ...prevState, activeLive: value }));
  };
  
  export const setLives = (setGame: (arg0: (prevState: any) => any) => void, value: number) => {
    setGame((prevState: any) => ({ ...prevState, lives: value }));
  };
  
  export const setShowScore = (setGame: (arg0: (prevState: any) => any) => void, value: boolean) => {
    setGame((prevState: any) => ({ ...prevState, showScore: value }));
  };
  
  export const setAllPReady = (setGame: (arg0: (prevState: any) => any) => void, value: boolean) => {
    setGame((prevState: any) => ({ ...prevState, allPReady: value }));
  };


  export const recvGameSettingMSG = (message: { action: any; value: any; },setGame: (arg0: (prevState: any) => any) => void) => {
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
  

  
