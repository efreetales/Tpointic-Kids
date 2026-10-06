// Grava o jogo sozinho (Chrome sem janela, controlado pelo protocolo de depuração) para o vídeo de divulgação.
// Salva os quadros (frames/), quando cada um chegou (quadros.json), os sons que tocaram (sons.json)
// e as marcas de cada cena (marcas.json). Depois o monta_video.py edita tudo.
// Uso: node grava.mjs   (com o jogo servido em http://localhost:8000)
import { spawn } from "node:child_process";
import fs from "node:fs";
import path from "node:path";

const PASTA = path.dirname(new URL(import.meta.url).pathname).replace(/^\/([A-Z]:)/, "$1");
const FRAMES = path.join(PASTA, "frames");
fs.rmSync(FRAMES, { recursive: true, force: true }); fs.mkdirSync(FRAMES, { recursive: true });
const PERFIL = path.join(PASTA, "perfil_chrome");
fs.rmSync(PERFIL, { recursive: true, force: true });

const chrome = spawn("C:/Program Files/Google/Chrome/Application/chrome.exe", [
  "--headless=new", "--remote-debugging-port=9333", `--user-data-dir=${PERFIL}`,
  "--autoplay-policy=no-user-gesture-required", "--mute-audio", "--hide-scrollbars",
  "--window-size=540,675", "--force-device-scale-factor=2", "about:blank"], { stdio: "ignore" });
const espera = ms => new Promise(r => setTimeout(r, ms));

let alvo = null;
for (let i = 0; i < 40 && !alvo; i++) {
  await espera(250);
  try { alvo = (await (await fetch("http://127.0.0.1:9333/json/list")).json()).find(t => t.type === "page"); } catch (e) {}
}
const ws = new WebSocket(alvo.webSocketDebuggerUrl);
await new Promise(r => ws.addEventListener("open", r, { once: true }));
let id = 0; const pendentes = new Map();
const cdp = (method, params = {}) => new Promise((ok, erro) => {
  const n = ++id; pendentes.set(n, { ok, erro }); ws.send(JSON.stringify({ id: n, method, params }));
});
const quadros = [];
ws.addEventListener("message", ev => {
  const m = JSON.parse(ev.data);
  if (m.id && pendentes.has(m.id)) { const p = pendentes.get(m.id); pendentes.delete(m.id); m.error ? p.erro(new Error(m.error.message)) : p.ok(m.result); return; }
  if (m.method === "Page.screencastFrame") {
    const n = quadros.length;
    fs.writeFileSync(path.join(FRAMES, String(n).padStart(6, "0") + ".jpg"), Buffer.from(m.params.data, "base64"));
    quadros.push(Date.now());
    ws.send(JSON.stringify({ id: ++id, method: "Page.screencastFrameAck", params: { sessionId: m.params.sessionId } }));
  }
});

// Gancho que roda antes do jogo: anota cada som (nome do arquivo, hora, tom, volume, quando parou).
const gancho = `(() => {
  const nomes = new WeakMap(); window.__sons = [];
  const f0 = window.fetch;
  window.fetch = async (...a) => { const r = await f0(...a); const url = String(a[0]);
    if (/\\.mp3$/.test(url)) { const ab0 = r.arrayBuffer.bind(r); r.arrayBuffer = async () => { const ab = await ab0(); nomes.set(ab, url.split("/").pop().replace(".mp3", "")); return ab; }; }
    return r; };
  const d0 = BaseAudioContext.prototype.decodeAudioData;
  BaseAudioContext.prototype.decodeAudioData = function(ab, ok, erro) { const nome = nomes.get(ab);
    return d0.call(this, ab, b => { if (b && nome) b.__nome = nome; ok && ok(b); }, erro); };
  const c0 = AudioNode.prototype.connect;
  AudioNode.prototype.connect = function(dest, ...r) { if (this instanceof AudioBufferSourceNode && dest instanceof GainNode) this.__ganho = dest; return c0.call(this, dest, ...r); };
  const s0 = AudioBufferSourceNode.prototype.start;
  AudioBufferSourceNode.prototype.start = function(quando = 0, offset = 0, ...r) {
    if (this.buffer && this.buffer.__nome) { const ctx = this.context;
      const ev = { nome: this.buffer.__nome, t: Date.now() + Math.max(0, quando - ctx.currentTime) * 1000, offset, rate: this.playbackRate.value,
        loop: this.loop, ganho: this.__ganho ? this.__ganho.gain.value : 1 };
      window.__sons.push(ev); this.__ev = ev;
      this.addEventListener("ended", () => { if (!ev.fim) ev.fim = Date.now(); }); }
    return s0.call(this, quando, offset, ...r); };
  const p0 = AudioScheduledSourceNode.prototype.stop;
  AudioScheduledSourceNode.prototype.stop = function(quando = 0) { if (this.__ev && !this.__ev.fim) { const ctx = this.context; this.__ev.fim = Date.now() + Math.max(0, quando - ctx.currentTime) * 1000; } return p0.call(this, quando); };
  window.__marcas = []; window.marca = n => window.__marcas.push([n, Date.now()]);
})();`;

