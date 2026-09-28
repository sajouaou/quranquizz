import {
  IonBackButton, IonButton, IonButtons, IonContent, IonHeader, IonIcon, IonItem, IonLabel,
  IonList, IonListHeader, IonNote, IonPage, IonProgressBar, IonRadio, IonRadioGroup, IonSearchbar,
  IonSegment, IonSegmentButton, IonSpinner, IonTitle, IonToggle, IonToolbar, useIonAlert, useIonToast,
} from '@ionic/react';
import { checkmarkCircle, cloudDownloadOutline, playCircleOutline, stopCircleOutline, trashOutline } from 'ionicons/icons';
import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { filterChapters } from '../components/user/SurahPicker';
import { useAudioPlayer } from '../hooks/useAudioPlayer';
import { useChapters } from '../hooks/useChapters';
import {
  clearAudioCache, deleteSurah, downloadSurah, formatBytes, getDownloadedSurahs, getStorageEstimate,
  isCacheSupported, requestPersistentStorage,
} from '../lib/audioCache';
import { setPrefs, usePrefs } from '../lib/prefs';
import { RECITERS, reciterLabel } from '../lib/quranApi';
import './Library.css';

interface Job {
  surahs: number[];
  index: number;
  done: number;
  total: number;
}

const Library: React.FC = () => {
  const { reciterId, autoCache } = usePrefs();
  const chapters = useChapters();
  const audio = useAudioPlayer();
  const [presentAlert] = useIonAlert();
  const [presentToast] = useIonToast();
  const [tab, setTab] = useState<'reciters' | 'offline'>('reciters');
  const [downloaded, setDownloaded] = useState<number[]>(() => getDownloadedSurahs(reciterId));
  const [usage, setUsage] = useState<string | null>(null);
  const [query, setQuery] = useState('');
  const [job, setJob] = useState<Job | null>(null);
  const abortRef = useRef<AbortController | null>(null);
  const [previewing, setPreviewing] = useState<number | null>(null);

  const refresh = useCallback(() => {
    setDownloaded(getDownloadedSurahs(reciterId));
    getStorageEstimate().then((e) => setUsage(e ? formatBytes(e.usage) : null));
  }, [reciterId]);

  useEffect(refresh, [refresh]);
  useEffect(() => () => abortRef.current?.abort(), []);

  const runDownload = async (surahs: number[]) => {
    const todo = surahs.filter((s) => !getDownloadedSurahs(reciterId).includes(s));
    if (todo.length === 0) return;
    const controller = new AbortController();
    abortRef.current = controller;
    requestPersistentStorage();
    let failed = 0;
    for (let i = 0; i < todo.length; i++) {
      if (controller.signal.aborted) break;
      setJob({ surahs: todo, index: i, done: 0, total: 0 });
      try {
        await downloadSurah(reciterId, todo[i], (done, total) => setJob({ surahs: todo, index: i, done, total }), controller.signal);
      } catch {
        if (controller.signal.aborted) break;
        failed++;
      }
      refresh();
    }
    setJob(null);
    abortRef.current = null;
    refresh();
    if (failed > 0) {
      presentToast({ message: `${failed} sourate(s) n'ont pas pu être téléchargées. Vérifie ta connexion.`, duration: 3000, color: 'danger' });
    } else if (!controller.signal.aborted) {
      presentToast({ message: 'Téléchargement terminé : disponible hors-ligne.', duration: 2000, color: 'success' });
    }
  };

  const confirmBulk = (label: string, surahs: number[]) => {
    presentAlert({
      header: `Télécharger ${label} ?`,
      message: `${surahs.length} sourates pour ${reciterLabel(RECITERS.find((r) => r.id === reciterId))}. Prévois une connexion Wi-Fi.`,
      buttons: [
        { text: 'Annuler', role: 'cancel' },
        { text: 'Télécharger', handler: () => { runDownload(surahs); } },
      ],
    });
  };

  const remove = async (surah: number) => {
    await deleteSurah(reciterId, surah);
    refresh();
  };

  const clearAll = () => {
    presentAlert({
      header: 'Tout supprimer ?',
      message: "Toutes les récitations enregistrées sur l'appareil seront effacées.",
      buttons: [
        { text: 'Annuler', role: 'cancel' },
        { text: 'Supprimer', role: 'destructive', handler: () => { clearAudioCache().then(refresh); } },
      ],
    });
  };

  // Plays Al-Fatihah 1:1 with this reciter, without changing the chosen one.
  const preview = (id: number) => {
    if (previewing === id && (audio.status === 'playing' || audio.status === 'loading')) {
      audio.stop();
      setPreviewing(null);
      return;
    }
    setPreviewing(id);
    audio.load(1, 0, 1, id);
  };

  const visible = useMemo(() => filterChapters(chapters, query), [chapters, query]);
  const busy = job !== null;

  return (
    <IonPage>
      <IonHeader>
        <IonToolbar>
          <IonButtons slot="start">
            <IonBackButton defaultHref="/home" text="" />
          </IonButtons>
          <IonTitle>Récitateurs & hors-ligne</IonTitle>
        </IonToolbar>
        <IonToolbar>
          <IonSegment value={tab} onIonChange={(e) => setTab(e.detail.value as 'reciters' | 'offline')}>
            <IonSegmentButton value="reciters"><IonLabel>Récitateurs</IonLabel></IonSegmentButton>
            <IonSegmentButton value="offline"><IonLabel>Hors-ligne</IonLabel></IonSegmentButton>
          </IonSegment>
        </IonToolbar>
        {job && <IonProgressBar value={job.total ? job.done / job.total : 0} />}
      </IonHeader>

      <IonContent>
        {tab === 'reciters' && (
          <IonList inset>
            <IonListHeader><IonLabel>Choisis la voix utilisée pendant les parties</IonLabel></IonListHeader>
            <IonRadioGroup value={reciterId} onIonChange={(e) => setPrefs({ reciterId: Number(e.detail.value) })}>
              {RECITERS.map((r) => (
                <IonItem key={r.id}>
                  <IonButton slot="start" fill="clear" aria-label={`Écouter ${r.name}`} onClick={() => preview(r.id)}>
                    <IonIcon slot="icon-only"
                      icon={previewing === r.id && audio.status === 'playing' ? stopCircleOutline : playCircleOutline} />
                  </IonButton>
                  <IonRadio value={r.id} justify="space-between">
                    <IonLabel>
                      <h2>{r.name}</h2>
                      {r.style && <p>{r.style}</p>}
                      {getDownloadedSurahs(r.id).length > 0 && (
                        <p className="offline-count">{getDownloadedSurahs(r.id).length} sourate(s) hors-ligne</p>
                      )}
                    </IonLabel>
                  </IonRadio>
                  {previewing === r.id && audio.status === 'loading' && <IonSpinner slot="end" name="dots" />}
                </IonItem>
              ))}
            </IonRadioGroup>
          </IonList>
        )}

        {tab === 'offline' && (
          <>
            {!isCacheSupported() && (
              <p className="library-warning">Le stockage hors-ligne n'est pas disponible sur ce navigateur.</p>
            )}
            <IonList inset>
              <IonItem>
                <IonToggle checked={autoCache} onIonChange={(e) => setPrefs({ autoCache: e.detail.checked })}>
                  <IonLabel>
                    Garder les ayat écoutées
                    <IonNote className="setting-hint">Chaque verset joué est conservé pour rejouer sans connexion</IonNote>
                  </IonLabel>
                </IonToggle>
              </IonItem>
              <IonItem>
                <IonLabel>
                  Récitateur
                  <IonNote className="setting-hint">{reciterLabel(RECITERS.find((r) => r.id === reciterId))}</IonNote>
                </IonLabel>
                <IonNote slot="end">{downloaded.length} / 114</IonNote>
              </IonItem>
              {usage && (
                <IonItem>
                  <IonLabel>Espace utilisé</IonLabel>
                  <IonNote slot="end">{usage}</IonNote>
                </IonItem>
              )}
            </IonList>

            <div className="bulk-actions">
              {busy ? (
                <IonButton expand="block" color="medium" onClick={() => abortRef.current?.abort()}>
                  Arrêter ({job.index + 1}/{job.surahs.length} · {job.done}/{job.total} ayat)
                </IonButton>
              ) : (
                <>
                  <IonButton fill="outline" onClick={() => confirmBulk("Juz' 'Amma", Array.from({ length: 37 }, (_, i) => 78 + i))}>
                    Juz' 'Amma (78–114)
                  </IonButton>
                  <IonButton fill="outline" onClick={() => confirmBulk('tout le Coran', Array.from({ length: 114 }, (_, i) => i + 1))}>
                    Tout le Coran
                  </IonButton>
                  <IonButton fill="clear" color="danger" onClick={clearAll}>Tout effacer</IonButton>
                </>
              )}
            </div>

            <IonSearchbar value={query} placeholder="Rechercher une sourate" onIonInput={(e) => setQuery(e.detail.value ?? '')} />
            <IonList>
              {visible.map((chapter) => {
                const isDone = downloaded.includes(chapter.id);
                const isCurrent = job?.surahs[job.index] === chapter.id;
                return (
                  <IonItem key={chapter.id}>
                    <span className="surah-number" slot="start">{chapter.id}</span>
                    <IonLabel>
                      <h2>{chapter.name_simple} {chapter.name_arabic && <span className="arabic">{chapter.name_arabic}</span>}</h2>
                      <p>
                        {isCurrent && job ? `Téléchargement… ${job.done}/${job.total}` : `${chapter.verses_count} versets`}
                      </p>
                    </IonLabel>
                    {isCurrent ? (
                      <IonSpinner slot="end" name="crescent" />
                    ) : isDone ? (
                      <>
                        <IonIcon slot="end" icon={checkmarkCircle} color="success" aria-label="Disponible hors-ligne" />
                        <IonButton slot="end" fill="clear" color="medium" disabled={busy} aria-label="Supprimer" onClick={() => remove(chapter.id)}>
                          <IonIcon slot="icon-only" icon={trashOutline} />
                        </IonButton>
                      </>
                    ) : (
                      <IonButton slot="end" fill="clear" disabled={busy || !isCacheSupported()} aria-label="Télécharger" onClick={() => runDownload([chapter.id])}>
                        <IonIcon slot="icon-only" icon={cloudDownloadOutline} />
                      </IonButton>
                    )}
                  </IonItem>
                );
              })}
            </IonList>
          </>
        )}
      </IonContent>
    </IonPage>
  );
};

export default Library;
