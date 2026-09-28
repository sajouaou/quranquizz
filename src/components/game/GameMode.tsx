import { SetStateAction } from "react";
import type { AudioPlayer } from "../../hooks/useAudioPlayer";
import { RECITERS, reciterLabel } from "../../lib/quranApi";
import { getPrefs, setPrefs } from "../../lib/prefs";
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
      case "Survie": {
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
      }
      default:
        break;
    }

}

export type SettingItem =
  | { type: "SECTION"; label: string }
  | { type: "SELECT"; label: string; hint?: string; condition?: boolean; value: number;
      data: { value: number; label: string }[]; set: (value: number) => void }
  | { type: "CHECKBOX"; label: string; hint?: string; condition?: boolean; value: boolean; set: (value: boolean) => void }
  | { type: "SLIDER"; label: string; min: number; max: number; step: number; value: number; set: (value: number) => void }
  | { type: "BUTTON"; label: string; condition?: boolean; color?: string; click: () => void };

const range = (from: number, to: number) => Array.from({ length: Math.max(0, to - from + 1) }, (_, i) => from + i);

export const getSettingsGameMode = (mode:string,
    players: PlayerProps[],showInput:boolean,game: GameProps, sendGameMessage: (arg0: any) => any,
chapters:Chapter[],audio:AudioPlayer): SettingItem[] => {
    const versesOf = (surah: number) => chapters.find((chapter) => chapter.id === surah)?.verses_count ?? 0;
    const surahLabel = (chapter: Chapter) => `${chapter.id}. ${chapter.name_simple}`;

    const nbAyatSettings: SettingItem = {type:"SELECT",
        label:"Nombre d'ayat récitées",
        hint:"Versets consécutifs joués à chaque manche",
        value:game.numberOfAyat,
        data:range(1, 20).map((x) =>({ value:x,label:`${x}` })),
        set:(value) => sendGameMessage({ content: `The number of ayat is set to ${value}`, action: 'setNumberOfAyat', type: 'GAMESETTING', value })
        };
    const chooseMinSurah: SettingItem = {type:"SELECT",
        label:"De la sourate",
        value:game.minSurah,
        data:chapters
            .filter((chapter) => chapter.id <= game.maxSurah)
            .map((x) =>({ value:x.id,label:surahLabel(x) })),
        set:(value) =>sendGameMessage({ content: `The minimum surah is set to ${value}`, action: 'setMinSurah', type: 'GAMESETTING', value })
        };
    const chooseMinVerse: SettingItem = {type:"SELECT",
        condition:game.filterVerse,
        label:"…à partir du verset",
        value:game.minVerse,
        data: range(0, versesOf(game.minSurah) - 1)
            .filter((x) => game.minSurah !== game.maxSurah || x <= game.maxVerse)
            .map((x) =>({ value:x,label:`${x+1}` })),
        set:(value) =>sendGameMessage({ content: `The minimum verse is set to ${value+1}`, action: 'setMinVerse', type: 'GAMESETTING', value })
        };
    const chooseMaxSurah: SettingItem = {type:"SELECT",
        label:"À la sourate",
        value:game.maxSurah,
        data:chapters
            .filter((chapter) => game.minSurah <= chapter.id)
            .map((x) =>({ value:x.id,label:surahLabel(x) })),
        set:(value) => sendGameMessage({ content: `The maximum surah is set to ${value}`, action: 'setMaxSurah', type: 'GAMESETTING', value })
        };
    const chooseMaxVerse: SettingItem = {type:"SELECT",
        condition:game.filterVerse,
        label:"…jusqu'au verset",
        value:game.maxVerse,
        data: range(0, versesOf(game.maxSurah) - 1)
            .filter((x) => game.minSurah !== game.maxSurah || game.minVerse  <= x)
            .map((x) =>({ value:x,label:`${x+1}` })),
        set:(value) =>sendGameMessage({ content: `The maximum verse is set to ${value+1}`, action: 'setMaxVerse', type: 'GAMESETTING', value })
        };

    const filterVerse: SettingItem = {type:"CHECKBOX",
        label:"Limiter aux versets",
        hint:"Choisir le premier et le dernier verset de la plage",
        value:game.filterVerse,
        set:(value) => sendGameMessage({ content: 'The verse filter is ' + (value ? 'enabled' : 'disabled'), action: 'setFilterVerse', type: 'GAMESETTING', value: value })
    };
    const askVerse: SettingItem = {type:"CHECKBOX",
        label:"Demander le verset",
        hint:"Il faut aussi trouver le numéro du verset",
        value:game.askVerse,
        set:(value) => sendGameMessage({ content: 'Asking verse for the answer is '+ (value ? 'enabled' : 'disabled'), action: 'setAskVerse', type: 'GAMESETTING', value: value })
        };
    const randomVerseDist: SettingItem = {type:"CHECKBOX",
        label:"Pondérer par nombre de versets",
        hint:"Les longues sourates tombent plus souvent",
        value:game.verseDistribution,
        set:(value) => sendGameMessage({ content: 'The verse ditribution is ' + (value ? 'enabled' : 'disabled'), action: 'setVerseDistribution', type: 'GAMESETTING', value: value })
    };
    const  limit: SettingItem = {type:"CHECKBOX",
        label:"Nombre de manches limité",
        value:game.isLimited,
        set:(value) => sendGameMessage({ content: (value ? 'The game is limited in rounds' : 'The game is endless'), action: 'setIsLimited', type: 'GAMESETTING', value: value })
    };
    const nbRound: SettingItem = {type:"SELECT",
        condition:game.isLimited,
        label:"Manches",
        value:game.round,
        data:range(1, 50).map((x) =>({ value:x,label:`${x}` })),
        set:(value) => sendGameMessage({ content: `The number of rounds is set to  ${value}`, action: 'setRound', type: 'GAMESETTING', value })
    };
    const skip: SettingItem = {type:"CHECKBOX",
        label:"Passer si tout le monde se trompe",
        value:game.isSkip,
        set:(value) => sendGameMessage({ content: 'Automatic skip if everyone has a wrong answer is ' + (value ? 'enabled' : 'disabled'), action: 'setIsSkip', type: 'GAMESETTING', value: value })
    };
    const showScore: SettingItem = {type:"CHECKBOX",
        label:"Afficher les scores",
        value:game.showScore,
        set:(value) => sendGameMessage({ content: (value ? 'Scores are visible' : 'Scores are not visible'), action: 'setShowScore', type: 'GAMESETTING', value: value })
    };
    const activeLive: SettingItem = {type:"CHECKBOX",
        label:"Mode vies",
        value:game.activeLive,
        set:(value) => sendGameMessage({ content: 'The survival mode is ' + (value ? 'enabled' : 'disabled'), action: 'setActiveLive', type: 'GAMESETTING', value: value })
        };
    const nbLive: SettingItem = {type:"SELECT",
        condition:game.activeLive,
        label:"Vies",
        value:game.lives,
        data:range(1, 50).map((x) =>({ value:x,label:`${x}` })),
        set:(value) => sendGameMessage({ content: `The number of lives is set to ${value}`, action: 'setLives', type: 'GAMESETTING', value })
        };
    const showScoreSetting: SettingItem = { type:"BUTTON",
        condition:game.showScore,
        label:"Remettre les scores à zéro",
        color:"medium",
        click:() => sendGameMessage({ content: 'Scores are reset', action: 'resetScore', type: 'PLAYER'})
        };

    // Personal settings: stored on this device only, never sent to the other players.
    const reciter: SettingItem = { type: "SELECT",
        label:"Récitateur",
        value:getPrefs().reciterId,
        data:RECITERS.map((r) => ({ value: r.id, label: reciterLabel(r) })),
        set:(value) => setPrefs({ reciterId: value })
        };
    const volume: SettingItem = { type: "SLIDER",
        label:"Volume",
        min:0,
        max:1,
        step:0.05,
        value:audio.volume,
        set:(value) => audio.setVolume(value)
        };
    const personal: SettingItem[] = [{ type: "SECTION", label: "Audio (sur cet appareil)" }, reciter, volume];

    const selection: SettingItem[] = [
        { type: "SECTION", label: "Sélection des versets" },
        chooseMinSurah, chooseMaxSurah, filterVerse, chooseMinVerse, chooseMaxVerse,
        nbAyatSettings, randomVerseDist,
    ];

    if (mode === "Training" || (mode === "Online" && players[0].isHost  && !showInput)) {
        return [
            ...selection,
            { type: "SECTION", label: "Règles" },
            askVerse, limit, nbRound, skip, showScore, activeLive, nbLive, showScoreSetting,
            ...personal,
        ];
    }
    if (!showInput) {
        switch(mode){
            case "Arcade":
                return [...selection, { type: "SECTION", label: "Règles" }, askVerse, ...personal];
            case "Survie":
                return [...selection, { type: "SECTION", label: "Règles" }, askVerse, nbLive, ...personal];
            default:
                break;
        }
    }
    return personal;
}
