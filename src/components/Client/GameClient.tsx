import React, { useState, useEffect } from "react";
import queryString from "query-string";
import io from "socket.io-client";

let socket = null;

const Chat = ({ location }) => {
  const [name, setName] = useState("");
  const [room, setRoom] = useState("");
  const [messages, setMessages] = useState([]);
  const [message, setMessage] = useState("");

  const ENDPOINT = "http://localhost:5000";

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

  useEffect(() => {
    if(socket !== null){
        console.log("Test test MESSAGE");
    }
    // socket.on("roomData", ({ users }) => {
    //   console.log(users);
    //   setUsers(users);
    // });
  }, []);

  const handleSubmit = (e) => {
    e.preventDefault();
    if (message) {
      socket.emit("sendMessage", { message });
      setMessage("");
    } else alert("empty input");
  };

  return (
    <div>
      {messages.map((val, i) => {
        return (
          <div key={i}>
            {val.text}
            <br />
            <b>{val.user}</b>
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
    </div>
  );
};

export default Chat;
