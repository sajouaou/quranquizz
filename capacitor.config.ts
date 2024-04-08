import { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'ionic.quranquizz',
  appName: 'quranquizz',
  webDir: 'dist',
  server: {
    androidScheme: 'https'
  }
};

export default config;
