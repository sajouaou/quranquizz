import {
  IonBackButton, IonButtons, IonContent, IonHeader, IonIcon, IonPage, IonTitle, IonToolbar, useIonRouter,
} from '@ionic/react';
import { book, checkmarkCircle, headset, helpCircle, star, starOutline } from 'ionicons/icons';
import { STORIES, STORY_GROUPS, Story } from '../../data/stories';
import { useChapters } from '../../hooks/useChapters';
import { getBestScore } from '../../lib/stats';
import { useStoryProgress } from '../../lib/storyProgress';
import './Stories.css';

export const Stars: React.FC<{ count: number }> = ({ count }) => (
  <span className="stars" aria-label={`${count} étoile(s) sur 3`}>
    {[0, 1, 2].map((i) => <IonIcon key={i} icon={i < count ? star : starOutline} />)}
  </span>
);

export const StoryName: React.FC<{ story: Story }> = ({ story }) => <>{story.title}</>;

// The prophet's (or Maryam's) name followed by the honorific, isolated so Arabic
// text never reorders the surrounding French text.
export const PersonName: React.FC<{ story: Story }> = ({ story }) =>
  story.person ? (
    <span className="person">
      {story.person}
      {story.honorific && <> <bdi className="honorific arabic" lang="ar">{story.honorific}</bdi></>}
    </span>
  ) : null;

export const StoryRef: React.FC<{ story: Story }> = ({ story }) => (
  <bdi dir="ltr">{story.surah}:{story.from}–{story.to}</bdi>
);

const StoriesHome: React.FC = () => {
  const router = useIonRouter();
  const chapters = useChapters();
  const progress = useStoryProgress();
  const done = STORIES.filter((s) => progress[s.id]?.listened).length;
  const quizBest = getBestScore('Qasas');

  return (
    <IonPage>
      <IonHeader>
        <IonToolbar>
          <IonButtons slot="start"><IonBackButton defaultHref="/home" text="" /></IonButtons>
          <IonTitle>Récits du Coran</IonTitle>
        </IonToolbar>
      </IonHeader>
      <IonContent className="stories-content">
        <div className="stories">
          <section className="stories-intro card">
            <IonIcon icon={book} />
            <div>
              <p>
                « Nous te racontons le plus beau des récits » <small>(sens de 12:3)</small>. Écoute chaque récit
                récité, médite sa leçon, puis relève les défis.
              </p>
              <p className="stories-progress">{done} / {STORIES.length} récits écoutés</p>
            </div>
          </section>

          <button type="button" className="quiz-card" onClick={() => router.push('/quiz/recits')}>
            <IonIcon icon={helpCircle} />
            <span>
              <strong>Défi : quel récit ?</strong>
              <small>Écoute une ayah et retrouve de quel récit elle provient{quizBest !== null ? ` · record ${quizBest}/10` : ''}</small>
            </span>
          </button>

          {STORY_GROUPS.map((group) => (
            <section key={group.id} className="story-group">
              <h2>{group.title}</h2>
              <p className="group-subtitle">{group.subtitle}</p>
              <div className="story-list">
                {STORIES.filter((s) => s.group === group.id).map((story) => {
                  const p = progress[story.id];
                  const chapter = chapters.find((c) => c.id === story.surah);
                  return (
                    <button key={story.id} type="button" className="story-card" onClick={() => router.push(`/stories/${story.id}`)}>
                      <span className="story-title"><StoryName story={story} /></span>
                      <PersonName story={story} />
                      <span className="story-ref">
                        {chapter?.name_simple ?? `Sourate ${story.surah}`} · <StoryRef story={story} />
                      </span>
                      <span className="story-status">
                        {p?.listened
                          ? <span className="listened"><IonIcon icon={checkmarkCircle} /> écouté</span>
                          : <span className="not-listened"><IonIcon icon={headset} /> à écouter</span>}
                        <Stars count={p?.stars ?? 0} />
                      </span>
                    </button>
                  );
                })}
              </div>
            </section>
          ))}
          <p className="stories-note">
            Les résumés relatent le sens des versets ; pour approfondir, référez-vous au tafsir et aux savants.
          </p>
        </div>
      </IonContent>
    </IonPage>
  );
};

export default StoriesHome;
