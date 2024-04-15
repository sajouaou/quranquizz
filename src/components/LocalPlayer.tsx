import Player from '../components/Player';
import InputGame from './InputGame';

class LocalPlayer extends Player{
    constructor(props) {
      super(props);   
     console.log(this);
    }
    render(){
        return (
          <div className='control-container'>
            <InputGame
            replayAudio={this.props.replayAudio}
            chapters={this.props.chapters}
            minSurah={this.props.minSurah}
            maxSurah={this.props.maxSurah}
            askVerse={this.props.askVerse}
            maxVerse={this.props.maxVerse}
            minVerse={this.props.minVerse}
            allReady={this.props.allPReady}
            checkGuessPlayer={this.props.checkGuessPlayer }
            player={this}
            />
            {super.render()}
          </div>
        );
    }
}
export default LocalPlayer;