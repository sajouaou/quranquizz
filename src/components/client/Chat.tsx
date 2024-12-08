import { IonButton, IonCheckbox, IonInput, IonItem, IonLabel, IonList, IonText } from "@ionic/react";
import React, { useEffect, useState } from "react";
import './Chat.css';

interface ChatProps 
{
  messages: any[];
  name: string;
  message: string;
  showChat: boolean;
  isHost: any;
  handleSubmit:any;
  setMessage:any;
  setShowChat:any;
  sendScan:any;
}


// TODO si possible deplacer la logique reseau ou message Managment ici
const Chat: React.FC<ChatProps>  = ({
  messages,
  name,
  message,
  showChat,
  isHost,
  handleSubmit,
  setMessage,
  setShowChat,
  sendScan
}) => {
  const chatContainerRef = React.useRef<any>(null);
  
  const [showGame, setShowGame] = useState(false); 
  
  
  useEffect(() => {
    // Scroll to the bottom of the chat container whenever messages change
    scrollToBottom();

    function scrollToBottom() {
      if (chatContainerRef.current !== null ) {
        chatContainerRef.current.scrollTop = chatContainerRef.current.scrollHeight ;
      }
    }
  }, [messages,showChat]);

  return (
    <IonList className="chat-container" ref={chatContainerRef}>
          {messages.filter((val)=> {return (val.text.type === "CHAT") || (val.text.type === "WELCOME") || showGame }).map((val, i) => {
            return (

            <IonItem  key={i}>
                <IonLabel> <IonText className={"message-user " + (isHost(val.user) ? 'host' : '')}>{val.user}</IonText> : 
                <IonText className={"message-text " + (val.user === name ? 'user-message ' : 'other-message ') }> {val.text.content } </IonText>  
                </IonLabel>
            </IonItem>
            )
            ;
          })}
          <form onSubmit={handleSubmit}>
            <IonItem>
              <IonInput label="" value={message} onIonInput={(e) => setMessage(e.target.value)} fill="outline" placeholder="Enter Message"></IonInput> 
            </IonItem>
            <IonItem>
              <IonButton type="submit" >Send</IonButton> 
              <IonButton onClick={sendScan} >SCAN</IonButton>
              <IonButton onClick={() => {setShowChat(!showChat); }} >Close</IonButton> 
              <IonCheckbox checked={showGame} onClick={() => setShowGame(!showGame)} className={`showCheck`}  > </IonCheckbox>  
            </IonItem>
          </form>
    </IonList>
  );
};

export default Chat;
