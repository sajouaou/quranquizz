#!/usr/bin/env node
// Generates the store listing visuals in store/: icon, feature graphic and phone screenshots.
// Usage: node scripts/store-assets.cjs [--url http://localhost:5173] [--only icon,banner,shots]
//   Without --url, a Vite dev server is started for the time of the captures.
//   Needs Playwright: npm install --no-save playwright && npx playwright install chromium
// The screenshots play real rounds, so the recitations must be reachable (api.quran.com).
const { spawn } = require('node:child_process');
const fs = require('node:fs');
const path = require('node:path');

const ROOT = path.join(__dirname, '..');
const OUT = path.join(ROOT, 'store');
const SHOTS = path.join(OUT, 'screenshots');
const RAW = path.join(SHOTS, 'raw');
const PORT = 5199;

// 9:16, the ratio the Play Store expects for phone screenshots.
const PHONE = { width: 360, height: 640, scale: 3 }; // 1080 x 1920

const EMERALD = '#0f7a64';
const GOLD = '#c89b3c';
const CREAM = '#f4f1ea';

// Caption shown above each screenshot. `file` is also the name of the raw capture.
const CAPTIONS = [
  { file: '01-accueil', title: 'Écoute une récitation,<br>retrouve la sourate', sub: 'Quatre façons de jouer' },
  { file: '02-ecoute', title: 'Reconnais-tu<br>cette récitation ?', sub: 'Arcade · 10 manches' },
  { file: '03-bonne-reponse', title: 'Progresse<br>à chaque manche', sub: 'La réponse est donnée après chaque essai' },
  { file: '04-sourates', title: 'Les 114 sourates', sub: 'Recherche par nom ou par numéro' },
  { file: '05-recits', title: '20 récits du Coran<br>à écouter', sub: 'Prophètes, figures de foi, sagesse' },
  { file: '06-recit', title: 'Un résumé, une leçon,<br>la récitation', sub: 'Puis un défi pour situer chaque ayah' },
  { file: '07-partie-locale', title: 'Jouez à plusieurs,<br>même sans Internet', sub: "D'appareil à appareil, par code QR" },
  { file: '08-recitateurs', title: 'Choisis<br>ton récitateur', sub: '12 récitations, à télécharger pour jouer hors-ligne' },
];

// Demo progress, so the screens are not empty.
const SEED = {
  'qq.best': { Arcade: 8, Survie: 14, Qasas: 9 },
  'qq.prefs': { reciterId: 7, playerName: 'Maryam', autoCache: false },
  'qq.stories': {
    adam: { listened: true, stars: 3 }, nuh: { listened: true, stars: 2 }, hud: { listened: true, stars: 3 },
    ibrahim: { listened: true, stars: 3 }, yusuf: { listened: true, stars: 2 }, musa: { listened: true, stars: 1 },
    kahf: { listened: true, stars: 3 },
  },
};

const args = process.argv.slice(2);
const option = (name) => (args.includes(name) ? args[args.indexOf(name) + 1] : undefined);
const only = (option('--only') ?? 'icon,banner,shots').split(',');

let chromium;
try {
  ({ chromium } = require('playwright'));
} catch {
  console.error('Playwright is missing: npm install --no-save playwright && npx playwright install chromium');
  process.exit(1);
}

const dataUri = (file, type) => `data:${type};base64,${fs.readFileSync(file).toString('base64')}`;
// The logo is inlined, so that CSS can hide its background and keep the star only.
const LOGO = fs.readFileSync(path.join(ROOT, 'resources', 'logo.svg'), 'utf8');

// Eight-pointed star tile, drawn very lightly over the emerald background.
const PATTERN = `url("data:image/svg+xml,${encodeURIComponent(
  `<svg xmlns='http://www.w3.org/2000/svg' width='96' height='96' viewBox='0 0 96 96' fill='none' stroke='#fff' stroke-opacity='.07' stroke-width='1.5'>
    <rect x='24' y='24' width='48' height='48'/><rect x='24' y='24' width='48' height='48' transform='rotate(45 48 48)'/>
    <path d='M0 48h14M82 48h14M48 0v14M48 82v14'/>
  </svg>`,
)}")`;

