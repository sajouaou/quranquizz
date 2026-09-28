import {
  IonBackButton, IonButton, IonButtons, IonContent, IonHeader, IonIcon, IonInput, IonItem, IonList, IonPage,
  IonSpinner, IonTitle, IonToolbar, useIonRouter, useIonViewWillEnter,
} from '@ionic/react';
import { enterOutline, radioOutline } from 'ionicons/icons';
import { useRef, useState } from 'react';
import { defaultGame } from '../components/game/Game';
import { defaultPlayer } from '../components/game/Player';
import ScanSignal from '../components/p2p/ScanSignal';
import SignalCode from '../components/p2p/SignalCode';
import { GuestLink, HostLink } from '../lib/net/p2p';
import { endSession, startSession } from '../lib/net/session';
import { answerOffer, isWebRtcSupported, waitOpen } from '../lib/net/webrtc';
import { getPrefs, setPrefs } from '../lib/prefs';
import '../components/p2p/P2P.css';

type Step = 'choose' | 'scan' | 'answer' | 'error';

// Peer-to-peer game without any server: one device hosts, the others pair with it.
const LocalLobby: React.FC = () => {
  const router = useIonRouter();
  const [name, setName] = useState(getPrefs().playerName);
  const [step, setStep] = useState<Step>('choose');
  const [answer, setAnswer] = useState('');
  const [hostName, setHostName] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const peerRef = useRef<RTCPeerConnection | null>(null);
  const trimmed = name.trim();

  // Coming back here ends any previous local game.
  useIonViewWillEnter(() => {
    endSession();
    peerRef.current?.close();
    peerRef.current = null;
    setStep('choose');
    setBusy(false);
  });

  const hello = () => ({
    username: trimmed,
    player: { ...defaultPlayer, playerName: trimmed },
    game: { ...defaultGame },
    clientId: getPrefs().clientId,
  });

  const host = () => {
    setPrefs({ playerName: trimmed });
    startSession({ link: new HostLink(hello()), name: trimmed, hostName: trimmed });
    router.push('/play/Local');
  };

  const onOffer = async (text: string) => {
    setBusy(true);
    setPrefs({ playerName: trimmed });
    try {
      const { pc, code, hostName: owner, channel } = await answerOffer(text, trimmed);
      peerRef.current = pc;
      setHostName(owner);
      setAnswer(code);
      setStep('answer');
      const open = await Promise.race([
        channel.then((c) => waitOpen(c)),
        new Promise<never>((_, reject) => setTimeout(() => reject(new Error("L'hôte n'a pas scanné la réponse à temps.")), 120000)),
      ]);
      startSession({ link: new GuestLink(open, hello(), pc), name: trimmed, hostName: owner });
      peerRef.current = null;
      router.push('/play/Local');
    } catch (e) {
      setError((e as Error).message);
      setStep('error');
    } finally {
      setBusy(false);
    }
  };

  return (
    <IonPage>
      <IonHeader>
        <IonToolbar>
          <IonButtons slot="start"><IonBackButton defaultHref="/home" text="" /></IonButtons>
          <IonTitle>Partie locale</IonTitle>
        </IonToolbar>
      </IonHeader>
      <IonContent className="ion-padding p2p-content">
        <div className="lobby-form">
          {!isWebRtcSupported() && <p className="signal-error">Cet appareil ne permet pas les connexions directes (WebRTC).</p>}

          {step === 'choose' && (
            <>
              <p className="lobby-help">
                Jouez à plusieurs sans serveur ni compte : les appareils se connectent directement entre eux.
              </p>
              <IonList inset>
                <IonItem>
                  <IonInput label="Ton pseudo" labelPlacement="stacked" placeholder="ex. Maryam" maxlength={20}
                    value={name} onIonInput={(e) => setName(String(e.detail.value ?? ''))} />
                </IonItem>
              </IonList>
              <div className="local-choice">
                <IonButton expand="block" size="large" disabled={!trimmed || !isWebRtcSupported()} onClick={host}>
                  <IonIcon slot="start" icon={radioOutline} />Héberger la partie
                </IonButton>
                <IonButton expand="block" size="large" fill="outline" disabled={!trimmed || !isWebRtcSupported()} onClick={() => setStep('scan')}>
                  <IonIcon slot="start" icon={enterOutline} />Rejoindre une partie
                </IonButton>
              </div>
              <ul className="local-help">
                <li>Soyez sur le même Wi-Fi, ou connectez-vous au partage de connexion d'un des téléphones : Internet n'est pas nécessaire.</li>
                <li>L'hôte appuie sur « Ajouter un joueur » pour chaque invité : un code à scanner dans chaque sens.</li>
                <li>Pour les récitations, les sourates doivent être téléchargées sur chaque appareil (Récitateurs & hors-ligne) si vous n'avez pas Internet.</li>
              </ul>
            </>
          )}

          {step === 'scan' && (
            <>
              <ScanSignal title="1. Scanne le code affiché par l'hôte" onCode={onOffer} disabled={busy} />
              {busy && <div className="p2p-wait"><IonSpinner /> Préparation de la réponse…</div>}
              <IonButton fill="clear" expand="block" onClick={() => setStep('choose')}>Retour</IonButton>
            </>
          )}

          {step === 'answer' && (
            <>
              <SignalCode code={answer} title={`2. Montre ce code à ${hostName || "l'hôte"}`}
                hint="L'hôte le scanne avec « Scanner sa réponse ». La partie s'ouvrira automatiquement." />
              <div className="p2p-wait"><IonSpinner /> En attente de l'hôte…</div>
            </>
          )}

          {step === 'error' && (
            <div className="p2p-error">
              <p>{error}</p>
              <IonButton onClick={() => { setError(null); setStep('scan'); }}>Réessayer</IonButton>
            </div>
          )}
        </div>
      </IonContent>
    </IonPage>
  );
};

export default LocalLobby;
