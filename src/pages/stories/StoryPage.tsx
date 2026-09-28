import {
  IonBackButton, IonButton, IonButtons, IonContent, IonHeader, IonIcon, IonPage, IonProgressBar, IonSpinner,
  IonTitle, IonToolbar, useIonRouter,
} from '@ionic/react';
import { pause, play, playSkipBack, playSkipForward, trophy } from 'ionicons/icons';
import { useEffect, useState } from 'react';
import { Redirect, useParams } from 'react-router-dom';
import { findStory, storyLength } from '../../data/stories';
import { useAudioPlayer } from '../../hooks/useAudioPlayer';
import { useChapters } from '../../hooks/useChapters';
import { usePrefs } from '../../lib/prefs';
import { findReciter, reciterLabel } from '../../lib/quranApi';
import { markListened, useStoryProgress } from '../../lib/storyProgress';
import { PersonName, Stars, StoryName } from './StoriesHome';
import './Stories.css';

const StoryPage: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const story = findStory(id);
  const router = useIonRouter();
  const chapters = useChapters();
  const audio = useAudioPlayer();
  const progress = useStoryProgress();
  const { reciterId } = usePrefs();
  // Index (0-based) of the first ayah of the sequence currently loaded in the player.
  const [start, setStart] = useState<number | null>(null);

  const absolute = start !== null ? start + audio.current + 1 : null; // ayah number being recited
  useEffect(() => {
    if (story && audio.status === 'ended' && absolute === story.to) markListened(story.id);
  }, [audio.status, absolute, story]);

  if (!story) return <Redirect to="/stories" />;
  const chapter = chapters.find((c) => c.id === story.surah);
  const length = storyLength(story);

  const playFrom = (ayah: number) => {
    const clamped = Math.min(Math.max(ayah, story.from), story.to);
    setStart(clamped - 1);
    audio.load(story.surah, clamped - 1, story.to - clamped + 1);
  };

  const toggle = () => {
    if (audio.status === 'playing') audio.pause();
    else if (audio.status === 'paused') audio.resume();
    else if (absolute !== null && audio.status !== 'ended') audio.replay();
    else playFrom(story.from);
  };

  const listening = start !== null && audio.status !== 'idle';
  const position = absolute !== null ? absolute - story.from + 1 : 0;

  return (
    <IonPage>
      <IonHeader>
        <IonToolbar>
          <IonButtons slot="start"><IonBackButton defaultHref="/stories" text="" /></IonButtons>
          <IonTitle>{story.person ?? 'Récit'}</IonTitle>
        </IonToolbar>
      </IonHeader>
      <IonContent className="stories-content">
        <div className="stories">
          <header className="story-header">
            {chapter?.name_arabic && <p className="arabic story-surah-ar" lang="ar">{chapter.name_arabic}</p>}
            <h1><StoryName story={story} /></h1>
            <p><PersonName story={story} /></p>
            <p className="story-ref">
              Sourate {chapter?.name_simple ?? story.surah} ({story.surah}), versets {story.from} à {story.to} · {length} ayat
            </p>
            <Stars count={progress[story.id]?.stars ?? 0} />
          </header>

          <section className="card story-summary">
            <h3>Le récit</h3>
            <p>{story.summary}</p>
          </section>

          <section className="card story-lesson">
            <h3>À méditer</h3>
            <blockquote>« {story.lesson.meaning} »</blockquote>
            <p className="lesson-ref">Sens approximatif de {story.lesson.ref}</p>
          </section>

          <section className="card story-player">
            <h3>Écouter le récit</h3>
            <p className="adab">« Et quand le Coran est récité, écoutez-le attentivement et faites silence, afin qu'il vous soit fait miséricorde. » <small>(sens de 7:204)</small></p>
            <div className="player-controls">
              <IonButton fill="clear" aria-label="Ayah précédente" disabled={!listening || (absolute ?? 0) <= story.from}
                onClick={() => absolute && playFrom(absolute - 1)}>
                <IonIcon slot="icon-only" icon={playSkipBack} />
              </IonButton>
              <button type="button" className="audio-button" onClick={toggle}
                aria-label={audio.status === 'playing' ? 'Pause' : 'Écouter'}>
                {audio.status === 'loading' ? <IonSpinner name="crescent" /> : <IonIcon icon={audio.status === 'playing' ? pause : play} />}
              </button>
              <IonButton fill="clear" aria-label="Ayah suivante" disabled={!listening || (absolute ?? story.to) >= story.to}
                onClick={() => absolute && playFrom(absolute + 1)}>
                <IonIcon slot="icon-only" icon={playSkipForward} />
              </IonButton>
            </div>
            {listening && (
              <>
                <IonProgressBar value={position / length} />
                <p className="player-position">
                  {audio.status === 'error' ? 'Audio indisponible — réessaie' : `Ayah ${absolute} · ${position} / ${length}`}
                </p>
              </>
            )}
            <p className="player-reciter">{reciterLabel(findReciter(reciterId))}</p>
          </section>

          <IonButton expand="block" size="large" className="challenge-button"
            onClick={() => { audio.stop(); router.push(`/stories/${story.id}/defi`); }}>
            <IonIcon slot="start" icon={trophy} />
            Défi : situe l'ayah dans le récit
          </IonButton>
        </div>
      </IonContent>
    </IonPage>
  );
};

export default StoryPage;
