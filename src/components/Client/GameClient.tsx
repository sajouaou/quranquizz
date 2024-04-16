import React, { useState, useEffect, useRef } from "react";
import queryString from "query-string";
import io from "socket.io-client";
import "./GameClient.css"

let socket = null;

const Chat = ({ location }) => {
  const [name, setName] = useState("");
  const [room, setRoom] = useState("");
  const [messages, setMessages] = useState([]);
  const [message, setMessage] = useState("");
  const chatContainerRef = useRef(null);

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
    
        socket.emit("join", { name, room }, (error) => {
          if (error) {
            alert(error);
          }
        });

        socket.on("message", (message) => {
        setMessages((messages) => [...messages, message]);
        });
    }
  }, [location.search]);

  const handleSubmit = (e) => {
    e.preventDefault();
    if (message) {
      socket.emit("sendMessage", { message });
      setMessage("");
    } else alert("empty input");
  };

  return (
    <div>
       <div className="chat-container" ref={chatContainerRef}>
        <div className="chat-messages">
      {messages.map((val, i) => {
        return (
        <div className={"message " + (val.user === name ? 'user-message' : 'other-message')} key={i}>
            <div className="message-user">{val.user} :  </div>
            <div className="message-text"> {val.text}</div>
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
    </div>
  );
};

export default Chat;
