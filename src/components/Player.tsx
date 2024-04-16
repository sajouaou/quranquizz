import React, { Component, useState } from 'react';

class Player extends Component {
    constructor(props) {
        super(props);
        [this.playerName,this.setPlayerName] = useState(this.props.name);
        [this.guessChapter,this.setGuessChapter] = useState(1);
        [this.guessVerse,this.setGuessVerse] = useState(0);
        [this.streak, this.setStreak] = useState(0); //
        [this.ready, this.setReady] = useState(false); //
        [this.gameState, this.setGameState] = useState('not ready'); //
        [this.found, this.setFound] = useState(false); //
        [this.correctChapter, this.setCorrectChapter] = useState(-1); //
        [this.correctVerse, this.setCorrectVerse] = useState(-1); //
        //Score
        [this.showScore, this.setShowScore] = useState(false);
        [this.score, this.setScore] = useState(0); //       
        //Alive
        [this.showLives, this.setShowLive] = useState(false);
        [this.lives, this.setLives] = useState(1); // 
        
      }
  
      toJson(){
        const stateJson = {
            playerName: this.playerName,
            guessChapter: this.guessChapter,
            guessVerse: this.guessVerse,
            streak: this.streak,
            ready: this.ready,
            gameState: this.gameState,
            found: this.found,
            correctChapter: this.correctChapter,
            correctVerse: this.correctVerse,
            showScore: this.showScore,
            score: this.score,
            showLives: this.showLives,
            lives: this.lives
        };
        return JSON.stringify(stateJson);
      }

    fromJson(jsonString) {
        const stateJson = JSON.parse(jsonString);
        // Vous pouvez maintenant accéder aux propriétés de l'objet stateJson
        this.setPlayerName(stateJson.playerName);
        this.setGuessChapter(stateJson.guessChapter);
        this.setGuessVerse(stateJson.guessVerse);
        this.setStreak(stateJson.streak);
        this.setReady(stateJson.ready);
        this.setGameState(stateJson.gameState);
        this.setFound(stateJson.found);
        this.setCorrectChapter(stateJson.correctChapter);
        this.setCorrectVerse(stateJson.correctVerse);
        this.setShowScore(stateJson.showScore);
        this.setScore(stateJson.score);
        this.setShowLives(stateJson.showLives);
        this.setLives(stateJson.lives);
    }


    isAlive(){
        return !this.showLives || this.lives > 0;
    }

    makeGuess(chapterId:number| null,verseId:number| null){
        if(chapterId === -1){
            this.setGameState('next');
            this.setReady(true);
        }
        else {
            this.setGuessChapter(chapterId);
            this.setGuessVerse(verseId);
            this.setGameState('ready');
            this.setReady(true);
        }
    }

    resetScore(){
        this.setScore(0);
        this.setStreak(0);
    }
    correct(chapterId:number| null,verseId:number| null){
        this.setCorrectChapter(chapterId);
        this.setCorrectVerse(verseId);
    }

    success(){
        this.setReady(false);
        this.setGameState('win');
        this.setScore(this.score +1);
        this.setStreak(this.streak+1);
    }
    fail(){
        this.setReady(false);
        this.setGameState('lose');
        this.setStreak(0);
    }

    isReady(){
        return this.gameState === 'ready' ||  this.gameState === 'next';
    }


    setChapter(chapterId:number){
        this.setGuessChapter(chapterId);        
    }

    setVerse(verseId:number){
        this.setGuessVerse(verseId);   
    }
  
    render(){
        return (
            <div className='player'>
            <p>Player : {this.playerName}</p>
            <p>{this.gameState}</p>
            { this.showScore && (
                <>
              <p>Score: {this.score}</p>
              <p>Streak: {this.streak}</p>
              </>
            )
            }
            { this.showLives && (
                <>
              <p>Lives: {this.lives}</p>
              </>
            )
            }
            </div>
        );
    }
}

export default Player;