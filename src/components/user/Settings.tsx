import {
  IonButton, IonButtons, IonContent, IonHeader, IonItem, IonLabel, IonList, IonListHeader,
  IonModal, IonNote, IonRange, IonSelect, IonSelectOption, IonTitle, IonToggle, IonToolbar,
} from '@ionic/react';
import { volumeHigh, volumeLow } from 'ionicons/icons';
import { IonIcon } from '@ionic/react';
import React from 'react';
import type { SettingItem } from '../game/GameMode';

interface SettingsProps {
  isOpen: boolean;
  onClose: () => void;
  settingsParameters: SettingItem[];
  readOnlyNotice?: string;
}

const Settings: React.FC<SettingsProps> = ({ isOpen, onClose, settingsParameters, readOnlyNotice }) => {
  const visible = settingsParameters.filter((e) => !('condition' in e) || e.condition === undefined || e.condition);

  return (
    <IonModal isOpen={isOpen} onDidDismiss={onClose} initialBreakpoint={0.75} breakpoints={[0, 0.75, 1]}>
      <IonHeader>
        <IonToolbar>
          <IonTitle>Réglages</IonTitle>
          <IonButtons slot="end">
            <IonButton strong onClick={onClose}>OK</IonButton>
          </IonButtons>
        </IonToolbar>
      </IonHeader>
      <IonContent>
        {readOnlyNotice && <p className="settings-notice">{readOnlyNotice}</p>}
        <IonList inset>
          {visible.map((element, i) => {
            switch (element.type) {
              case 'SECTION':
                return (
                  <IonListHeader key={i}>
                    <IonLabel>{element.label}</IonLabel>
                  </IonListHeader>
                );
              case 'CHECKBOX':
                return (
                  <IonItem key={i}>
                    <IonToggle checked={element.value} onIonChange={(e) => element.set(e.detail.checked)}>
                      <IonLabel>
                        {element.label}
                        {element.hint && <IonNote className="setting-hint">{element.hint}</IonNote>}
                      </IonLabel>
                    </IonToggle>
                  </IonItem>
                );
              case 'SELECT':
                return (
                  <IonItem key={i}>
                    <IonSelect
                      label={element.label}
                      interface="popover"
                      value={element.value}
                      onIonChange={(e) => element.set(Number(e.detail.value))}
                    >
                      {element.data.map((x) => (
                        <IonSelectOption key={x.value} value={x.value}>{x.label}</IonSelectOption>
                      ))}
                    </IonSelect>
                  </IonItem>
                );
              case 'SLIDER':
                return (
                  <IonItem key={i}>
                    <IonRange
                      label={element.label}
                      min={element.min}
                      max={element.max}
                      step={element.step}
                      value={element.value}
                      onIonInput={(e) => element.set(Number(e.detail.value))}
                    >
                      <IonIcon slot="start" icon={volumeLow} />
                      <IonIcon slot="end" icon={volumeHigh} />
                    </IonRange>
                  </IonItem>
                );
              case 'BUTTON':
                return (
                  <IonItem key={i} lines="none">
                    <IonButton expand="block" fill="outline" color={element.color} className="full" onClick={element.click}>
                      {element.label}
                    </IonButton>
                  </IonItem>
                );
              default:
                return null;
            }
          })}
        </IonList>
      </IonContent>
    </IonModal>
  );
};

export default Settings;
