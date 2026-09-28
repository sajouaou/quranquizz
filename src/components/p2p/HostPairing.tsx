import {
  IonButton, IonButtons, IonContent, IonHeader, IonModal, IonSpinner, IonTitle, IonToolbar, useIonToast,
} from '@ionic/react';
import { useEffect, useRef, useState } from 'react';
import type { RoomLink } from '../../lib/net/link';
import type { HostLink } from '../../lib/net/p2p';
import { acceptAnswer, createOffer, waitOpen } from '../../lib/net/webrtc';
import ScanSignal from './ScanSignal';
import SignalCode from './SignalCode';
import './P2P.css';

interface HostPairingProps {
  isOpen: boolean;
  onClose: () => void;
  link: RoomLink;
  hostName: string;
}

type Step = 'creating' | 'offer' | 'connecting' | 'error';

// Host side of the pairing: show an invitation code, read the player's answer code.
const HostPairing: React.FC<HostPairingProps> = ({ isOpen, onClose, link, hostName }) => {
  const [step, setStep] = useState<Step>('creating');
  const [code, setCode] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [attempt, setAttempt] = useState(0);
  const pending = useRef<{ pc: RTCPeerConnection; channel: RTCDataChannel; done: boolean } | null>(null);
  const [presentToast] = useIonToast();

  useEffect(() => {
    if (!isOpen) return;
    let cancelled = false;
    setStep('creating');
    setError(null);
    createOffer(hostName)
      .then(({ pc, channel, code: offer }) => {
        if (cancelled) { pc.close(); return; }
        // Plugged in right away: the player's hello arrives as soon as the channel opens.
        (link as HostLink).attach(channel, pc);
        pending.current = { pc, channel, done: false };
        setCode(offer);
        setStep('offer');
      })
      .catch(() => { if (!cancelled) { setError("Impossible de créer l'invitation sur cet appareil."); setStep('error'); } });
    return () => {
      cancelled = true;
      if (pending.current && !pending.current.done) pending.current.pc.close();
      pending.current = null;
    };
  }, [isOpen, attempt, hostName, link]);

  const onAnswer = async (text: string) => {
    const current = pending.current;
    if (!current) return;
    try {
      setStep('connecting');
      const guestName = await acceptAnswer(current.pc, text);
      await waitOpen(current.channel);
      current.done = true;
      presentToast({ message: `${guestName} est connecté`, duration: 2000, color: 'success' });
      onClose();
    } catch (e) {
      setError((e as Error).message);
      setStep('error');
    }
  };

  return (
    <IonModal isOpen={isOpen} onDidDismiss={onClose}>
      <IonHeader>
        <IonToolbar>
          <IonTitle>Ajouter un joueur</IonTitle>
          <IonButtons slot="end"><IonButton onClick={onClose}>Fermer</IonButton></IonButtons>
        </IonToolbar>
      </IonHeader>
      <IonContent className="ion-padding p2p-content">
        {step === 'creating' && <div className="p2p-wait"><IonSpinner /> Préparation de l'invitation…</div>}
        {(step === 'offer' || step === 'connecting') && (
          <>
            <SignalCode code={code} title="1. Fais scanner ce code" hint="Ton ami ouvre « Partie locale › Rejoindre » et scanne ce code (ou colle-le)." />
            {step === 'offer'
              ? <ScanSignal title="2. Scanne sa réponse" onCode={onAnswer} />
              : <div className="p2p-wait"><IonSpinner /> Connexion en cours…</div>}
          </>
        )}
        {step === 'error' && (
          <div className="p2p-error">
            <p>{error}</p>
            <IonButton onClick={() => setAttempt((a) => a + 1)}>Recommencer</IonButton>
          </div>
        )}
      </IonContent>
    </IonModal>
  );
};

export default HostPairing;