await cdp("Page.enable"); await cdp("Runtime.enable");
await cdp("Emulation.setDeviceMetricsOverride", { width: 540, height: 675, deviceScaleFactor: 2, mobile: false });
await cdp("Page.addScriptToEvaluateOnNewDocument", { source: gancho });
await cdp("Page.navigate", { url: "http://localhost:8000/?gravacao=" + Date.now() });
await espera(3500);
await cdp("Page.startScreencast", { format: "jpeg", quality: 90, maxWidth: 1080, maxHeight: 1350, everyNthFrame: 1 });

const roda = async codigo => {
  const r = await cdp("Runtime.evaluate", { expression: `(async () => { ${codigo} })()`, awaitPromise: true, returnByValue: true });
  if (r.exceptionDetails) throw new Error(JSON.stringify(r.exceptionDetails).slice(0, 400));
  return r.result.value;
};

// Utilidades dentro da página: esperar, legenda e cartão final.
await roda(`
  window.w = ms => new Promise(r => setTimeout(r, ms));
  const css = document.createElement("style");
  css.textContent = \`
    .legenda{position:fixed;left:14px;right:14px;bottom:12px;z-index:50;text-align:center;font-family:"Baloo 2",sans-serif;font-weight:800;
      font-size:21px;line-height:1.15;color:#24323F;background:#FFD25A;border:3px solid #24323F;border-radius:18px;padding:8px 12px;
      box-shadow:0 4px 0 #24323F;animation:legIn .35s ease-out both}
    .legenda small{display:block;font-family:Nunito,sans-serif;font-weight:800;font-size:14px;margin-top:2px}
    @keyframes legIn{from{transform:translateY(30px);opacity:0}to{transform:none;opacity:1}}
    .cartaz{position:fixed;inset:0;z-index:60;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:12px;
      background:#7CC56B url("imagens/cenario_floresta.webp") center/cover;text-align:center;padding:24px;animation:cartazIn .5s ease-out both}
    .cartaz .caixa{background:#FFFDF6;border:4px solid #24323F;border-radius:26px;box-shadow:0 6px 0 #24323F;padding:18px 20px;max-width:440px}
    .cartaz h1{font-family:"Baloo 2",sans-serif;font-weight:800;font-size:44px;line-height:1;margin:0;color:#24323F}
    .cartaz h1 span{color:#F2785C}
    .cartaz p{font-family:Nunito,sans-serif;font-weight:800;font-size:18px;margin:8px 0 0;color:#24323F}
    .cartaz .link{display:inline-block;margin-top:12px;background:#FFD25A;border:3px solid #24323F;border-radius:999px;padding:6px 16px;font-size:20px}
    .cartaz .turma{display:flex;gap:6px;justify-content:center}
    .cartaz .turma svg{width:96px;height:96px;overflow:visible}
    @keyframes cartazIn{from{opacity:0}to{opacity:1}}
    /* só no vídeo: sem o rodapé dos pais e a barra de músicas (as legendas explicam); espaço embaixo para a legenda */
    .foot,.musicbar{display:none!important}
    .app{height:calc(100% - 74px)!important}
    .video-sem-banda .stage{display:none!important}\`;
  document.head.appendChild(css);
  window.legenda = (t, sub) => { document.querySelectorAll(".legenda").forEach(x => x.remove());
    if (!t) return; const d = document.createElement("div"); d.className = "legenda"; d.innerHTML = t + (sub ? "<small>" + sub + "</small>" : ""); document.body.appendChild(d); };
  window.cartaz = (html) => { const d = document.createElement("div"); d.className = "cartaz"; d.innerHTML = html; document.body.appendChild(d); return d; };
  window.turma = () => ["caca","zeca","nina","tuca"].map(id => document.querySelector("#c-" + id + " svg").outerHTML).join("");
  window.toque = el => { const r = el.getBoundingClientRect(), o = { bubbles: true, clientX: r.x + r.width / 2, clientY: r.y + r.height / 2, pointerId: 1, isPrimary: true };
    el.dispatchEvent(new PointerEvent("pointerdown", o)); el.dispatchEvent(new PointerEvent("pointerup", o)); };
  return "ok";`);

// ---------- Roteiro ----------
// 1) Abertura: cartaz com a turma
await roda(`marca("abertura");
  const c = cartaz('<div class="turma">' + turma() + '</div><div class="caixa"><h1>Bicharada <span>Cantante</span></h1><p>Um jogo para contar, cantar e brincar com as sílabas</p></div>');
  await w(3200); c.remove(); return 1;`);
