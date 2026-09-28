import { IonPage, useIonRouter } from '@ionic/react';
import { useState } from 'react';
import { Redirect, useLocation, useParams } from 'react-router-dom';
import GameContainer from '../components/GameContainer';
import { useChapters } from '../hooks/useChapters';

const KNOWN_MODES = ['Training', 'Arcade', 'Survie', 'Online'];

export const SERVER_ENDPOINT = import.meta.env.VITE_SERVER_URL ?? 'wss://quranquizz-server.onrender.com';

const Play: React.FC = () => {
  const { mode } = useParams<{ mode: string }>();
  const location = useLocation();
  const router = useIonRouter();
  const chapters = useChapters();
  const [attempt, setAttempt] = useState(0);
  const params = new URLSearchParams(location.search);
  const online = mode === 'Online';
  const name = online ? params.get('name') ?? '' : 'ME';
  const room = params.get('room') ?? undefined;

  const leave = () => {
    if (router.canGoBack()) router.goBack();
    else router.push('/home', 'root', 'replace');
  };

  return (
    <IonPage>
      {!KNOWN_MODES.includes(mode) ? (
        <Redirect to="/home" />
      ) : online && (!name || !room) ? (
        // Opened without a room (e.g. reload): go through the lobby.
        <Redirect to={room ? `/online?room=${encodeURIComponent(room)}` : '/online'} />
      ) : (
        <GameContainer
          key={`${mode}-${room ?? ''}-${name}-${attempt}`}
          mode={mode}
          chapters={chapters}
          name={name}
          room={room}
          endpoint={online ? SERVER_ENDPOINT : undefined}
          leave={leave}
          retry={() => setAttempt((a) => a + 1)}
        />
      )}
    </IonPage>
  );
};

export default Play;
