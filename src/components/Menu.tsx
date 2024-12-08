import React, { useEffect, useState } from 'react';
import './Menu.css';
import ExploreContainer from './GameContainer';
import { IonButton, IonContent, IonInput, IonItem } from '@ionic/react';
import { Chapter } from './game/Game';

interface MenuItem {
  label: string;
  className:string;
  action: () => void;
}

interface MenuProps {
  items: MenuItem[];
}

const MenuComponent: React.FC<MenuProps> = ({ items }) => {
  return (
  <div className="MenuComponent">
    <ul>
      {items.map((item, index) => (
        <li className={"menu-item " + item.className} key={index} onClick={item.action}>
          <IonButton>{item.label}</IonButton>
        </li>
      ))}
    </ul>
  </div>
  );
};

const Menu: React.FC = () => {
  
  const [chapters, setChapters] = useState<Chapter[]>([]);
    const [state, setState] = useState('');
    const [number, setNumber] = useState(0);


    const [name, setName] = useState<any>("");
    const [room, setRoom] = useState<any>(""); // State to hold the room's name
    //const [ENDPOINT, setENDPOINT] = useState("http://localhost:5000");
    //const [ENDPOINT, setENDPOINT] = useState("http://192.168.1.14:5000");
    const [ENDPOINT, setENDPOINT] = useState("wss://quranquizz-server.onrender.com");
    
    //const [ENDPOINT, setENDPOINT] = useState("https://socketio-chat-h9jt.herokuapp.com");
    
    const [isConnected, setIsConnected] = useState(false);

    
  useEffect(() => {
    const fetchChapters = async () => {
      try {
        const response = await fetch('https://api.quran.com/api/v4/chapters');
        if (response.ok) {
          const data = await response.json();
          setChapters(data.chapters);
        } else {
          console.error('Failed to fetch chapters');
        }
      } catch (error) {
        console.error('Error fetching chapters:', error);
      }
    };

    fetchChapters();
  }, []);

  


  const menuItems = [
    { label: 'Entrainement',className:"local train", action: () => { setState('Training'); } },
    { label: 'Arcade',className:"local arcade", action:  () => { setState('Arcade'); } },
    { label: 'Survival',className:"local survie", action:  () => { setState('Survie'); } },
    { label: 'Online',className:"online", action: () => {setState('Online');} },
  ];

    const handleNameChange = (event: { target: { value: React.SetStateAction<string>; }; }) => {
        setName(event.target.value);
    };
    
    const handleRoomNameChange = (event: { target: { value: React.SetStateAction<string>; }; }) => {
        setRoom(event.target.value); // Update roomName state when input changes
    };
    const handleServerChange = (e: any) => {
        setENDPOINT(e.target.value);
    }

    const handleJoin = () => {
      if(name.length > 0 && room.length > 0){
        setIsConnected(true);
      }
    }
    
    /* 
   <Link
    onClick={(e) => (!name || !room ? e.preventDefault() : null)}
    to={`/chat?name=${name}&room=${room}`}
  >
  </Link>*/
  return (
    <div id="container">
        {(state !== 'Online' && state !== '') &&
            <ExploreContainer mode={state} chapters={chapters} location={{search: {name:"ME"}}} leave={() => {setState('');setIsConnected(false);}}/>
        }
        {(state === 'Online') &&
            <>  
            { !isConnected  && (
            <form onSubmit={handleJoin}>  
                <IonInput
                    placeholder="Enter room name"
                    fill="outline"
                    value={room}
                    onIonInput={(e) => setRoom(e.target.value)}
                />
                <IonInput
                    placeholder="Enter player name"
                    fill="outline"
                    value={name}
                    onIonInput={(e) => setName(e.target.value) }
                />
              <IonItem>
                  <IonButton onClick={handleJoin}>Join/Create Room</IonButton>
                  <IonButton className="menu-button return" onClick={() => {setState('');setIsConnected(false);}}>Return</IonButton>
              </IonItem>
            </form>
            )}
          
            { isConnected  && (
              <ExploreContainer  mode={state} chapters={chapters}  location={{search:{name,room,ENDPOINT} }} leave={() => {setState('');setIsConnected(false);}} />) }

            </>
        }
        
        {state === '' &&
            <MenuComponent items={menuItems} />
        }
    </div>
  );
};

export default Menu;