// 2) Jogo: pergunta, sílabas, contagem e vitória
await roda(`marca("inicio"); legenda("Toque em Brincar e a turma começa!"); await w(1200);
  document.getElementById("startBtn").click(); marca("brincar");
  for (let i = 0; i < 40 && !document.querySelector(".fruit.big"); i++) await w(200);
  marca("pergunta"); legenda("“Que fruta é essa?”", "a criança responde falando ou tocando");
  await w(2600); document.querySelector(".fruit.big").click(); marca("resposta");
  legenda("O bichinho fala sílaba por sílaba", "e as sílabas acendem na tela");
  for (let i = 0; i < 60 && !document.querySelector(".fruit[data-kind]"); i++) await w(200);
  marca("contar"); legenda("Pega as frutas e conta junto!"); await w(2300);
  const ms = [...document.querySelectorAll(".fruit[data-kind='manga']")];
  ms[0].click(); marca("conta1"); await w(1300); ms[1].click(); marca("conta2");
  for (let i = 0; i < 80 && !document.getElementById("field").classList.contains("singing"); i++) await w(200);
  marca("vitoria"); legenda("Cada acerto vira festa", "música original, karaokê e palmas no ritmo");
  for (let i = 0; i < 120 && !document.querySelector("#stage .critter.passo-vibra"); i++) await w(100);
  marca("vibra"); await w(3000); legenda(null); marca("fimvitoria");
  await w(1500);
  document.getElementById("homeBtn").click(); await w(200); document.getElementById("homeSim").click(); await w(1200);
  return 1;`);
// 3) Cantinho da Cacá
await roda(`marca("pet"); legenda("Na tela inicial, a Cacá vem brincar"); await w(800);
  document.getElementById("c-caca").click(); await w(4300);
  document.body.classList.add("video-sem-banda"); await w(300);   // no vídeo, o palco da Cacá ocupa a tela toda
  marca("enfeitar"); legenda("Enfeitar…");
  for (const id of ["palha", "oculos_coracao", "colar_flores"]) { document.querySelector('[data-enfeite="' + id + '"]').click(); await w(1500); }
  await w(900);
  [...document.querySelectorAll(".pet-aba")].find(b => b.dataset.aba === "comer").click(); await w(400);
  marca("comer"); legenda("…dar frutinhas…"); toque(document.querySelector('[data-fruta="banana"]')); await w(8200);
  [...document.querySelectorAll(".pet-aba")].find(b => b.dataset.aba === "brincar").click(); await w(300);
  marca("bolhas"); legenda("…e brincar!"); document.querySelector('[data-brinca="bolhas"]').click(); await w(1800);
  for (let k = 0; k < 4; k++) { const b = document.querySelector(".pet-bolha:not(.estoura)"); if (b) b.dispatchEvent(new PointerEvent("pointerdown", { bubbles: true })); await w(450); }
  await w(800); marca("bola"); document.querySelector('[data-brinca="bola"]').click(); await w(2600);
  marca("fimpet"); legenda(null); document.body.classList.remove("video-sem-banda");
  document.getElementById("homeBtn").click(); await w(800);
  return 1;`);
// 4) Música tema com o "Balança o bumbum"
await roda(`marca("tema"); legenda("Videoclipe e coreografia", "no “Balança o bumbum”, todo mundo vira e rebola!");
  document.getElementById("btnTema").click(); await w(34500); marca("fimtema");
  document.getElementById("btnTema").click(); legenda(null); await w(800); return 1;`);
// 5) Hora de dormir (anoitecer, bocejos e ronco)
await roda(`marca("ninar"); legenda("E no fim, hora de dormir 🌙");
  document.getElementById("btnNinar").click(); await w(68000); marca("fimninar"); return 1;`);
// 6) Cartaz final
await roda(`legenda(null); document.getElementById("btnNinar").click(); await w(300); marca("final");
  cartaz('<div class="turma">' + turma() + '</div><div class="caixa"><h1>Bicharada <span>Cantante</span></h1><p>MVP em teste com crianças de 2 a 5 anos.<br>Jogue e me conte como foi!</p><div class="link">tpointic-kids.vercel.app</div></div>');
  await w(4500); marca("fim"); return 1;`);

await cdp("Page.stopScreencast"); await espera(300);
const sons = await roda(`return window.__sons;`);
const marcas = await roda(`return window.__marcas;`);
fs.writeFileSync(path.join(PASTA, "quadros.json"), JSON.stringify(quadros));
fs.writeFileSync(path.join(PASTA, "sons.json"), JSON.stringify(sons, null, 1));
fs.writeFileSync(path.join(PASTA, "marcas.json"), JSON.stringify(marcas, null, 1));
console.log("quadros", quadros.length, "sons", sons.length, "marcas", marcas.length);
ws.close(); chrome.kill();
process.exit(0);
