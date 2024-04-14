import React, { useState, useEffect } from 'react';



interface GameProps 
{

}


interface Chapter {
    id: number;
    name_simple: string;
    verses_count: number;
}

const GameModel = {
    chapters: [], // Tableau de chapitres
    confirmedChapter: null, // Chapitre confirmé
    confirmedVerse: 0, // Verset confirmé
    askVerse: false, // Demander le verset
    filterVerse: false, // Filtrer le verset
    numberOfAyat: 1, // Nombre d'ayat par défaut
    minSurah: 1, // Surah minimum
    maxSurah: 114, // Surah maximum
    minVerse: 0, // Verset minimum
    maxVerse: 286, // Verset maximum
    maximumVerse: 286, // Nombre maximum de versets
  };
  
  export default GameModel;