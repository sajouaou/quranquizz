import React, { useEffect, useState } from 'react';
import './Menu.css';
import ExploreContainer from '../components/ExploreContainer';
import GameClient from './client/GameClient';
import { Link } from 'react-router-dom';
import { IonButton } from '@ionic/react';
import Chat from './client/GameClient';

interface MenuItem {
  label: string;
  action: () => void;
}

interface MenuProps {
  items: MenuItem[];
}

interface Chapter {
  id: number;
  name_simple: string;
  verses_count: number;
}



const MenuComponent: React.FC<MenuProps> = ({ items }) => {
  return (
    <div className="MenuComponent">
      <ul>
        {items.map((item, index) => (
          <li className="menu-button" key={index} onClick={item.action}>
            {item.label}
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


    const [name, setName] = useState("");
    const [room, setRoom] = useState(""); // State to hold the room's name
    const [ENDPOINT, setENDPOINT] = useState("http://192.168.1.14:5000");
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

  
  const handleOption1Click = () => {
    console.log('Option 1 clicked');
    setState('Training');
    // Mettez votre logique ou action ici
  };

  const handleOption2Click = () => {
    console.log('Option 2 clicked');
    setState('Online');
    // Mettez votre logique ou action ici
  };

  const handleOption3Click = () => {
    console.log('Option 3 clicked');
    // Mettez votre logique ou action ici
  };

  const menuItems = [
    { label: 'Entrainement', action: handleOption1Click },
    { label: '/////', action: handleOption2Click },
    { label: '/////', action: handleOption3Click },
  ];

    const handleNameChange = (event: { target: { value: React.SetStateAction<string>; }; }) => {
        setName(event.target.value);
    };
    
    const handleRoomNameChange = (event: { target: { value: React.SetStateAction<string>; }; }) => {
        setRoom(event.target.value); // Update roomName state when input changes
    };
    const handleServerChange = (e: { target: { value: React.SetStateAction<string>; }; }) => {
      setENDPOINT(e.target.value);
    }

    const handleJoin = () => {
      setIsConnected(true);
    }
    
    /* 
   <Link
    onClick={(e) => (!name || !room ? e.preventDefault() : null)}
    to={`/chat?name=${name}&room=${room}`}
  >
  </Link>*/
  return (
    <div id="container">
        {(state === 'Training' || state === 'Survie') &&
            <ExploreContainer mode={state} chapters={chapters} location={{search: null}}/>
        }
        {(state === 'Online') &&
            <>  
            { !isConnected  && (
            <>  
            <input
                type="text"
                placeholder="Enter room name"
                value={room}
                onChange={handleRoomNameChange}
            />
                <input
                    type="text"
                    placeholder="Enter player name"
                    value={name}
                    onChange={handleNameChange}
                />
                <input
                type="text"
                placeholder="Enter address of Server"
                value={ENDPOINT}
                onChange={handleServerChange}
            />
                  <IonButton type="submit" onClick={handleJoin}>Join/Create Room</IonButton>
                
                
            </>
          )}
          
          { isConnected  && (
              <ExploreContainer  mode={state} chapters={chapters}  location={{search:{name,room,ENDPOINT} }} />) }

            </>
        }

        {state === '' &&
            <MenuComponent items={menuItems} />
        }

        {state !== '' &&
            <button className="menu-button" onClick={() => {setState('');setIsConnected(false);}}>Return</button>
        }
    </div>
  );
};

export default Menu;