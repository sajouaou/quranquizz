
import React, { useState } from 'react';
import { IonRange, IonIcon } from '@ionic/react';
import { volumeHigh, volumeLow } from 'ionicons/icons';

const VolumeControl = () => {
  const [volume, setVolume] = useState(50); // Volume initial

  const adjustVolume = (event) => {
    const newVolume = event.detail.value;
    setVolume(newVolume);
    // Vous pouvez ajouter ici la logique pour ajuster le volume de lecture audio ou toute autre sortie sonore de votre application.
  };

  return (
    <IonRange min={0} max={100} value={volume} onIonChange={adjustVolume}>
      <IonIcon slot="start" size="small" icon={volumeLow} />
      <IonIcon slot="end" size="small" icon={volumeHigh} />
    </IonRange>
  );
};

export default VolumeControl;