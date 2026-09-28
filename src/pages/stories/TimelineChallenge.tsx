import {
  IonBackButton, IonButton, IonButtons, IonContent, IonHeader, IonIcon, IonPage, IonRange, IonTitle, IonToolbar,
  useIonRouter,
} from '@ionic/react';
import { checkmarkCircle, closeCircle, ellipseOutline, refresh } from 'ionicons/icons';
import { useEffect, useMemo, useState } from 'react';
import { Redirect, useParams } from 'react-router-dom';
import { Story, findStory, storyLength } from '../../data/stories';
import { useAudioPlayer } from '../../hooks/useAudioPlayer';
import AudioPanel from '../../components/user/AudioPanel';
import { recordStars, starsFor, timelinePoints } from '../../lib/storyProgress';
import { vibrateResult } from '../../lib/feedback';
import { Stars, StoryName, StoryRef } from './StoriesHome';
import './Stories.css';

const ROUNDS = 5;

// Ayat to place: distinct when the story is long enough.
export function pickAyat(story: Story, rounds = ROUNDS, random = Math.random): number[] {
  const pool = Array.from({ length: storyLength(story) }, (_, i) => story.from + i);
  const picked: number[] = [];
  while (picked.length < rounds) {
    if (pool.length === 0) pool.push(...Array.from({ length: storyLength(story) }, (_, i) => story.from + i));
    picked.push(pool.splice(Math.floor(random() * pool.length), 1)[0]);
  }
  return picked;
}

const TimelineChallenge: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const story = findStory(id);
  const router = useIonRouter();
  const audio = useAudioPlayer();
  const [attempt, setAttempt] = useState(0);
  const ayat = useMemo(() => (story ? pickAyat(story) : []), [story, attempt]);
  const [round, setRound] = useState(0);
  const [guess, setGuess] = useState(0);
  const [answered, setAnswered] = useState<number | null>(null); // points of the current round
  const [points, setPoints] = useState(0);
  const [result, setResult] = useState<{ stars: number; improved: boolean } | null>(null);

  const middle = story ? Math.round((story.from + story.to) / 2) : 0;
  useEffect(() => {
    if (!story || round >= ayat.length) return;
    setGuess(middle);
    setAnswered(null);
    audio.load(story.surah, ayat[round] - 1, 1);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [round, ayat]);

  if (!story) return <Redirect to="/stories" />;
  const length = storyLength(story);
  const actual = ayat[round];
  const finished = round >= ayat.length;

  const validate = () => {
    const p = timelinePoints(guess, actual, length);
    setAnswered(p);
    setPoints((total) => total + p);
    vibrateResult(p >= 2 ? 'win' : p === 1 ? 'next' : 'lose');
  };

  const next = () => {
    if (round + 1 >= ayat.length) {
      audio.stop();
      const stars = starsFor(points, ayat.length * 3);
      setResult({ stars, improved: recordStars(story.id, stars) });
    }
    setRound(round + 1);
  };

  const restart = () => {
    setPoints(0);
    setResult(null);
    setRound(0);
    setAttempt((a) => a + 1);
  };

  return (
    <IonPage>
      <IonHeader>
        <IonToolbar>
          <IonButtons slot="start"><IonBackButton defaultHref={`/stories/${story.id}`} text="" /></IonButtons>
          <IonTitle>Situe l'ayah</IonTitle>
        </IonToolbar>
      </IonHeader>
      <IonContent className="stories-content">
        <div className="stories">
          <p className="challenge-story"><StoryName story={story} /> · <StoryRef story={story} /></p>

          {!finished && (
            <>
              <p className="round-counter">Ayah {round + 1} / {ayat.length} · {points} pts</p>
              <AudioPanel audio={audio} />
              <section className="card timeline">
                <p className="question">À quel moment du récit se trouve cette ayah ?</p>
                <IonRange
                  min={story.from}
                  max={story.to}
                  step={1}
                  snaps={length <= 30}
                  ticks={length <= 30}
                  pin
                  pinFormatter={(v: number) => `v. ${v}`}
                  value={guess}
                  disabled={answered !== null}
                  onIonInput={(e) => setGuess(Number(e.detail.value))}
                  aria-label="Position de l'ayah dans le récit"
                >
                  <span slot="start">{story.from}</span>
                  <span slot="end">{story.to}</span>
                </IonRange>
                <p className="timeline-guess">Ta réponse : verset {guess}</p>
                {answered === null ? (
                  <IonButton expand="block" onClick={validate}>Valider</IonButton>
                ) : (
                  <>
                    <div className={`feedback ${answered >= 2 ? 'feedback-win' : answered === 1 ? 'feedback-next' : 'feedback-lose'}`}>
                      <IonIcon icon={answered >= 2 ? checkmarkCircle : answered === 1 ? ellipseOutline : closeCircle} />
                      <div>
                        <strong>{answered === 3 ? 'Exact !' : answered === 2 ? 'Tout près !' : answered === 1 ? 'Pas loin' : 'Trop loin'} (+{answered})</strong>
                        <span>C'était le verset {actual} ({story.surah}:{actual})</span>
                      </div>
                    </div>
                    <IonButton expand="block" onClick={next}>{round + 1 >= ayat.length ? 'Voir le résultat' : 'Ayah suivante'}</IonButton>
                  </>
                )}
              </section>
            </>
          )}

          {finished && result && (
            <section className="card end-screen">
              <h2>Défi terminé</h2>
              <p className="end-score"><strong>{points}</strong> points sur {ayat.length * 3}</p>
              <Stars count={result.stars} />
              {result.improved && <p className="end-record">Nouvelle meilleure note pour ce récit !</p>}
              <div className="end-actions">
                <IonButton expand="block" onClick={restart}><IonIcon slot="start" icon={refresh} />Recommencer</IonButton>
                <IonButton expand="block" fill="outline" onClick={() => router.goBack()}>Retour au récit</IonButton>
              </div>
            </section>
          )}
        </div>
      </IonContent>
    </IonPage>
  );
};

export default TimelineChallenge;
