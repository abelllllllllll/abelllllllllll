const { chromium } = require('playwright');
const { spawn } = require('child_process');
const path = require('path');
const [,, html, out, mode] = process.argv;
(async () => {
  const b = await chromium.launch();
  const p = await b.newPage({ viewport: { width: 1080, height: 1920 } });
  await p.goto('file://' + path.resolve(html));
  await p.evaluate(() => document.fonts.ready);
  await p.waitForTimeout(300);
  if (mode === 'stills') {
    for (const t of [1.5, 2.6, 5.8, 11.5, 15.5, 19.5]) {
      await p.evaluate(t => render(t), t);
      await p.screenshot({ path: `${out}/still_${t}.png` });
    }
  } else {
    const fps = 30, dur = 20;
    const ff = spawn('ffmpeg', ['-y','-f','image2pipe','-framerate',String(fps),'-i','-','-c:v','libx264','-pix_fmt','yuv420p','-crf','18','-preset','medium','-movflags','+faststart', out], { stdio: ['pipe','ignore','inherit'] });
    for (let i = 0; i < fps * dur; i++) {
      await p.evaluate(t => render(t), i / fps);
      const buf = await p.screenshot({ type: 'jpeg', quality: 95 });
      if (!ff.stdin.write(buf)) await new Promise(r => ff.stdin.once('drain', r));
    }
    ff.stdin.end();
    await new Promise(r => ff.on('close', r));
  }
  await b.close();
})();
