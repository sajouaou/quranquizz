import { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'ionic.quranquizz',
  appName: 'quranquizz',
  webDir: 'dist',
  server: {
    androidScheme: 'https'
  }
,
    android: {
       buildOptions: {
          keystorePath: 'c:\Users\Anxoi\.keystore\anxoKeyTest.jks',
          keystoreAlias: 'AnxoDev',
       }
    }
  };

export default config;
