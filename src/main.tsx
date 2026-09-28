import React from 'react';
import { createRoot } from 'react-dom/client';
import App from './App';
import { installAudioUnlock } from './hooks/useAudioPlayer';

installAudioUnlock();

const container = document.getElementById('root');
const root = createRoot(container!);
root.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
