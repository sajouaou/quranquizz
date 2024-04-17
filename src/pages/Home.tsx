import { IonContent, IonHeader, IonPage, IonTitle, IonToolbar } from '@ionic/react';
import Menu from '../components/Menu';
import './Home.css';

const Home: React.FC = () => {
  return (
    <IonPage>
      <IonHeader>
        <IonToolbar>
          <IonTitle>Quran Quizz v1.13 Online Test</IonTitle>
        </IonToolbar>
      </IonHeader>
      <IonContent fullscreen>
        <IonHeader collapse="condense">
          <IonToolbar>
            <IonTitle size="large">Quran Quizz v1.13 Online Test</IonTitle>
          </IonToolbar>
        </IonHeader>
        <Menu />
      </IonContent>
    </IonPage>
  );
};

export default Home;
