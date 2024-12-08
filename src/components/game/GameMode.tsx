import { SetStateAction } from "react";
import AudioSection from "../user/AudioSection";
import { Chapter, GameProps } from "./Game";
import { PlayerProps } from "./Player";



export const setGameMode = (mode:string,setGame: (arg0: (prevState: any) => any) => void,
setPlayers:{ (value: SetStateAction<PlayerProps[]>): void; (arg0: any[]): void; }, players: PlayerProps[]) => {
    switch(mode){
      case "Arcade":
        setGame((prevState: any) => ({ ...prevState, 
          round: 10,
          showScore: true,
          isLimited:true,
          isSkip: true 
        }));
        break;
      case "Survie": 
        setGame((prevState: any) => ({ ...prevState, 
            activeLive: true,
            lives: 3,
            showScore: true,
            isSkip: true 
        }));
        const updatedPlayers = players.map(player => ({
            ...player,
            showLives: true,
            lives:3
        }));
        // Mettre à jour l'état des joueurs avec la nouvelle liste mise à jour
        setPlayers(updatedPlayers);
        break;
      default:
        break;
    }

}

export const getSettingsGameMode = (mode:string,
    players: PlayerProps[],showInput:boolean,game: GameProps, sendGameMessage: (arg0: any) => any,
chapters:Chapter[],audioSection:AudioSection,handleSaveSettings: any) => {
    let res: any[] = [];
    const nbAyatSettings = {type:"SELECT",
        condition:true,
        label:"Number of Ayat :",
        value:game.numberOfAyat,
        data:[...Array(286).keys()]
            .map((x,i) =>({ id:x,value:x+1,label:x+1  })),
        set:(event: React.ChangeEvent<HTMLSelectElement>) => sendGameMessage({ content: `The number of ayat is set to ${parseInt(event.target.value)}`, action: 'setNumberOfAyat', type: 'GAMESETTING', value: parseInt(event.target.value) })
        };
    const chooseMinSurah = {type:"SELECT",
        condition:true,
        label:"Minimum Surah:",
        value:game.minSurah,
        data:chapters
            .filter((chapter) => chapter.id <= game.maxSurah)
            .map((x,i) =>({ id:x.id,value:x.id,label:x.name_simple  })),
        set:(event: React.ChangeEvent<HTMLSelectElement>) =>sendGameMessage({ content: `The minimum surah is set to ${parseInt(event.target.value) }`, action: 'setMinSurah', type: 'GAMESETTING', value: parseInt(event.target.value)  })
        };
    const chooseMinVerse = {type:"SELECT",
        condition:game.filterVerse,
        notNext:true,
        value:game.minVerse,
        data: [...Array(chapters
                        .filter((chapter) => chapter.id === game.minSurah)[0].verses_count).keys()
            ]
            .filter((x) => game.minSurah !== game.maxSurah || x <= game.maxVerse)
            .map((x,i) =>({ id:x,value:x,label:x+1  })) 
        ,
        set:(event: React.ChangeEvent<HTMLSelectElement>) =>sendGameMessage({ content: `The minimum verse is set to ${parseInt(event.target.value)+1}`, action: 'setMinVerse', type: 'GAMESETTING', value: parseInt(event.target.value) })
        };
    const chooseMaxSurah = {type:"SELECT",
        condition:true,
        label:"Maximum Surah:",
        value:game.maxSurah,
        data:chapters
            .filter((chapter) => game.minSurah <= chapter.id)
            .map((x,i) =>({ id:x.id,value:x.id,label:x.name_simple  })),
        set:(event: React.ChangeEvent<HTMLSelectElement>) => sendGameMessage({ content: `The maximum surah is set to ${parseInt(event.target.value)}`, action: 'setMaxSurah', type: 'GAMESETTING', value: parseInt(event.target.value) })  
        };
    const chooseMaxVerse = {type:"SELECT",
        condition:game.filterVerse,
        notNext:true,
        value:game.maxVerse,
        data: [...Array(chapters
                        .filter((chapter) => chapter.id === game.maxSurah)[0].verses_count).keys()
            ]
            .filter((x) => game.minSurah !== game.maxSurah || game.minVerse  <= x)
            .map((x,i) =>({ id:x,value:x,label:x+1  })) 
        ,
        set:(event: React.ChangeEvent<HTMLSelectElement>) =>sendGameMessage({ content: `The maximum verse is set to ${parseInt(event.target.value)+1}`, action: 'setMaxVerse', type: 'GAMESETTING', value: parseInt(event.target.value) })
        };

    const filterVerse = {type:"CHECKBOX",
        label:"Filter Verses:",
        value:game.filterVerse,
        set:(value: boolean) => sendGameMessage({ content: 'The verse filter is ' + (value ? 'enabled' : 'disabled'), action: 'setFilterVerse', type: 'GAMESETTING', value: value })
    };

    const askVerse = {type:"CHECKBOX",
        label:"Ask Verses:",
        value:game.askVerse,
        set:(value: boolean) => sendGameMessage({ content: 'Asking verse for the answer is '+ (value ? 'enabled' : 'disabled'), action: 'setAskVerse', type: 'GAMESETTING', value: value })
        };
    const randomVerseDist = {type:"CHECKBOX",
        label:"Random Verses Distribution:",
        value:game.verseDistribution,
        set:(value: boolean) => sendGameMessage({ content: 'The verse ditribution is ' + (value ? 'enabled' : 'disabled'), action: 'setVerseDistribution', type: 'GAMESETTING', value: value })
    };
    const  limit = {type:"CHECKBOX",
        label:"Limit :",
        value:game.isLimited,
        set:(value: boolean) => sendGameMessage({ content: (value ? 'The game is limited in rounds' : 'The game is endless'), action: 'setIsLimited', type: 'GAMESETTING', value: value })
    };
    const nbRound = {type:"SELECT",
        condition:game.isLimited,
        label:"Number of Round :",
        value:game.round,
        data:[...Array(50).keys()]
        .map((x,i) =>({ id:x,value:x+1,label:x+1  })),
        set:(event: React.ChangeEvent<HTMLSelectElement>) => sendGameMessage({ content: `The number of rounds is set to  ${parseInt(event.target.value)}`, action: 'setRound', type: 'GAMESETTING', value: parseInt(event.target.value) })
    };

    const skip = {type:"CHECKBOX",
        label:"Skip if fail :",
        value:game.isSkip,
        set:(value: boolean) => sendGameMessage({ content: 'Automatic skip if everyone has a wrong answer is ' + (value ? 'enabled' : 'disabled'), action: 'setIsSkip', type: 'GAMESETTING', value: value })
    };

    const showScore = {type:"CHECKBOX",
    label:"Show Score :",
    value:game.showScore,
    set:(value: boolean) => sendGameMessage({ content: (value ? 'Scores are visible' : 'Scores are not visible'), action: 'setShowScore', type: 'GAMESETTING', value: value })
    };
    const activeLive = {type:"CHECKBOX",
        label:"Active Lives :",
        value:game.activeLive,
        set:(value: boolean) => sendGameMessage({ content: 'The survival mode is ' + (value ? 'enabled' : 'disabled'), action: 'setActiveLive', type: 'GAMESETTING', value: value })
        };

    const nbLive = {type:"SELECT",
        condition:game.activeLive,
        label:"Number of Lives :",
        value:game.lives,
        data:[...Array(50).keys()]
        .map((x,i) =>({ id:x,value:x+1,label:x+1  })),
        set:(event: React.ChangeEvent<HTMLSelectElement>) => sendGameMessage({ content: `The number of lives is set to ${parseInt(event.target.value)}`, action: 'setLives', type: 'GAMESETTING', value: parseInt(event.target.value) })
        };

    const showScoreSetting = { type:"BUTTON",
        condition:game.showScore,
        label:"Reset Score",
        class:"menu-button settings",
        click:() => sendGameMessage({ content: 'Scores are reset', action: 'resetScore', type: 'PLAYER'})
        };
    const audioSliderSetting = { type: "SLIDER",
        label:"Volume:",
        min:"0",
        max:"1",
        step:"0.01",
        value:audioSection.volume,
        set:(event: React.ChangeEvent<HTMLInputElement>) => {audioSection.setVolumeAudio(parseFloat(event.target.value))}
        };

    const saveButton = { type:"BUTTON",
        condition:true,
        label:"Save",
        class:"menu-button settings",
        click:handleSaveSettings
        };

    if (mode === "Training" || (mode === "Online" && players[0].isHost  && !showInput)) {
        res.push(
            nbAyatSettings,
            chooseMinSurah,
            chooseMinVerse,
            chooseMaxSurah,
            chooseMaxVerse,
            filterVerse,
            askVerse,
            randomVerseDist,
            limit,
            nbRound,
            skip,
            showScore,
            activeLive,
            nbLive,
            showScoreSetting,
            audioSliderSetting,
            saveButton
        );
    }
    else if ((!showInput)){
        switch(mode){
            case "Arcade":
                res.push(
                    nbAyatSettings,
                    chooseMinSurah,
                    chooseMinVerse,
                    chooseMaxSurah,
                    chooseMaxVerse,
                    filterVerse,
                    askVerse,
                    randomVerseDist,
                    audioSliderSetting,
                    saveButton
                );
                break;
            case "Survie":
                res.push(
                    nbAyatSettings,
                    chooseMinSurah,
                    chooseMinVerse,
                    chooseMaxSurah,
                    chooseMaxVerse,
                    filterVerse,
                    askVerse,
                    randomVerseDist,
                    nbLive,
                    audioSliderSetting,
                    saveButton
                );
                break;
            default:
                res.push(
                    audioSliderSetting,
                    saveButton
                );
                break;

        }
    }
    else {
        res.push(
            audioSliderSetting,
            saveButton
        );
    }
    return res;
}

