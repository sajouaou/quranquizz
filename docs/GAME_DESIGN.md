# Quran Quizz — game design

This document covers four things:

- an analysis of the game;
- the user stories behind the current features;
- the rules that keep the content respectful of Islam;
- how multiplayer works, with or without a server.

## 1. Analysis

### Core loop

1. A verse (ayah) is recited.
2. The player names the surah, and optionally the verse number.
3. The result is shown with the right answer, then the next recitation starts.

Everything else (modes, rules, multiplayer) is built on this loop. It is short, based on
listening, and it rewards what the player has already learned, whether by heart or from
the meaning.

### Strengths

- **Learning through play**: every round is a moment of listening to the Qur'an.
  Revealing the answer teaches, it does not punish.
- **Simple rules**: the host sets the surah range, verse range, number of rounds and lives.
  The same settings suit a child learning Juz' 'Amma and a hafiz.
- **Family play**: the multiplayer mode suits evenings together, study circles (halaqa)
  and classrooms.

### Weaknesses found and addressed

| Problem | What was done |
|---|---|
| Only a guessing game: nothing to learn when you don't know yet | **Story mode**: listen to complete stories with a summary and a lesson, then take challenges on them |
| Multiplayer depended on a single free server, which sleeps when idle | **Local game over peer-to-peer WebRTC**: no server, works on a phone hotspot without Internet |
| The website needed the network | Service worker: the web app opens offline once it has been visited |
| Audio needed the network | Reciters can be downloaded, and verses already heard are kept |
| Fragile network code (crashes, stuck rounds) | Server rewritten; client edge cases covered by tests (see the pull requests) |

## 2. User stories

### Implemented

- As a **learner**, I want to hear a whole Qur'anic story with its reference and a short
  summary, so that I understand what I recite.
  Covered by: `/stories/:id` with a player that plays the story's verses in order, pause and
  previous/next verse, and "listened" progress.
- As a **learner**, I want to find where a verse sits in a story I know, so that I
  memorise its order.
  Covered by: "Situe l'ayah" (`/stories/:id/defi`). Five verses are placed on a timeline,
  with 0 to 3 points per verse and up to 3 stars per story.
- As a **player**, I want to recognise which story a recited verse comes from.
  Covered by: "Quel récit ?" (`/quiz/recits`), 10 multiple-choice questions, with a personal record.
- As a **family with no Internet** (on a trip, or at a centre without Wi-Fi), we want to play
  together on our phones.
  Covered by: **Partie locale**. One phone hosts; the others pair by scanning a QR code in
  each direction (or pasting the code). This works on the same Wi-Fi or on a phone hotspot.
- As a **host**, I want to let a latecomer in during the game without restarting.
  Covered by: "Ajouter un joueur" in the game header. The newcomer enters the round in progress.
- As a **teacher**, I want to share a room link with students.
  Covered by: the "Inviter des amis" button in online mode.
- As a **player on a train**, I want the recitations to play offline.
  Covered by: downloading surahs, Juz' 'Amma or the whole Qur'an per reciter.

### Backlog (ideas that keep the same spirit)

- **Pass-and-play**: several players on one device, taking turns (no network at all).
- **Hifz review**: spaced repetition that asks more often about the surahs a player gets wrong.
- **Story episodes**: split long stories (Yusuf, Musa) into scenes to learn their order.
- **Tafsir links**: open an approved tafsir at the verse of each story.
- **Other languages**: the interface is in French; English and Arabic would open the app to more families.

## 3. Content guidelines (adab)

These rules apply to everything added to the app:

- **The Qur'an is recited, never reproduced by hand.** No Arabic Qur'an text is typed in the
  code. The app plays recitations from quran.com. Quotes shown in French are labelled
  "sens approximatif de x:y", meaning they give the sense of a verse and are not a translation
  presented as the Qur'an.
- **Stories stay with the text.** Summaries relate what the verses say. Details from outside
  the Qur'an are limited to what the authentic Sunnah or tafsir state, and are marked
  ("selon la Sunna", "selon le tafsir"), for example al-Khiḍr or the army of Abraha. No
  Isrā'īliyyāt, and no invented dialogue.
- **No images of prophets or people.** Stories are shown with text, calligraphy and icons only.
- **Honorifics**: عليه السلام after the prophets, عليها السلام after Maryam, ﷺ after the
  Prophet Muhammad.
