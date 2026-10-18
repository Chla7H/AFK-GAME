const $ = (id) => document.getElementById(id);
const music = $('music');
let fadeTimer = null;
let wantPlay = false;

function report(status, extra) {
  fetch('https://tm_afk/audioStatus', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ status: status, extra: extra || '' })
  }).catch(() => {});
}

music.addEventListener('error', () => {
  const e = music.error;
  report('error', e ? ('code ' + e.code + ' ' + (e.message || '')) : 'unknown');
});
music.addEventListener('playing', () => report('playing', 'vol ' + music.volume));

function tryPlay(retries) {
  if (!wantPlay) return;
  const p = music.play();
  if (p && p.catch) {
    p.catch((err) => {
      report('play-blocked', String(err));
      if (retries > 0) setTimeout(() => tryPlay(retries - 1), 700);
    });
  }
}

function startMusic(cfg) {
  if (!cfg || !cfg.enabled) { report('disabled'); return; }
  clearInterval(fadeTimer);
  wantPlay = true;
  music.muted = false;
  music.src = cfg.file;
  music.loop = !!cfg.loop;
  music.volume = Math.min(1, Math.max(0, cfg.volume));
  music.currentTime = 0;
  music.load();
  tryPlay(5);
}

function stopMusic() {
  wantPlay = false;
  clearInterval(fadeTimer);
  fadeTimer = setInterval(() => {
    if (music.volume > 0.05) {
      music.volume = Math.max(0, music.volume - 0.05);
    } else {
      clearInterval(fadeTimer);
      music.pause();
      music.removeAttribute('src');
      music.load();
    }
  }, 40);
}

window.addEventListener('message', (e) => {
  const d = e.data;
  if (d.action === 'show') {
    $('title').textContent = d.title;
    $('subtitle').textContent = d.subtitle;
    $('hint').textContent = d.hint;
    if (d.showMessage) $('box').classList.remove('hidden');
    startMusic(d.music);
  } else if (d.action === 'hide') {
    $('box').classList.add('hidden');
    $('emote').textContent = '';
    stopMusic();
  } else if (d.action === 'emote') {
    $('emote').textContent = '♪ ' + d.label;
  } else if (d.action === 'musicToggle') {
    if (d.play) { wantPlay = true; clearInterval(fadeTimer); tryPlay(3); }
    else { wantPlay = false; music.pause(); }
  } else if (d.action === 'volume') {
    music.volume = Math.min(1, Math.max(0, d.volume));
  }
});
