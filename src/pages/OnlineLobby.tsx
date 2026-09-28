import {
  IonBackButton, IonButton, IonButtons, IonContent, IonHeader, IonIcon, IonInput, IonItem,
  IonList, IonNote, IonPage, IonTitle, IonToolbar, useIonRouter,
} from '@ionic/react';
import { enterOutline } from 'ionicons/icons';
import { useState } from 'react';
import { useLocation } from 'react-router-dom';
import { getPrefs, setPrefs } from '../lib/prefs';

const OnlineLobby: React.FC = () => {
  const router = useIonRouter();
  const [name, setName] = useState(getPrefs().playerName);
  const location = useLocation();
  // Invitation links open /online?room=xxx
  const [room, setRoom] = useState(() => new URLSearchParams(location.search).get('room') ?? getPrefs().lastRoom);
  const valid = name.trim().length > 0 && room.trim().length > 0;

  const join = (e?: { preventDefault: () => void }) => {
    e?.preventDefault();
    if (!valid) return;
    setPrefs({ playerName: name.trim(), lastRoom: room.trim() });
    const query = new URLSearchParams({ name: name.trim(), room: room.trim() });
    router.push(`/play/Online?${query.toString()}`);
  };

  return (
    <IonPage>
      <IonHeader>
        <IonToolbar>
          <IonButtons slot="start">
            <IonBackButton defaultHref="/home" text="" />
          </IonButtons>
          <IonTitle>Jouer en ligne</IonTitle>
        </IonToolbar>
      </IonHeader>
      <IonContent className="ion-padding">
        <form onSubmit={join} className="lobby-form">
          <p className="lobby-help">
            Entre le même nom de salon que tes amis pour jouer ensemble. Le premier arrivé devient l'hôte.
          </p>
          <IonList inset>
            <IonItem>
              <IonInput label="Ton pseudo" labelPlacement="stacked" placeholder="ex. Yusuf" maxlength={20}
                value={name} onIonInput={(e) => setName(String(e.detail.value ?? ''))} autocomplete="nickname" />
            </IonItem>
            <IonItem>
              <IonInput label="Nom du salon" labelPlacement="stacked" placeholder="ex. famille" maxlength={30}
                value={room} onIonInput={(e) => setRoom(String(e.detail.value ?? ''))} enterkeyhint="go" />
            </IonItem>
          </IonList>
          <IonNote className="lobby-note">Chaque joueur doit avoir un pseudo différent.</IonNote>
          <IonButton type="submit" expand="block" size="large" disabled={!valid}>
            <IonIcon slot="start" icon={enterOutline} />
            Rejoindre / créer le salon
          </IonButton>
        </form>
      </IonContent>
    </IonPage>
  );
};

export default OnlineLobby;
