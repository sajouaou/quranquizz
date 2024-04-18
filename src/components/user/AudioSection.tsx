import React, { Component, useState } from 'react';

interface AudioSectionProps {
  numberOfAyat: number;
  maximumVerse: number;
  confirmedVerse: string; // Ajoutez confirmedVerse au type de props
}


class AudioSection extends Component<AudioSectionProps> {
  [x: string]: any;
  constructor(props:any) {
    super(props);
    [this.volume, this.setVolume] = useState(0);
    [this.data, this.setData] = useState<Promise<any>>();
    [this.ayat, this.setAyat] = useState<number>(0);
    [this.audioFile, this.setAudioFile] = useState<string | null>(null);
    [this.isPlaying, this.setPlay] = useState(false);
    this.audioRef = React.createRef();
  }



  fetchAudioFile = async (chapterId: number,verse: number) => {
    try {
      const response = await fetch(`https://api.quran.com/api/v4/recitations/10/by_chapter/${chapterId}?per_page=286`);
      if (response.ok) {
        const data = await response.json();
        if (data.audio_files.length > 0) {
          this.setData( data );
          this.setPlay(false);
          this.setAyat(0);
          this.setAudioFile(data.audio_files[verse].url);
        } else {
          console.error('No audio file found for chapter:', chapterId);
        }
      } else {
        console.error('Failed to fetch audio file for chapter:', chapterId);
      }
    } catch (error) {
      console.error('Error fetching audio file:', error);
    }
  };

  playAudio = () => {
    const { numberOfAyat, maximumVerse,confirmedVerse } = this.props;
    if (this.audioFile && this.audioRef.current && !this.isPlaying) {
      this.setPlay(true);
      this.audioRef.current.src = `https://verses.quran.com/${this.audioFile}`;
      this.audioRef.current.volume = this.volume;
      this.audioRef.current.play();
      this.audioRef.current.onended = () => {
        if (this.ayat + 1 < numberOfAyat && this.ayat + 1 < maximumVerse) {
          this.setAyat(this.ayat + 1);
          this.setPlay(false);
          this.setAudioFile(this.data.audio_files[confirmedVerse+this.ayat+1].url);
        }
      };
    }
  };

  replayAudio = () => {
    const { confirmedVerse } = this.props;
    this.setAyat(0);
    this.setPlay(false);
    this.setAudioFile(this.data.audio_files[confirmedVerse].url);
    this.playAudio();
  };

  setVolumeAudio = (vol:number) => {
    this.setVolume(vol);
    if (this.audioRef.current) {
      this.audioRef.current.volume = vol;
    }
  };


  render() {
    return (
      <audio className="invisible" ref={this.audioRef} controls />
    );
  }
}

export default AudioSection;