import React, { useState, useEffect } from 'react';
import { IonButton, IonIcon, IonItem, IonLabel, IonSelect, IonSelectOption, IonSpinner } from '@ionic/react';
import { checkmarkCircle, chevronDown, closeCircle, playSkipForward } from 'ionicons/icons';
import SurahPicker from './SurahPicker';
import { verseBounds, type Chapter } from '../game/Game';
import { isEliminated, type PlayerProps } from '../game/Player';
import { vibrateResult } from '../../lib/feedback';
import './InputGame.css';

interface InputGameProps {
  isPlayer: boolean;
  chapters: Chapter[];
  minSurah: number;
  maxSurah: number;
  maxVerse: number;
  minVerse: number;
  askVerse: boolean;
  filterVerse: boolean;
  allReady: boolean;
  revealed: boolean;
  correctChapter: number | null;
  correctVerse: number;
  sendGameMessage: (message: any) => void;
  checkGuessAllPlayers: () => void;
  player: PlayerProps;
}

type Feedback = 'win' | 'lose' | 'next' | null;

// One instance per player: it holds the per-player round logic (readiness checks,
// result feedback). Only the local player's instance renders the answer controls.
const InputGame: React.FC<InputGameProps> = ({
  isPlayer,
  chapters,
  minSurah,
  maxSurah,
  maxVerse,
  minVerse,
  askVerse,
  filterVerse,
  allReady,
  revealed,
  correctChapter,
  correctVerse,
  sendGameMessage,
  checkGuessAllPlayers,
  player
}) => {
  const [feedback, setFeedback] = useState<Feedback>(null);
  const [pickerOpen, setPickerOpen] = useState(false);

  useEffect(() => {
    checkGuessAllPlayers();
  }, [player.gameState]);

  useEffect(() => {
    if (allReady) {
      if (player.gameState === 'win' || player.gameState === 'lose' || player.gameState === 'next') {
        setFeedback(player.gameState);
        if (isPlayer) vibrateResult(player.gameState);
        setTimeout(() => setFeedback(null), 2500);
      }
      if (isPlayer) {
        sendGameMessage({ content: `${player.playerName} is not ready`, action: 'setGameState', type: 'PLAYER', value:{player,state:"not ready"} });
      }
    }
  }, [allReady]);

  const handleNextButtonClick = () => {
    sendGameMessage({ content: `${player.playerName} is ready  for the next  question`, action: 'makeGuess', type: 'PLAYER', value:{player,surah:-1,verse:1} });
  };

  const handleConfirmButtonClick = () => {
    sendGameMessage({ content: `${player.playerName} has confirmed his choice`, action: 'makeGuess', type: 'PLAYER', value:{player,surah:player.guessChapter,verse:player.guessVerse} });
  };

  const handleChapterSelect = (selectedChapterId: number) => {
    sendGameMessage({ content: `${player.playerName} has selected a chapter`, action: 'setGuessChapter', type: 'PLAYER', value:{player,surah:selectedChapterId} });
  };
  const handleVerseSelect = (selectedVerseId: number) => {
    sendGameMessage({ content: `${player.playerName} has selected a verse`, action: 'setGuessVerse', type: 'PLAYER', value:{player,verse:selectedVerseId} });
  };

  if (!isPlayer) return null;

  const allowed = chapters.filter((chapter) => minSurah <= chapter.id && chapter.id <= maxSurah);
  const selected = allowed.find((chapter) => chapter.id === player.guessChapter) ?? null;
  const verses = (() => {
    if (!selected) return [];
    const [lo, hi] = verseBounds({ filterVerse, minSurah, maxSurah, minVerse, maxVerse }, selected);
    return Array.from({ length: hi - lo + 1 }, (_, i) => lo + i);
  })();
  const verseValid = !askVerse || verses.includes(player.guessVerse);
  const waiting = player.gameState === 'ready' || player.gameState === 'next';
  const correct = chapters.find((chapter) => chapter.id === correctChapter);

  if (isEliminated(player)) {
    return (
      <div className="InputContainer card eliminated">
        <p className="question">Tu n'as plus de vies 💔</p>
        <p className="waiting">Tu restes spectateur jusqu'à la fin de la partie.</p>
      </div>
    );
  }

  return (
    <div className="InputContainer card">
      {feedback && correct && (
        <div className={`feedback feedback-${feedback}`} role="status">
          <IonIcon icon={feedback === 'win' ? checkmarkCircle : feedback === 'lose' ? closeCircle : playSkipForward} />
          <div>
            <strong>{feedback === 'win' ? 'Bien joué !' : feedback === 'lose' ? 'Raté…' : 'Passé'}</strong>
            <span>
              {revealed
                ? <>C'était {correct.id}. {correct.name_simple}{askVerse ? `, verset ${correctVerse + 1}` : ''}</>
                : 'Personne n\'a trouvé : réécoute et retente ta chance !'}
            </span>
          </div>
        </div>
      )}

      <p className="question">De quelle sourate provient cette récitation ?</p>

      <button className="surah-button" type="button" disabled={waiting} onClick={() => setPickerOpen(true)}>
        {selected ? (
          <>
            <span className="surah-number">{selected.id}</span>
            <span className="surah-name">{selected.name_simple}</span>
            {selected.name_arabic && <span className="arabic">{selected.name_arabic}</span>}
          </>
        ) : (
          <span className="surah-name placeholder">Choisir une sourate</span>
        )}
        <IonIcon icon={chevronDown} />
      </button>

      {askVerse && selected && (
        <IonItem lines="none" className="verse-item">
          <IonLabel>Verset</IonLabel>
          <IonSelect
            interface="popover"
            disabled={waiting}
            placeholder="—"
            value={verseValid ? player.guessVerse : undefined}
            onIonChange={(e) => handleVerseSelect(Number(e.detail.value))}
          >
            {verses.map((x) => (
              <IonSelectOption key={x} value={x}>{x + 1}</IonSelectOption>
            ))}
          </IonSelect>
        </IonItem>
      )}

      {waiting ? (
        <div className="waiting">
          <IonSpinner name="dots" />
          <span>{player.gameState === 'next' ? 'Passé — ' : 'Réponse envoyée — '}en attente des autres joueurs</span>
        </div>
      ) : (
        <div className="answer-actions">
          <IonButton fill="outline" color="medium" onClick={handleNextButtonClick}>
            <IonIcon slot="start" icon={playSkipForward} />
            Passer
          </IonButton>
          <IonButton className="confirm" disabled={!selected || !verseValid} onClick={handleConfirmButtonClick}>
            <IonIcon slot="start" icon={checkmarkCircle} />
            Valider
          </IonButton>
        </div>
      )}

      <SurahPicker
        isOpen={pickerOpen}
        chapters={allowed}
        selected={selected?.id ?? null}
        onSelect={handleChapterSelect}
        onClose={() => setPickerOpen(false)}
      />
    </div>
  );
};

export default InputGame;
