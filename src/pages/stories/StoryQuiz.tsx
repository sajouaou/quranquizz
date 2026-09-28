import {
  IonBackButton, IonButton, IonButtons, IonContent, IonHeader, IonIcon, IonPage, IonTitle, IonToolbar, useIonRouter,
} from '@ionic/react';
import { checkmarkCircle, closeCircle, refresh } from 'ionicons/icons';
import { useEffect, useMemo, useState } from 'react';
import { STORIES, Story } from '../../data/stories';
import { useAudioPlayer } from '../../hooks/useAudioPlayer';
import AudioPanel from '../../components/user/AudioPanel';
import { recordScore } from '../../lib/stats';
import { vibrateResult } from '../../lib/feedback';
import { StoryName } from './StoriesHome';
import './Stories.css';

const ROUNDS = 10;

export interface QuizQuestion {
  story: Story;
  ayah: number;
  choices: Story[];
}

const shuffle = <T,>(items: T[], random: () => number) => {
  const copy = [...items];
  for (let i = copy.length - 1; i > 0; i--) {
    const j = Math.floor(random() * (i + 1));
    [copy[i], copy[j]] = [copy[j], copy[i]];
  }
  return copy;
};

// Each question: an ayah of one story, and 4 stories to choose from.
export function buildQuiz(rounds = ROUNDS, random = Math.random): QuizQuestion[] {
  const order = shuffle(STORIES, random);
  return Array.from({ length: rounds }, (_, i) => {
    const story = order[i % order.length];
    const ayah = story.from + Math.floor(random() * (story.to - story.from + 1));
    const others = shuffle(STORIES.filter((s) => s.id !== story.id), random).slice(0, 3);
    return { story, ayah, choices: shuffle([story, ...others], random) };
  });
}

const StoryQuiz: React.FC = () => {
  const router = useIonRouter();
  const audio = useAudioPlayer();
  const [attempt, setAttempt] = useState(0);
  const quiz = useMemo(() => buildQuiz(), [attempt]);
  const [round, setRound] = useState(0);
  const [picked, setPicked] = useState<string | null>(null);
  const [score, setScore] = useState(0);
  const [record, setRecord] = useState<{ best: number; isRecord: boolean } | null>(null);

  const question = quiz[round];
  useEffect(() => {
    if (!question) return;
    setPicked(null);
    audio.load(question.story.surah, question.ayah - 1, 1);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [round, quiz]);

  const choose = (story: Story) => {
    if (picked) return;
    setPicked(story.id);
    const right = story.id === question.story.id;
    if (right) setScore((s) => s + 1);
    vibrateResult(right ? 'win' : 'lose');
  };

  const next = () => {
    if (round + 1 >= quiz.length) {
      audio.stop();
      setRecord(recordScore('Qasas', score));
    }
    setRound(round + 1);
  };

  const restart = () => {
    setScore(0);
    setRecord(null);
    setRound(0);
    setAttempt((a) => a + 1);
  };

  return (
    <IonPage>
      <IonHeader>
        <IonToolbar>
          <IonButtons slot="start"><IonBackButton defaultHref="/stories" text="" /></IonButtons>
          <IonTitle>Quel récit ?</IonTitle>
        </IonToolbar>
      </IonHeader>
      <IonContent className="stories-content">
        <div className="stories">
          {question && (
            <>
              <p className="round-counter">Question {round + 1} / {quiz.length} · {score} bonne{score > 1 ? 's' : ''} réponse{score > 1 ? 's' : ''}</p>
              <AudioPanel audio={audio} />
              <section className="card quiz">
                <p className="question">De quel récit provient cette ayah ?</p>
                <div className="choices">
                  {question.choices.map((story) => {
                    const state = !picked ? '' : story.id === question.story.id ? 'right' : story.id === picked ? 'wrong' : 'dim';
                    return (
                      <button key={story.id} type="button" className={`choice ${state}`} disabled={!!picked} onClick={() => choose(story)}>
                        <StoryName story={story} />
                        {state === 'right' && <IonIcon icon={checkmarkCircle} />}
                        {state === 'wrong' && <IonIcon icon={closeCircle} />}
                      </button>
                    );
                  })}
                </div>
                {picked && (
                  <>
                    <p className="quiz-answer">
                      Ayah {question.story.surah}:{question.ayah} — <button type="button" className="link"
                        onClick={() => router.push(`/stories/${question.story.id}`)}>découvrir ce récit</button>
                    </p>
                    <IonButton expand="block" onClick={next}>{round + 1 >= quiz.length ? 'Voir le résultat' : 'Question suivante'}</IonButton>
                  </>
                )}
              </section>
            </>
          )}
          {!question && (
            <section className="card end-screen">
              <h2>Défi terminé</h2>
              <p className="end-score"><strong>{score}</strong> / {quiz.length}</p>
              {record?.isRecord && <p className="end-record">Nouveau record !</p>}
              {record && !record.isRecord && record.best > 0 && <p className="end-best">Record : {record.best}</p>}
              <div className="end-actions">
                <IonButton expand="block" onClick={restart}><IonIcon slot="start" icon={refresh} />Rejouer</IonButton>
                <IonButton expand="block" fill="outline" onClick={() => router.goBack()}>Retour aux récits</IonButton>
              </div>
            </section>
          )}
        </div>
      </IonContent>
    </IonPage>
  );
};

export default StoryQuiz;
