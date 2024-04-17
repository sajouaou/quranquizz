import React, { useState, useEffect, useRef } from "react";
import queryString from "query-string";
import io from "socket.io-client";
import "./GameClient.css"
import { IonButton } from "@ionic/react";

let socket = null;

interface Player {
    name: string;
    isHost: boolean;
}

const Chat = ({ location }) => {
  const [name, setName] = useState("");
  const [room, setRoom] = useState("");
  const [messages, setMessages] = useState([]);
  const [message, setMessage] = useState("");
  const chatContainerRef = useRef(null);
  const [players, setPlayers] = useState([{name:"",isHost:false}]);

  const ENDPOINT = "http://localhost:5000";
  
  useEffect(() => {
    // Scroll to the bottom of the chat container whenever messages change
    chatContainerRef.current.scrollTop = chatContainerRef.current.scrollHeight;
  }, [messages]);


  useEffect(() => {
    if(socket === null){
        console.log("Test test JOIN");
        const { name, room } = queryString.parse(location.search);
        socket = io(ENDPOINT);
        setRoom(room);
        setName(name);
        const updatedPlayers = [...players]; // Créer une copie du tableau players
        updatedPlayers[0].name =    name; // Modifier la copie du tableau
        setPlayers(updatedPlayers); // Mettre à jour l'état avec la 
    
        socket.emit("join", { name, room }, (error) => {
          if (error) {
            alert(error);
          }
        });

        socket.on("message", (message) => {
            setMessages((messages) => [...messages, message]);
            if(message.text.type === "CHAT"){
                //setMessages((messages) => [...messages, message]);
            }
            else if(message.text.type === "GAME"){
                if(message.text.content === "SCAN"){
                    socket.emit("sendMessage", { message :{ content :`${name} sends infos`,userInfo:true, type:"GAME", playerInfo:players[0] }});
                }
            }
            else if(message.text.type === "WELCOME"){
                const updatedPlayers = [...players]; // Créer une copie du tableau players
                if(message.text.users.length < 1){
                    updatedPlayers[0].isHost =    true; // Modifier la copie du tableau
                }
                else {
                    message.text.users.forEach((x)=>{
                        updatedPlayers.push(x);
                    })
                }
                setPlayers(updatedPlayers); // Mettre à jour l'état avec la 
                console.log(updatedPlayers);
            }

        });

        socket.on("roomData", ({ users }) => {
           console.log(users);
            setUsers(users);
        });

    }
  }, [location.search]);

  const handleSubmit = (e) => {
    e.preventDefault();
    if (message) {
      socket.emit("sendMessage", { message :{ content :message, type:"CHAT"}});
      setMessage("");
    } else alert("empty input");
  };
  const sendScan = (e) => {
    e.preventDefault();
    socket.emit("sendMessage", { message :{ content :"SCAN", type:"GAME"}});
  };
  return (
    <div>
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
      </div>
      </div>
      <form action="" onSubmit={handleSubmit}>
        <input
          type="text"
          value={message}
          onChange={(e) => setMessage(e.target.value)}
        />
        <input type="submit" />
      </form>
      <IonButton onClick={sendScan} >SCAN</IonButton>
    </div>
  );
};

export default Chat;
