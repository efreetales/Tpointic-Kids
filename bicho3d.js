// Bichos em 3D no palco (three.js). Cada bicho listado em window.BICHOS_3D ganha um canvas no lugar do
// desenho. O jogo não precisa saber de nada: este módulo lê as classes do botão do bicho (talk, host, sing,
// dance, drowsy, yawn, sleep, snore) e o nível da voz (el._voz, posto pelo jogo) e anima tudo ao vivo,
// com transições suaves. Se o 3D falhar, o desenho continua.
import * as THREE from "three";
import { GLTFLoader } from "three/addons/loaders/GLTFLoader.js";

const LISTA = window.BICHOS_3D || {};
const reduzir = matchMedia("(prefers-reduced-motion: reduce)").matches;

// Ângulos em radianos, somados ao descanso. Braço: negativo desce, positivo sobe (o direito é espelhado em gira).
// Cabeça: X+ olha para cima, X- abaixa.
const BRACO_BAIXO = -1.2;

function suaviza(atual, alvo, dt, rapidez) { return atual + (alvo - atual) * (1 - Math.exp(-dt * rapidez)); }

async function montar(id, arquivo) {
  const botao = document.getElementById("c-" + id);
  if (!botao) return;
  const tela = document.createElement("canvas");
  tela.className = "bicho3d"; tela.setAttribute("aria-hidden", "true");
  let r;
  try { r = new THREE.WebGLRenderer({ canvas: tela, antialias: true, alpha: true, preserveDrawingBuffer: true }); }
  catch (e) { return; }                                         // sem WebGL: fica o desenho
  r.outputColorSpace = THREE.SRGBColorSpace;
  r.setPixelRatio(Math.min(devicePixelRatio, 2));

  const cena = new THREE.Scene();
  const ceu = new THREE.HemisphereLight(0xffffff, 0x9a8a70, 1.4); cena.add(ceu);
  const sol = new THREE.DirectionalLight(0xffffff, 2.2); sol.position.set(-1.2, 2.2, 2.4); cena.add(sol);
  const cam = new THREE.PerspectiveCamera(22, 1, 0.1, 20);
  cam.position.set(0, 0.55, 2.7); cam.lookAt(0, 0.5, 0);

  let g;
  try { g = await new GLTFLoader().loadAsync(arquivo); } catch (e) { console.warn("3D:", e); return; }
  const raiz = g.scene; cena.add(raiz);
  const ossos = {}; const bocas = [];
  raiz.traverse(o => {
    if (o.isBone) ossos[o.name.replace("mixamorig", "")] = o;
    if (o.isMesh && o.morphTargetDictionary) bocas.push(o);
    if (o.isMesh) o.frustumCulled = false;                        // ossos movem a malha para fora da caixa original
  });
  const palp = [raiz.getObjectByName("palpebra_E"), raiz.getObjectByName("palpebra_D")].filter(Boolean);
  const rest = {}; for (const [n, b] of Object.entries(ossos)) rest[n] = b.quaternion.clone();

  // Troca o desenho pelo canvas só depois de carregar.
  botao.insertBefore(tela, botao.firstChild);
  botao.classList.add("tem3d");

  // estado animado (tudo suavizado)
  const s = { boca: 0, bocejo: 0, olho: 0, cabX: 0, cabZ: 0, tronco: 0, bracoE: BRACO_BAIXO, bracoD: BRACO_BAIXO,
              bracoEz: 0, bracoDz: 0, pulo: 0, balanco: 0, alt: 0, luz: 1 };
  (window.__bichos3d ||= {})[id] = s;    // estado atual, para conferência no console
  let piscaAte = 0, proxPisca = 2 + Math.random() * 3, puloT = -1, ultimo = performance.now() / 1000;
  const eul = new THREE.Euler(), q = new THREE.Quaternion();
  // Todo giro é somado à pose de descanso do osso (apagar o descanso deforma os ombros).
  // Os braços são espelhados: o direito gira com o sinal trocado.
  const gira = (nome, x = 0, y = 0, z = 0) => {
    const b = ossos[nome]; if (!b) return;
    eul.set(x, y, z); q.setFromEuler(eul); b.quaternion.copy(rest[nome]).multiply(q);
  };
  // pulinho: quando a classe "sing" aparece, começa um pulo
  new MutationObserver(() => { if (botao.classList.contains("sing")) puloT = 0; })
    .observe(botao, { attributes: true, attributeFilter: ["class"] });

  function quadro() {
    requestAnimationFrame(quadro);
    if (document.hidden) return;
    const agora = performance.now() / 1000, dt = Math.min(0.05, agora - ultimo); ultimo = agora;
    const k = botao.classList;
    const dorme = k.contains("sleep"), ronca = k.contains("snore"), sono = k.contains("drowsy"), boceja = k.contains("yawn");
    const danca = k.contains("dance") && !reduzir, vez = k.contains("host");
    const beat = parseFloat(getComputedStyle(document.documentElement).getPropertyValue("--beat")) || 0.5;
    const voz = botao._voz || (k.contains("talk") ? 0.12 : 0);    // sem volume (voz sintetizada): usa "falando"

    // ---- alvos ----
    let alvo = { boca: 0, bocejo: 0, olho: 0, cabX: 0, cabZ: Math.sin(agora * 0.7) * 0.05, tronco: 0,
                 bracoE: BRACO_BAIXO, bracoD: BRACO_BAIXO, bracoEz: 0, bracoDz: 0, balanco: 0, alt: 0 };
    // falar/cantar: boca segue a voz; cabeça acompanha um pouco
    alvo.boca = Math.min(1, Math.max(0, (voz - 0.02) * 9));
    if (alvo.boca > 0.05) { alvo.cabX = -0.05 + alvo.boca * 0.06; }
    if (vez && !dorme) { alvo.bracoD = BRACO_BAIXO + 0.35 + Math.sin(agora * 3) * 0.12; alvo.cabZ = 0.08; }   // gesticula na vez dela
    if (danca) {
      const fase = (agora % beat) / beat, lado = Math.floor(agora / beat) % 2 ? 1 : -1;
      alvo.balanco = lado * 0.13;
      alvo.alt = Math.abs(Math.sin(Math.PI * fase)) * 0.035;
      alvo.bracoE = lado > 0 ? 1.3 : -0.3; alvo.bracoD = lado < 0 ? 1.3 : -0.3;      // um braço lá em cima, o outro embaixo, alternando
      alvo.cabZ = -lado * 0.12;
    }
    if (sono) { alvo.olho = 0.55; alvo.cabX = -0.22; alvo.bracoE = alvo.bracoD = BRACO_BAIXO - 0.05; alvo.tronco = 0.06; }
    if (boceja) { alvo.bocejo = 1; alvo.boca = 0; alvo.olho = 0.9; alvo.cabX = 0.18; alvo.bracoE = alvo.bracoD = 0.9; }
    if (dorme) {
      alvo.olho = 1; alvo.boca = 0; alvo.cabX = -0.35; alvo.cabZ = 0.15; alvo.tronco = 0.14;
      alvo.bracoE = alvo.bracoD = BRACO_BAIXO + 0.05; alvo.alt = -0.01;
    }
    // piscar de vez em quando (acordada)
    if (!dorme && !sono && !boceja) {
      proxPisca -= dt;
      if (proxPisca <= 0) { piscaAte = agora + 0.13; proxPisca = 2.5 + Math.random() * 3.5; }
      if (agora < piscaAte) alvo.olho = 1;
    }

    // ---- suaviza ----
    const R = (n, rap) => { s[n] = suaviza(s[n], alvo[n], dt, rap); };
    R("boca", 22); R("bocejo", 3); R("olho", agora < piscaAte ? 30 : 6); R("cabX", 5); R("cabZ", 4); R("tronco", 3);
    R("bracoE", 7); R("bracoD", 7); R("bracoEz", 6); R("bracoDz", 6); R("balanco", 8); R("alt", 12);
    s.luz = suaviza(s.luz, document.body.classList.contains("night") ? 0.45 : 1, dt, 0.6);

    // respiração (mais funda dormindo/roncando)
    const resp = Math.sin(agora * (dorme ? 1.4 : 2.2)) * (ronca ? 0.06 : dorme ? 0.04 : 0.02);
    // pulinho
    let pulo = 0;
    if (puloT >= 0) { puloT += dt; const f = puloT / 0.42; pulo = f < 1 ? Math.sin(Math.PI * f) * 0.09 : 0; if (f >= 1) puloT = -1; }

    // ---- aplica ----
    gira("Spine1", s.tronco + resp, 0, 0);
    gira("Head", s.cabX, 0, s.cabZ);
    gira("LeftArm", s.bracoE, 0, s.bracoEz);
    gira("RightArm", -s.bracoD, 0, -s.bracoDz);
    raiz.rotation.z = s.balanco;
    raiz.position.y = s.alt + pulo;
    for (const m of bocas) {
      m.morphTargetInfluences[m.morphTargetDictionary.boca_aberta] = s.boca;
      m.morphTargetInfluences[m.morphTargetDictionary.bocejo] = s.bocejo;
    }
    for (const p of palp) { p.rotation.x = THREE.MathUtils.degToRad(90 - 150 * s.olho); p.visible = s.olho > 0.02; }
    ceu.intensity = 1.4 * s.luz; sol.intensity = 2.2 * s.luz;

    // tamanho do canvas acompanha o botão
    const w = tela.clientWidth, h = tela.clientHeight;
    if (w && (tela.width !== Math.round(w * r.getPixelRatio()) || tela.height !== Math.round(h * r.getPixelRatio()))) {
      r.setSize(w, h, false); cam.aspect = w / h; cam.updateProjectionMatrix();
    }
    r.render(cena, cam);
  }
  quadro();
}

for (const [id, arquivo] of Object.entries(LISTA)) montar(id, arquivo);
