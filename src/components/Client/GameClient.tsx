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
// TODO si possible deplacer la logique reseau ou message Managment ici
const Chat = ({  }) => {
  return (
    <div>
    </div>
  );
};

export default Chat;
