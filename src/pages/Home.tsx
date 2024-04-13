import { IonContent, IonHeader, IonPage, IonTitle, IonToolbar } from '@ionic/react';
import Menu from '../components/Menu';
import './Home.css';

const Home: React.FC = () => {
  return (
    <IonPage>
      <IonHeader>
        <IonToolbar>
          <IonTitle>Quran Quizz</IonTitle>
        </IonToolbar>
      </IonHeader>
      <IonContent fullscreen>
        <IonHeader collapse="condense">
          <IonToolbar>
            <IonTitle size="large">Quran Quizz</IonTitle>
          </IonToolbar>
        </IonHeader>
        <Menu />
      </IonContent>
    </IonPage>
  );
};

export default Home;
