import { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'ionic.quranquizz',
  appName: 'quranquizz',
  webDir: 'dist',
  server: {
    androidScheme: 'https'
  }
,
  plugins: {
    CapacitorHttp: {
      enabled: true,
    },
  },
    android: {
       buildOptions: {
          keystorePath: 'c:\Users\Anxoi\.keystore\anxoKeyTest.jks',
          keystoreAlias: 'AnxoDev',
       }
    }
  };

export default config;
