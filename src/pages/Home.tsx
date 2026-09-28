import { IonContent, IonIcon, IonPage, useIonRouter, useIonViewWillEnter } from '@ionic/react';
import { useState } from 'react';
import { cloudDownloadOutline, flash, globe, heart, school } from 'ionicons/icons';
import { usePrefs } from '../lib/prefs';
import { findReciter, reciterLabel } from '../lib/quranApi';
import { getBestScore } from '../lib/stats';
import './Home.css';

const MODES = [
  { mode: 'Training', title: 'Entraînement', text: 'À ton rythme, réglages libres', icon: school, className: 'train wide' },
  { mode: 'Arcade', title: 'Arcade', text: '10 manches pour faire le meilleur score', icon: flash, className: 'arcade' },
  { mode: 'Survie', title: 'Survie', text: '3 vies, combien de sourates trouveras-tu ?', icon: heart, className: 'survival' },
];

const Home: React.FC = () => {
  const router = useIonRouter();
  const { reciterId } = usePrefs();
  // Ionic keeps this page mounted: refresh the records when coming back to it.
  const [, setVisit] = useState(0);
  useIonViewWillEnter(() => setVisit((v) => v + 1));

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
            <button type="button" className="mode-card online wide" onClick={() => router.push('/online')}>
              <IonIcon icon={globe} />
              <span className="mode-title">Jouer en ligne</span>
              <span className="mode-text">Crée ou rejoins un salon avec tes amis</span>
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
