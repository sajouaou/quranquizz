import { IonContent, IonIcon, IonPage, useIonRouter, useIonViewWillEnter } from '@ionic/react';
import { useState } from 'react';
import { book, cloudDownloadOutline, flash, globe, heart, school, wifi } from 'ionicons/icons';
import { STORIES } from '../data/stories';
import { useStoryProgress } from '../lib/storyProgress';
import { usePrefs } from '../lib/prefs';
import { findReciter, reciterLabel } from '../lib/quranApi';
import { getBestScore } from '../lib/stats';
import { endSession } from '../lib/net/session';
import './Home.css';

const MODES = [
  { mode: 'Training', title: 'Entraînement', text: 'À ton rythme, réglages libres', icon: school, className: 'train wide' },
  { mode: 'Arcade', title: 'Arcade', text: '10 manches pour faire le meilleur score', icon: flash, className: 'arcade' },
  { mode: 'Survie', title: 'Survie', text: '3 vies, combien de sourates trouveras-tu ?', icon: heart, className: 'survival' },
];

const Home: React.FC = () => {
  const router = useIonRouter();
  const { reciterId } = usePrefs();
  const progress = useStoryProgress();
  const listened = STORIES.filter((story) => progress[story.id]?.listened).length;
  // Ionic keeps this page mounted: refresh the records when coming back to it.
  const [, setVisit] = useState(0);
  useIonViewWillEnter(() => {
    setVisit((v) => v + 1);
    endSession(); // back on the menu (e.g. Android back button): a local game is over
  });

  return (
    <IonPage>
      <IonContent fullscreen className="home-content">
        <div className="home">
          <header className="hero">
            <p className="hero-arabic arabic" lang="ar">القرآن الكريم</p>
            <h1>Quran Quizz</h1>
            <p className="hero-sub">Écoute une récitation, retrouve la sourate.</p>
          </header>

          <section className="mode-grid" aria-label="Modes de jeu">
            {MODES.map((m) => (
              <button key={m.mode} type="button" className={`mode-card ${m.className}`}
                onClick={() => router.push(`/play/${m.mode}`)}>
                <IonIcon icon={m.icon} />
                <span className="mode-title">{m.title}</span>
                <span className="mode-text">{m.text}</span>
                {getBestScore(m.mode) !== null && <span className="mode-best">Record : {getBestScore(m.mode)}</span>}
              </button>
            ))}
            <button type="button" className="mode-card qasas wide" onClick={() => router.push('/stories')}>
              <IonIcon icon={book} />
              <span className="mode-title">Récits du Coran</span>
              <span className="mode-text">Écoute les histoires des prophètes et relève leurs défis</span>
              <span className="mode-best">{listened} / {STORIES.length} récits écoutés</span>
            </button>
            <button type="button" className="mode-card online" onClick={() => router.push('/online')}>
              <IonIcon icon={globe} />
              <span className="mode-title">En ligne</span>
              <span className="mode-text">Salon sur Internet avec tes amis</span>
            </button>
            <button type="button" className="mode-card local" onClick={() => router.push('/local')}>
              <IonIcon icon={wifi} />
              <span className="mode-title">Partie locale</span>
              <span className="mode-text">Sans serveur, d'appareil à appareil</span>
            </button>
          </section>

          <button type="button" className="library-link" onClick={() => router.push('/library')}>
            <IonIcon icon={cloudDownloadOutline} />
            <span>
              <strong>Récitateurs & hors-ligne</strong>
              <small>{reciterLabel(findReciter(reciterId))}</small>
            </span>
          </button>
        </div>
      </IonContent>
    </IonPage>
  );
};

export default Home;
