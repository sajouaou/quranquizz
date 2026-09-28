import {
  IonButton, IonButtons, IonContent, IonFooter, IonHeader, IonIcon, IonInput, IonModal,
  IonTitle, IonToggle, IonToolbar,
} from '@ionic/react';
import { send } from 'ionicons/icons';
import React, { useEffect, useRef, useState } from 'react';
import './Chat.css';

interface ChatProps {
  messages: any[];
  name: string;
  message: string;
  showChat: boolean;
  isHost: (name: string) => boolean;
  handleSubmit: (e: { preventDefault: () => void }) => void;
  setMessage: (value: string) => void;
  setShowChat: (value: boolean) => void;
}

const Chat: React.FC<ChatProps> = ({
  messages,
  name,
  message,
  showChat,
  isHost,
  handleSubmit,
  setMessage,
  setShowChat,
}) => {
  const contentRef = useRef<HTMLIonContentElement>(null);
  const [showGame, setShowGame] = useState(false);

  const visible = messages.filter(
    (val) => val.text.type === 'CHAT' || val.text.type === 'WELCOME' || (showGame && val.text.content),
  );

  useEffect(() => {
    contentRef.current?.scrollToBottom(200);
  }, [visible.length, showChat]);

  return (
    <IonModal isOpen={showChat} onDidDismiss={() => setShowChat(false)}>
      <IonHeader>
        <IonToolbar>
          <IonTitle>Discussion</IonTitle>
          <IonButtons slot="end">
            <IonButton onClick={() => setShowChat(false)}>Fermer</IonButton>
          </IonButtons>
        </IonToolbar>
        <IonToolbar>
          <IonToggle className="chat-toggle" checked={showGame} onIonChange={(e) => setShowGame(e.detail.checked)}>
            Afficher les évènements de jeu
          </IonToggle>
        </IonToolbar>
      </IonHeader>
      <IonContent ref={contentRef} className="chat-content">
        <div className="chat-list">
          {visible.map((val, i) => {
            const mine = val.user === name;
            const system = val.user === 'Admin' || val.text.type !== 'CHAT';
            return (
              <div key={i} className={`message ${system ? 'system-message' : mine ? 'user-message' : 'other-message'}`}>
                {!system && !mine && (
                  <span className={'message-user ' + (isHost(val.user) ? 'host' : '')}>{val.user}</span>
                )}
                <span className="message-content">{val.text.content}</span>
              </div>
            );
          })}
        </div>
      </IonContent>
      <IonFooter>
        <form onSubmit={handleSubmit} className="chat-form">
          <IonInput
            value={message}
            onIonInput={(e) => setMessage(String(e.detail.value ?? ''))}
            fill="outline"
            placeholder="Écrire un message…"
            enterkeyhint="send"
          />
          <IonButton type="submit" disabled={!message.trim()} aria-label="Envoyer">
            <IonIcon slot="icon-only" icon={send} />
          </IonButton>
        </form>
      </IonFooter>
    </IonModal>
  );
};

export default Chat;