- **No music and no sound effects** over or between recitations: the only sound is the
  recitation. Feedback uses vibration and colour.
- **Listen respectfully**: the story player reminds the listener of 7:204. The game never
  mocks a wrong answer: the right answer is shown so it can be learned.
- **Fair competition only**: no bets, no paid or random rewards (no loot boxes), no ads. Stars
  and records only measure what has been learned.
- **Privacy**: no accounts. Preferences, records and progress stay on the device. A local game
  sends nothing to any server.

### Story catalog

The ranges are checked by `src/data/stories.test.ts`: every range exists, and stories from the
same surah do not overlap.

| Story | Reference | Lesson |
|---|---|---|
| Adam et le repentir | 2:30–39 | 2:37 |
| L'appel patient de Nuh | 71:1–28 | 71:10–11 |
| Hud et le peuple de ʿĀd | 11:50–60 | 11:56 |
| Salih et la chamelle | 11:61–68 | 11:61 |
| Ibrahim et les idoles | 21:51–70 | 21:69 |
| Yusuf, le plus beau des récits | 12:4–101 | 12:90 |
| Musa, du feu sacré à la mer | 20:9–79 | 20:25–28 |
| Sulayman, la fourmi et la huppe | 27:15–44 | 27:19 |
| La patience d'Ayyub | 38:41–44 | 38:44 |
| Yunus dans les ténèbres | 37:139–148 | 21:87 |
| L'invocation de Zakariya | 19:2–15 | 19:4 |
| Maryam et la naissance de ʿIsa | 19:16–33 | 19:30 |
| Les gens de la Caverne | 18:9–26 | 18:10 |
| Les conseils de Luqman | 31:12–19 | 31:13 |
| Talut et Jalut | 2:246–251 | 2:249 |
| Musa et le serviteur savant | 18:60–82 | 18:69 |
| Dhul-Qarnayn | 18:83–98 | 18:98 |
| Les gens du jardin | 68:17–33 | 68:29 |
| Qarun et ses trésors | 28:76–82 | 28:77 |
| L'armée de l'éléphant | 105:1–5 | 105:1 |

The summaries were written with care. They should still be reviewed by someone with knowledge
(an imam or a teacher) before the release.

## 4. Multiplayer architecture

The game engine only knows one thing about the network. A **relay** receives each player's
message `{ message, game, players }` and delivers `{ user, text }` to every player, the sender
included, in the same order for everyone. Every client replays that ordered list; the host's
client runs the round logic. So a different relay can be swapped in without touching the game.

```
             Online (server)                       Local (peer-to-peer, no server)

   phone A ─┐                                   phone B ─── WebRTC ───┐
   phone B ─┼── WebSocket ──► relay server      phone C ─── WebRTC ───┼──► phone A = host
   phone C ─┘                (Render)                                  │     runs the relay
                                                                       └──   in the app
```

- `src/lib/net/link.ts`: `RoomLink`, the interface the game uses. `WebSocketLink` is the
  implementation that talks to the server.
- `src/lib/net/relay.ts`: the relay rules, ported from `quranquizz_server`: ordering, host
  election, late joiners, duplicate names, settings accepted from the host only.
- `src/lib/net/p2p.ts`: `HostLink` (the relay plus the host's own player) and `GuestLink`
  (a data channel to the host).
- `src/lib/net/webrtc.ts` and `signal.ts`: serverless pairing.
  1. The host creates an offer and waits for its network candidates.
  2. The offer is compressed (deflate) into a code of about 550 characters (`QQ1.z…`), shown
     as a QR code.
  3. The guest scans it and shows its answer code; the host scans that back.
  4. A data channel opens directly between the two devices.

### Limits and choices

- **One QR exchange per guest.** Without a server there is no other way to exchange
  connection details. The codes can also be sent through a messaging app.
- **The host is the relay.** If the host leaves, the game ends for everyone and players are
  told so. If a guest drops, the game goes on, and the guest can pair again to take their
  place back.
- **Networks.** On the same Wi-Fi or a phone hotspot, devices connect directly, even without
  Internet. Across the Internet, public STUN servers are tried to get through routers; some
  networks (symmetric NAT, strict corporate Wi-Fi) will still need the online mode.
- **Privacy.** A pairing code contains the device's network addresses: share it only with the
  people you are playing with. The data channel is encrypted (DTLS).
