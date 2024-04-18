import { IonButton } from "@ionic/react";
import React, { useEffect } from "react";


interface ChatProps 
{
  messages: any[];
  name: string;
  message: string;
  showChat: boolean;

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
  handleSubmit,
  setMessage,
  setShowChat,
  sendScan
}) => {
  const chatContainerRef = React.useRef<HTMLDivElement>(null);
  
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
          {messages.map((val, i) => {
            return (
            <div className={"message " + (val.user === name ? 'user-message' : 'other-message')} key={i}>
                <div className="message-user">{val.user} :  </div>
                <div className="message-text"> {val.text.content}</div>
            </div>
            );
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
          </div>
        </div>
  );
};

export default Chat;
