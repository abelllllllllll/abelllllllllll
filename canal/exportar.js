// Exporta avatar, banner y miniaturas a PNG: node canal/exportar.js
const { chromium } = require('playwright');
const path = require('path');
const piezas = { avatar: [800, 800], banner: [2560, 1440], ep1: [1280, 720], ep2: [1280, 720], ep3: [1280, 720], ep4: [1280, 720], ep5: [1280, 720] };
(async () => {
  const b = await chromium.launch();
  for (const [k, [w, h]] of Object.entries(piezas)) {
    const p = await b.newPage({ viewport: { width: w, height: h } });
    await p.goto('file://' + path.resolve(__dirname, 'piezas.html') + '#' + k);
    await p.evaluate(() => document.fonts.ready); await p.waitForTimeout(200);
    await p.screenshot({ path: path.join(__dirname, 'imagenes', k + '.png') });
    await p.close();
  }
  await b.close();
})();
