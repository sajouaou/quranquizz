import { IonPage, useIonRouter } from '@ionic/react';
import { useMemo, useState } from 'react';
import { Redirect, useLocation, useParams } from 'react-router-dom';
import GameContainer, { Connection } from '../components/GameContainer';
import { useChapters } from '../hooks/useChapters';
import { endSession, getSession } from '../lib/net/session';

const KNOWN_MODES = ['Training', 'Arcade', 'Survie', 'Online', 'Local'];

export const SERVER_ENDPOINT = import.meta.env.VITE_SERVER_URL ?? 'wss://quranquizz-server.onrender.com';

const Play: React.FC = () => {
  const { mode } = useParams<{ mode: string }>();
  const location = useLocation();
  const router = useIonRouter();
  const chapters = useChapters();
  const [attempt, setAttempt] = useState(0);
  const params = new URLSearchParams(location.search);
  const session = mode === 'Local' ? getSession() : null;
  const name = mode === 'Online' ? params.get('name') ?? '' : session?.name ?? 'ME';
  const room = params.get('room') ?? undefined;

  // Stable object: a new one would reopen the connection.
  const connection = useMemo<Connection | undefined>(() => {
    if (mode === 'Online' && room) return { type: 'server', endpoint: SERVER_ENDPOINT, room };
    if (mode === 'Local' && session) return { type: 'p2p', link: session.link, label: session.link.kind === 'host' ? '' : `chez ${session.hostName}` };
    return undefined;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [mode, room, session?.link, attempt]);

  const leave = () => {
    if (mode === 'Local') endSession();
    if (router.canGoBack()) router.goBack();
    else router.push('/home', 'root', 'replace');
  };

  let content: React.ReactNode;
  if (!KNOWN_MODES.includes(mode)) {
    content = <Redirect to="/home" />;
  } else if (mode === 'Online' && (!name || !room)) {
    // Opened without a room (e.g. reload): go through the lobby.
    content = <Redirect to={room ? `/online?room=${encodeURIComponent(room)}` : '/online'} />;
  } else if (mode === 'Local' && !session) {
    content = <Redirect to="/local" />;
  } else {
    content = (
      <GameContainer
        key={`${mode}-${room ?? ''}-${name}-${attempt}`}
        mode={mode}
        chapters={chapters}
        name={name}
        connection={connection}
        leave={leave}
        retry={mode === 'Online' ? () => setAttempt((a) => a + 1) : undefined}
      />
    );
  }

  return <IonPage>{content}</IonPage>;
};

export default Play;
