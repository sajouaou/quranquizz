import { IonButton, IonIcon, IonSegment, IonSegmentButton, IonLabel, IonTextarea } from '@ionic/react';
import { cameraOutline, clipboardOutline } from 'ionicons/icons';
import { useEffect, useRef, useState } from 'react';

interface ScanSignalProps {
  title: string;
  onCode: (code: string) => void;
  disabled?: boolean;
}

type Detector = { detect: (source: HTMLVideoElement) => Promise<{ rawValue: string }[]> };

// Reads a pairing code with the camera (QR) or from pasted text.
const ScanSignal: React.FC<ScanSignalProps> = ({ title, onCode, disabled }) => {
  const [tab, setTab] = useState<'camera' | 'paste'>('camera');
  const [text, setText] = useState('');
  const [cameraError, setCameraError] = useState<string | null>(null);
  const [scanning, setScanning] = useState(false);
  const videoRef = useRef<HTMLVideoElement>(null);
  const streamRef = useRef<MediaStream | null>(null);

  const stopCamera = () => {
    streamRef.current?.getTracks().forEach((t) => t.stop());
    streamRef.current = null;
    setScanning(false);
  };
  useEffect(() => stopCamera, []);
  useEffect(() => { if (disabled) stopCamera(); }, [disabled]);

  const startCamera = async () => {
    setCameraError(null);
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: 'environment' } });
      streamRef.current = stream;
      const video = videoRef.current!;
      video.srcObject = stream;
      await video.play();
      setScanning(true);

      const Native = (window as unknown as { BarcodeDetector?: new (o: object) => Detector }).BarcodeDetector;
      const native = Native ? new Native({ formats: ['qr_code'] }) : null;
      const jsQR = native ? null : (await import('jsqr')).default;
      const canvas = document.createElement('canvas');
      const context = canvas.getContext('2d', { willReadFrequently: true })!;

      const tick = async () => {
        if (!streamRef.current) return;
        let value: string | null = null;
        try {
          if (native) {
            value = (await native.detect(video))[0]?.rawValue ?? null;
          } else if (jsQR && video.videoWidth) {
            canvas.width = video.videoWidth;
            canvas.height = video.videoHeight;
            context.drawImage(video, 0, 0);
            value = jsQR(context.getImageData(0, 0, canvas.width, canvas.height).data, canvas.width, canvas.height)?.data ?? null;
          }
        } catch {
          // keep scanning
        }
        if (value && value.includes('QQ1.')) {
          stopCamera();
          onCode(value);
          return;
        }
        setTimeout(tick, 200);
      };
      tick();
    } catch {
      setCameraError("Caméra indisponible. Autorise l'accès à la caméra, ou colle le code reçu.");
      setTab('paste');
    }
  };

  return (
    <div className="scan-signal">
      <h3>{title}</h3>
      <IonSegment value={tab} onIonChange={(e) => { stopCamera(); setTab(e.detail.value as 'camera' | 'paste'); }}>
        <IonSegmentButton value="camera"><IonLabel>Scanner</IonLabel></IonSegmentButton>
        <IonSegmentButton value="paste"><IonLabel>Coller le code</IonLabel></IonSegmentButton>
      </IonSegment>
      {tab === 'camera' ? (
        <div className="camera-box">
          <video ref={videoRef} playsInline muted className={scanning ? 'active' : ''} />
          {!scanning && (
            <IonButton disabled={disabled} onClick={startCamera}>
              <IonIcon slot="start" icon={cameraOutline} />Ouvrir la caméra
            </IonButton>
          )}
          {cameraError && <p className="signal-error">{cameraError}</p>}
        </div>
      ) : (
        <div className="paste-box">
          <IonTextarea
            fill="outline"
            rows={4}
            placeholder="Colle ici le code QQ1.… reçu"
            value={text}
            onIonInput={(e) => setText(String(e.detail.value ?? ''))}
            data-testid="signal-input"
          />
          <IonButton expand="block" disabled={disabled || !text.includes('QQ1.')} onClick={() => onCode(text)}>
            <IonIcon slot="start" icon={clipboardOutline} />Valider le code
          </IonButton>
        </div>
      )}
    </div>
  );
};

export default ScanSignal;
