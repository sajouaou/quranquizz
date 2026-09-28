import {
  IonButton, IonButtons, IonContent, IonHeader, IonItem, IonLabel, IonList, IonModal,
  IonNote, IonSearchbar, IonTitle, IonToolbar,
} from '@ionic/react';
import React, { useMemo, useState } from 'react';
import type { Chapter } from '../game/Game';

interface SurahPickerProps {
  isOpen: boolean;
  chapters: Chapter[];
  selected: number | null;
  onSelect: (id: number) => void;
  onClose: () => void;
}

export const normalize = (text: string) =>
  text.normalize('NFD').replace(/[̀-ͯ]/g, '').replace(/[^a-z0-9؀-ۿ]/gi, '').toLowerCase();

export function filterChapters(chapters: Chapter[], query: string): Chapter[] {
  const q = normalize(query);
  if (!q) return chapters;
  return chapters.filter(
    (c) =>
      String(c.id) === q ||
      normalize(c.name_simple).includes(q) ||
      (c.name_arabic ? normalize(c.name_arabic).includes(q) : false),
  );
}

const SurahPicker: React.FC<SurahPickerProps> = ({ isOpen, chapters, selected, onSelect, onClose }) => {
  const [query, setQuery] = useState('');
  const results = useMemo(() => filterChapters(chapters, query), [chapters, query]);

  return (
    <IonModal isOpen={isOpen} onDidDismiss={() => { setQuery(''); onClose(); }}>
      <IonHeader>
        <IonToolbar>
          <IonTitle>Choisir la sourate</IonTitle>
          <IonButtons slot="end">
            <IonButton onClick={onClose}>Fermer</IonButton>
          </IonButtons>
        </IonToolbar>
        <IonToolbar>
          <IonSearchbar
            value={query}
            debounce={0}
            placeholder="Nom ou numéro…"
            onIonInput={(e) => setQuery(e.detail.value ?? '')}
          />
        </IonToolbar>
      </IonHeader>
      <IonContent>
        <IonList>
          {results.map((chapter) => (
            <IonItem
              key={chapter.id}
              button
              detail={false}
              color={chapter.id === selected ? 'light' : undefined}
              onClick={() => { onSelect(chapter.id); onClose(); }}
            >
              <span className="surah-number" slot="start">{chapter.id}</span>
              <IonLabel>
                <h2>{chapter.name_simple}</h2>
                <p>{chapter.verses_count} versets</p>
              </IonLabel>
              {chapter.name_arabic && <IonNote slot="end" className="arabic">{chapter.name_arabic}</IonNote>}
            </IonItem>
          ))}
          {results.length === 0 && (
            <IonItem lines="none"><IonLabel color="medium">Aucune sourate trouvée</IonLabel></IonItem>
          )}
        </IonList>
      </IonContent>
    </IonModal>
  );
};

export default SurahPicker;
