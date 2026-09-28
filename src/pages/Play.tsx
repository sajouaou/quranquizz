import { IonPage, useIonRouter } from '@ionic/react';
import { Redirect, useLocation, useParams } from 'react-router-dom';
import GameContainer from '../components/GameContainer';
import { useChapters } from '../hooks/useChapters';

export const SERVER_ENDPOINT = import.meta.env.VITE_SERVER_URL ?? 'wss://quranquizz-server.onrender.com';

const Play: React.FC = () => {
  const { mode } = useParams<{ mode: string }>();
  const location = useLocation();
  const router = useIonRouter();
  const chapters = useChapters();
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
      {online && (!name || !room) ? (
        // Opened without a room (e.g. reload): go through the lobby.
        <Redirect to="/online" />
      ) : (
        <GameContainer
          key={`${mode}-${room ?? ''}-${name}`}
          mode={mode}
          chapters={chapters}
          name={name}
          room={room}
          endpoint={online ? SERVER_ENDPOINT : undefined}
          leave={leave}
        />
      )}
    </IonPage>
  );
};

export default Play;
