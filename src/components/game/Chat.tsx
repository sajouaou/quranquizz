import { IonButton } from "@ionic/react";
import React, { useEffect, useState } from "react";


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
  const chatContainerRef = React.useRef<HTMLDivElement>(null);
  
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
    <div className="chat-container" ref={chatContainerRef}>
            <div className="chat-messages">
          {messages.filter((val)=> {return (val.text.type === "CHAT") || (val.text.type === "WELCOME") || showGame }).map((val, i) => {
            return (

            <div className={"message " + (val.user === name ? 'user-message ' : 'other-message ')  } key={i}>
                <div className={"message-user " + (isHost(val.user) ? 'host' : '')}>{val.user} :  </div>
                <div className="message-text"> {val.text.content } </div>
            </div>
            )
            ;
          })}
        
          <form action="" onSubmit={handleSubmit}>
            <input
              type="text"
              value={message}
              onChange={(e) => setMessage(e.target.value)}
            />
            <input type="submit" />
          </form>
          <IonButton onClick={sendScan} >SCAN</IonButton>
          <IonButton onClick={() => {setShowChat(!showChat); }} >Close</IonButton>
          <>
          <label className={`showCheck`}>
            <input type="checkbox" checked={showGame} onChange={() => setShowGame(!showGame)} />
            <span className="slider round"></span>
          </label>
          </>
          </div>
        </div>
  );
};

export default Chat;