const BASE_CSS = `
  * { box-sizing: border-box; margin: 0; }
  html, body { width: 100%; height: 100%; }
  body { font-family: system-ui, -apple-system, 'Segoe UI', Roboto, 'Noto Sans', sans-serif; overflow: hidden; }
  .emerald {
    background: ${PATTERN}, radial-gradient(90% 80% at 22% 12%, #17a085 0%, ${EMERALD} 42%, #0a4f41 100%);
    color: #fff;
  }
`;

async function render(browser, { width, height, html, file }) {
  const page = await browser.newPage({ viewport: { width, height }, deviceScaleFactor: 1 });
  await page.setContent(`<!doctype html><meta charset="utf-8"><style>${BASE_CSS}</style>${html}`);
  await page.evaluate(() => Promise.all([...document.images].map((img) => img.decode())));
  await page.screenshot({ path: file });
  await page.close();
  console.log('  ', path.relative(ROOT, file));
}

// Same picture as the launcher icon (scripts/app-icons.sh): the stores round the corners themselves.
async function icons(browser) {
  for (const size of [512, 1024]) {
    await render(browser, {
      width: size,
      height: size,
      file: path.join(OUT, `icon-${size}.png`),
      html: `<style>svg { display: block; width: 100%; height: 100%; }</style><body>${LOGO}</body>`,
    });
  }
}

async function banner(browser) {
  await render(browser, {
    width: 1024,
    height: 500,
    file: path.join(OUT, 'feature-graphic-1024x500.png'),
    html: `
      <style>
        body { display: flex; align-items: center; gap: 28px; padding: 0 60px 0 34px; }
        svg { flex: none; width: 420px; height: 420px; }
        #background { display: none; }
        h1 { font-size: 84px; font-weight: 800; letter-spacing: -.03em; line-height: 1; }
        .rule { width: 72px; height: 5px; border-radius: 3px; background: ${GOLD}; margin: 24px 0 22px; }
        p { font-size: 30px; line-height: 1.3; color: ${CREAM}; }
        .modes { display: flex; gap: 10px; margin-top: 28px; }
        .modes span { font-size: 19px; font-weight: 700; padding: 7px 16px; border-radius: 999px;
          background: rgba(255, 255, 255, .14); color: #fff; }
      </style>
      <body class="emerald">
        ${LOGO}
        <div>
          <h1>Quran Quizz</h1>
          <div class="rule"></div>
          <p>Écoute une récitation,<br>retrouve la sourate.</p>
          <div class="modes"><span>Arcade</span><span>Survie</span><span>Récits</span><span>Entre amis</span></div>
        </div>
      </body>`,
  });
}

// ---------------------------------------------------------------- screenshots

async function waitForServer(url) {
  for (let i = 0; i < 60; i++) {
    try {
      if ((await fetch(url)).ok) return;
    } catch {
      // not up yet
    }
    await new Promise((resolve) => setTimeout(resolve, 500));
  }
  throw new Error(`No answer from ${url}`);
}

const surahRequest = (page) => page.waitForRequest(/\/by_chapter\/\d+/, { timeout: 30000 });
const surahOf = (request) => Number(/\/by_chapter\/(\d+)/.exec(request.url())[1]);

// The url lists are kept in localStorage: dropping them makes every round ask the API,
// which is how the script learns the surah being recited.
const forgetUrls = (page) =>
  page.evaluate(() => Object.keys(localStorage).filter((k) => k.startsWith('qq.urls.')).forEach((k) => localStorage.removeItem(k)));

async function pickSurah(page, surah) {
  await page.locator('.surah-button').click();
  const modal = page.locator('ion-modal.show-modal');
  await modal.locator('ion-item', { has: page.locator(`.surah-number:text-is("${surah}")`) }).click();
  await modal.waitFor({ state: 'hidden' });
}

async function capture(page, name) {
  await page.waitForTimeout(600); // let the Ionic transitions settle
  await page.screenshot({ path: path.join(RAW, `${name}.png`) });
  console.log('  ', path.relative(ROOT, path.join(RAW, `${name}.png`)));
}

