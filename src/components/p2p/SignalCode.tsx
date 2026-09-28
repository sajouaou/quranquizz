import { IonButton, IonIcon, IonSpinner, useIonToast } from '@ionic/react';
import { copyOutline, shareSocialOutline } from 'ionicons/icons';
import { useEffect, useState } from 'react';

interface SignalCodeProps {
  code: string;
  title: string;
  hint?: string;
}

// A pairing code shown as a QR code, with copy/share for when the camera isn't an option.
const SignalCode: React.FC<SignalCodeProps> = ({ code, title, hint }) => {
  const [image, setImage] = useState<string | null>(null);
  const [presentToast] = useIonToast();

  useEffect(() => {
    let cancelled = false;
    import('qrcode')
      .then((QR) => QR.toDataURL(code, { errorCorrectionLevel: 'L', margin: 1, width: 360 }))
      .then((url) => { if (!cancelled) setImage(url); })
      .catch(() => { if (!cancelled) setImage(null); });
    return () => { cancelled = true; };
  }, [code]);

  const copy = async () => {
    try {
      await navigator.clipboard.writeText(code);
      presentToast({ message: 'Code copié', duration: 1500 });
    } catch {
      presentToast({ message: 'Copie impossible : sélectionne le texte du code', duration: 2500 });
    }
  };

  const share = async () => {
    try {
      await navigator.share({ title: 'Quran Quizz', text: code });
    } catch {
      // cancelled
    }
  };

  return (
    <div className="signal-code">
      <h3>{title}</h3>
      {hint && <p className="signal-hint">{hint}</p>}
      <div className="qr-frame">
        {image ? <img src={image} alt="QR code de connexion" /> : <IonSpinner name="crescent" />}
      </div>
      <div className="signal-actions">
        <IonButton size="small" fill="outline" onClick={copy}>
          <IonIcon slot="start" icon={copyOutline} />Copier le code
        </IonButton>
        {typeof navigator.share === 'function' && (
          <IonButton size="small" fill="outline" onClick={share}>
            <IonIcon slot="start" icon={shareSocialOutline} />Envoyer
          </IonButton>
        )}
      </div>
      <details className="signal-text">
        <summary>Afficher le code texte</summary>
        <textarea readOnly value={code} rows={4} onFocus={(e) => e.currentTarget.select()} data-testid="signal-code" />
      </details>
    </div>
  );
};

export default SignalCode;
