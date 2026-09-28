import React from 'react';
import { createRoot } from 'react-dom/client';
import App from './App';
import { Capacitor } from '@capacitor/core';
import { installAudioUnlock } from './hooks/useAudioPlayer';

installAudioUnlock();

// Web version: keep the app available offline (the native apps already are).
if (import.meta.env.PROD && 'serviceWorker' in navigator && !Capacitor.isNativePlatform()) {
  window.addEventListener('load', () => { navigator.serviceWorker.register('/sw.js').catch(() => {}); });
}

const container = document.getElementById('root');
const root = createRoot(container!);
root.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