async function screenshots(browser, base) {
  const context = await browser.newContext({
    viewport: { width: PHONE.width, height: PHONE.height },
    deviceScaleFactor: PHONE.scale,
    locale: 'fr-FR',
    colorScheme: 'light',
    isMobile: true,
    hasTouch: true,
  });
  await context.addInitScript((seed) => {
    if (localStorage.getItem('qq.best')) return;
    Object.entries(seed).forEach(([key, value]) => localStorage.setItem(key, JSON.stringify(value)));
  }, SEED);
  const page = await context.newPage();
  const open = async (route) => {
    await page.goto(base + route);
    await page.waitForLoadState('networkidle');
  };

  await open('/home');
  await capture(page, '01-accueil');

  // Arcade: three rounds won, then the fourth one captured before and after the answer.
  await open('/play/Arcade');
  let request = surahRequest(page);
  await page.locator('ion-button', { hasText: 'Commencer' }).click();
  for (let round = 0; round < 4; round++) {
    const surah = surahOf(await request);
    await pickSurah(page, surah);
    // The script answers faster than a player would: let the previous result fade first.
    await page.locator('.feedback').waitFor({ state: 'hidden' });
    if (round === 3) {
      await page.locator('.audio-panel.status-playing').waitFor();
      await capture(page, '02-ecoute');
    }
    await forgetUrls(page);
    request = surahRequest(page);
    await page.locator('ion-button.confirm').click();
    await page.locator('.feedback-win').waitFor();
  }
  await capture(page, '03-bonne-reponse'); // the feedback stays 2.5 s
  await request;

  await page.locator('.surah-button').click();
  await page.locator('ion-modal.show-modal ion-item').first().waitFor();
  await capture(page, '04-sourates');

  await open('/stories');
  await capture(page, '05-recits');

  await open('/stories/yusuf');
  await capture(page, '06-recit');

  await open('/local');
  await page.locator('ion-button', { hasText: 'Héberger la partie' }).click();
  await page.locator('ion-button', { hasText: 'Ajouter un joueur' }).click();
  await page.locator('ion-modal.show-modal canvas, ion-modal.show-modal img, ion-modal.show-modal svg').first().waitFor();
  await capture(page, '07-partie-locale');

  await open('/library');
  await capture(page, '08-recitateurs');

  await context.close();
}

// Raw capture + caption on the emerald background.
async function captioned(browser) {
  for (const { file, title, sub } of CAPTIONS) {
    const raw = path.join(RAW, `${file}.png`);
    if (!fs.existsSync(raw)) continue;
    await render(browser, {
      width: 1080,
      height: 1920,
      file: path.join(SHOTS, `${file}.png`),
      html: `
        <style>
          body { display: flex; flex-direction: column; align-items: center; padding-top: 96px; text-align: center; }
          h1 { font-size: 70px; font-weight: 800; letter-spacing: -.025em; line-height: 1.12; }
          p { font-size: 34px; margin-top: 22px; color: #f1dfb4; }
          .phone { position: absolute; left: 140px; top: 430px; width: 800px; height: 1422px; border-radius: 56px;
            padding: 14px; background: #10201c; box-shadow: 0 30px 80px rgba(0, 0, 0, .45), 0 0 0 2px rgba(255, 255, 255, .12); }
          .phone img { width: 100%; height: 100%; border-radius: 42px; display: block; }
        </style>
        <body class="emerald">
          <h1>${title}</h1>
          <p>${sub}</p>
          <div class="phone"><img src="${dataUri(raw, 'image/png')}"></div>
        </body>`,
    });
  }
}

(async () => {
  fs.mkdirSync(RAW, { recursive: true });
  const browser = await chromium.launch({ args: ['--autoplay-policy=no-user-gesture-required', '--mute-audio'] });
  let server;
  try {
    if (only.includes('icon')) await icons(browser);
    if (only.includes('banner')) await banner(browser);
    if (only.includes('shots')) {
      let base = option('--url');
      if (!base) {
        base = `http://localhost:${PORT}`;
        const vite = path.join(ROOT, 'node_modules', 'vite', 'bin', 'vite.js');
        server = spawn(process.execPath, [vite, '--port', String(PORT), '--strictPort'], { cwd: ROOT, stdio: 'ignore' });
      }
      await waitForServer(base);
      await screenshots(browser, base);
      await captioned(browser);
    }
  } finally {
    await browser.close();
    server?.kill();
  }
})().catch((error) => {
  console.error(error);
  process.exit(1);
});
