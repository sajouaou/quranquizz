import { Redirect, Route } from 'react-router-dom';
import { IonApp, IonRouterOutlet, setupIonicReact } from '@ionic/react';
import { IonReactRouter } from '@ionic/react-router';
import Home from './pages/Home';
import Library from './pages/Library';
import OnlineLobby from './pages/OnlineLobby';
import LocalLobby from './pages/LocalLobby';
import Play from './pages/Play';
import StoriesHome from './pages/stories/StoriesHome';
import StoryPage from './pages/stories/StoryPage';
import StoryQuiz from './pages/stories/StoryQuiz';
import TimelineChallenge from './pages/stories/TimelineChallenge';

/* Core CSS required for Ionic components to work properly */
import '@ionic/react/css/core.css';

/* Basic CSS for apps built with Ionic */
import '@ionic/react/css/normalize.css';
import '@ionic/react/css/structure.css';
import '@ionic/react/css/typography.css';

/* Optional CSS utils that can be commented out */
import '@ionic/react/css/padding.css';
import '@ionic/react/css/float-elements.css';
import '@ionic/react/css/text-alignment.css';
import '@ionic/react/css/text-transformation.css';
import '@ionic/react/css/flex-utils.css';
import '@ionic/react/css/display.css';

/**
 * Ionic Dark Mode
 * -----------------------------------------------------
 * For more info, please see:
 * https://ionicframework.com/docs/theming/dark-mode
 */

/* import '@ionic/react/css/palettes/dark.always.css'; */
/* import '@ionic/react/css/palettes/dark.class.css'; */
import '@ionic/react/css/palettes/dark.system.css';

/* Theme variables */
import '@fontsource/amiri/400.css';
import './theme/variables.css';

setupIonicReact();

const App: React.FC = () => (
  <IonApp>
    <IonReactRouter>
      <IonRouterOutlet>
        <Route exact path="/home">
          <Home />
        </Route>
        <Route exact path="/online">
          <OnlineLobby />
        </Route>
        <Route exact path="/local">
          <LocalLobby />
        </Route>
        <Route exact path="/play/:mode">
          <Play />
        </Route>
        <Route exact path="/library">
          <Library />
        </Route>
        <Route exact path="/stories">
          <StoriesHome />
        </Route>
        <Route exact path="/stories/:id">
          <StoryPage />
        </Route>
        <Route exact path="/stories/:id/defi">
          <TimelineChallenge />
        </Route>
        <Route exact path="/quiz/recits">
          <StoryQuiz />
        </Route>
        <Route exact path="/">
          <Redirect to="/home" />
        </Route>
      </IonRouterOutlet>
    </IonReactRouter>
  </IonApp>
);

export default App;
