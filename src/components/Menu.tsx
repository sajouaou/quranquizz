import React, { useState } from 'react';
import './Menu.css';
import ExploreContainer from '../components/ExploreContainer';

interface MenuItem {
  label: string;
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
          <li className="menu-button" key={index} onClick={item.action}>
            {item.label}
          </li>
        ))}
      </ul>
    </div>
  );
};

const Menu: React.FC = () => {
    const [state, setState] = useState('');
    const [number, setNumber] = useState(0);
  
  const handleOption1Click = () => {
    console.log('Option 1 clicked');
    setState('Training');
    // Mettez votre logique ou action ici
  };

  const handleOption2Click = () => {
    console.log('Option 2 clicked');
    setState('Survie');
    // Mettez votre logique ou action ici
  };

  const handleOption3Click = () => {
    console.log('Option 3 clicked');
    // Mettez votre logique ou action ici
  };

  const menuItems = [
    { label: 'Entrainement', action: handleOption1Click },
    { label: 'Survie', action: handleOption2Click },
    { label: '/////', action: handleOption3Click },
  ];

  return (
    <div id="container">
        {(state === 'Training' || state === 'Survie') &&
            <ExploreContainer mode={state}/>
        }
        {state === '' &&
            <MenuComponent items={menuItems} />
        }

        {state !== '' &&
            <button className="menu-button" onClick={() => setState('')}>Return</button>
        }
    </div>
  );
};

export default Menu;