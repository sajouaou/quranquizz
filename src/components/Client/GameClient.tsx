import React, { useState, useEffect, useRef } from 'react';
import Player from '../Player';
import axios from "axios";



interface User {
    playerName: string;
}


axios.defaults.xsrfHeaderName = "X-CSRFTOKEN"; // Nom de l'en-tête CSRF côté Django
axios.defaults.xsrfCookieName = "csrftoken"; // Nom du cookie CSRF côté Django

interface GameClientProps 
{
  chapters: Chapter[]
}

interface Chapter {
    id: number;
    name_simple: string;
    verses_count: number;
  }


const GameClient: React.FC<GameClientProps> = ( { chapters }) => {
    const [players, setPlayers] = useState([{playerName:"",}]);
    const [roomName, setRoomName] = useState(""); // State to hold the room's name
    const [isConnected, setIsConnected] = useState(false);
  
    const handleNameChange = (event) => {
        const updatedPlayers = [...players]; // Créer une copie du tableau players
        updatedPlayers[0].playerName = event.target.value; // Modifier la copie du tableau
        setPlayers(updatedPlayers); // Mettre à jour l'état avec la nouvelle copie
    };
    
    const handleRoomNameChange = (event) => {
        setRoomName(event.target.value); // Update roomName state when input changes
    };

   const addPLayer = (player) => {
    const updatedPlayers = [...players]; // Créer une copie du tableau players
    updatedPlayers.push(player);
    setPlayers(updatedPlayers); // Mettre à jour l'état avec la nouvelle copie
    console.log(updatedPlayers);

   }

   const syncGame = (state) => {
    state.players.filter(player => {
        return !players.some(existingPlayer => existingPlayer.playerName === player.playerName);
    }).forEach(player => {
        console.log("NEW PLAYER");
        addPLayer(player);
    });

   }

   const loopSync = (roomName,player,connect) => {
    if(connect){
        axios.get(`http://127.0.0.1:8000/sync?roomName=${roomName}&player=${player}`)
        .then((res) => {
            console.log("LOOP DU RES");
            console.log(isConnected);
            console.log(isConnected);
            console.log(isConnected);
            console.log(isConnected);
            console.log(isConnected);
            syncGame(res.data);
            setTimeout(() => {loopSync(roomName,player,connect)},1000);
        });
    }
   }

  const handleJoinOrCreateRoom = () => {
    // Implement logic for joining/creating room here
    console.log("Joining or creating room:", roomName);
    console.log("Player:", players[0].playerName);
    if(roomName !== '' && players[0].playerName !== ''){
        const hostJson = JSON.stringify(players[0]);
        axios.get(`http://127.0.0.1:8000/create_room?roomName=${roomName}&player=${hostJson}`)
        .then((res) => {
            console.log(res.data);
            if(res.data.connected){
                // Connection réussis
                setIsConnected(true);
                console.log("INTERIEUR DU RES");
                console.log(isConnected);
                syncGame(res.data);
            }
            else {
                // Gere la connection 
            }
        });
        setTimeout(() => {loopSync(roomName,hostJson,true)},1000);
        console.log("Exterieur DU RES");
        console.log(isConnected);
    }
  };

    return (
      <div>
        {  !isConnected && (
            <>
            <input
                type="text"
                placeholder="Enter room name"
                value={roomName}
                onChange={handleRoomNameChange}
            />
                <input
                    type="text"
                    placeholder="Enter player name"
                    value={players[0].playerName}
                    onChange={handleNameChange}
                />
                <button onClick={handleJoinOrCreateRoom}>Join/Create Room</button>
                </>
        )
        }
      
         {
        players.map((player, index) => (
          <div className='control-container' key={index}>
            <div className='player'>
            <p>Player : {player.playerName}</p>
            </div>
          </div>
            ))
        }


      </div>

    );
};

export default GameClient;  
