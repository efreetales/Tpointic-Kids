# Bicharada Cantante

Jogo web infantil (2 a 5 anos; antes 3 a 6, alinhado à divulgação em 2026-10-07) da empresa do Tales: contar frutas com quatro bichos brasileiros que falam e cantam.
O Tales não programa: explique em português simples, faça o trabalho técnico por ele e só peça o que exige ação dele.

## Arquivos desta pasta

| Arquivo | O que é |
| --- | --- |
| `index.html` | O jogo inteiro (HTML + CSS + JS num arquivo só). Carrega os áudios de `audios/` por caminho relativo. |
| `audios/` | 36 falas + 3 músicas em MP3. Nomes fixos, usados pelo jogo (lista `CLIP_NAMES` no `index.html`). |
| `gerar_audios.ps1` | Gera falas e músicas pela API do ElevenLabs. Aberto por `GERAR_AUDIOS.bat` (dois cliques). |
| `chave_elevenlabs.dat` | Chave da API, criptografada pelo Windows (DPAPI, só o usuário dele lê). Nunca imprima nem copie a chave. |
| `vozes_escolhidas.txt` | ID da voz de cada personagem (`caca`, `zeca`, `nina`, `tuca`). |
| `vozes_usadas.txt` | Voz que gerou os áudios atuais de cada personagem; se mudar, o script refaz as falas dele. |
| `refazer.txt` | Nomes de áudios (sem `.mp3`, um por linha) a refazer mesmo que já existam. O script esvazia ao terminar sem erros. |
| `erros.txt` | Erros da API registrados pelo script. |
| `ajustes_vozes.json` | Ajustes de voz por personagem (velocidade, estabilidade, semelhança, estilo) e textos de falas trocados. Lido pelo `gerar_audios.ps1` e pela tela de ajuste. |
| `AJUSTAR_VOZES.bat` / `ajustar_vozes.py` / `ajustar_vozes.html` | Tela para o Tales ajustar e ouvir vozes (servidor Python local em http://localhost:8765, só 127.0.0.1). Gera tentativas, "Usar no jogo" troca o áudio, "Salvar ajustes" grava no `ajustes_vozes.json`. A lista de falas é lida do `gerar_audios.ps1`. |
| `tentativas_vozes/` | Tentativas geradas pela tela. |
| `audios_antigos/` | Backup automático de cada áudio substituído pela tela. |
| `gerar_audios_bicharada.py` | Versão antiga em Python, não usada. |

## Como testar o jogo no computador

O jogo usa `fetch` para os áudios, que não funciona abrindo o arquivo direto (file://). Sirva a pasta:
`python -m http.server 8000` (ou `npx serve`) e abra http://localhost:8000.

## Personagens e roteiro

- Cacá (capivara), Zeca (sapo), Nina (oncinha), Tuca (tucano). Vozes criadas pelo Tales no ElevenLabs (plano Starter, uso comercial liberado).
- 5 rodadas fixas (`PLAN` no `index.html`): Cacá 2 mangas, Zeca 3 bananas, Nina 3 morangos, Tuca 4 uvas, Cacá 5 cajus.
- Falas: `abertura_nina`, `fim_caca`, `apresenta_*`, `oba_*`, `rN_pedido_*`, `rN_contaK_*`, `rN_erro_*`.
- Músicas: `m1_tema` (Festa na Floresta, enviada pelo Tales, 2 min 14 s), `m2_comemora` (toca a cada rodada certa), `m3_ninar` (fecha o jogo).
- Falas geradas com `eleven_v4` (campo `modelo` do `ajustes_vozes.json`; antes era `eleven_multilingual_v2`), velocidade 0,85–0,9, porque crianças pequenas precisam de fala calma. Cada fala tem marcações de emoção em inglês (bloco `$emocoes` do `gerar_audios.ps1`).

## Histórico

- 2026-10-05: `m2_comemora` refeita com a letra nova (12,1 s). Ela não era refeita porque o script ignorava o `refazer.txt` (pulava o arquivo existente sem erro) e ainda tinha a letra antiga; os dois foram corrigidos. O `index.html` ganhou `<!doctype html>` e `<meta charset="utf-8">`, sem eles os acentos apareciam quebrados.

- 2026-10-05: o Zeca falava embolado nas falas curtas. A transcrição automática do ElevenLabs entendia "Uma!" como "Oba!", "Duas!" como "O Wesley", "Três!" como "Tudish", e `oba_zeca` ("Uhuuu! Muito bem!") era só risada por 7,5 s. As frases longas dele e os outros bichos saíam certos. A causa é a voz dele, criada no Voice Design como "um pouco rouca" e com coaxar embutido. A correção foi estabilidade 0,90 e style 0 para o Zeca e o pedido da rodada como `previous_text` (contexto, não falado) nas contagens. O texto do oba virou "Muito bem!", porque "Uhuuu" vira risada. As 7 falas dele foram refeitas e conferidas pela transcrição.

## Como conferir falas sem ouvir

A transcrição do ElevenLabs (`POST /v1/speech-to-text`, `model_id=scribe_v1`, `language_code=por`, `tag_audio_events=true`) mostra se a fala saiu inteligível. Fala curta que volta errada, ou como [risada], precisa ser refeita.

- 2026-10-05: o Zeca trocava de voz. Com estabilidade 0,90, cerca de 1 em 3 gerações sai com outra voz, bem mais grave (tom mediano de ~125–140 Hz, contra ~400 Hz nas falas normais dele). O `r2_pedido_zeca` (primeira fala dele na partida) estava assim e foi refeito pela tela (400 Hz). O tom foi medido com um script de autocorrelação sobre o PCM do ffmpeg.
- 2026-10-05: o Tales pediu uma tela para ele mesmo ajustar as vozes, em vez de tentativa e erro do Claude. Foi criado o `AJUSTAR_VOZES.bat`.

- 2026-10-05: o Tales ajustou pela tela e trocou 20 falas. Ajustes salvos: Cacá (0,30/0,50/1,0/0,90) e Tuca (1,0/0,8/0,1/0,85). Textos novos em `ajustes_vozes.json`; os balões do `index.html` foram acertados para `oba_caca` e `r5_erro_caca`. Conferência: a transcrição entende todas, exceto `r1_conta1_caca` ("Uma" → "Toma") e `r3_conta1_nina` ("Um" → "Hum"). Nenhuma voz trocada.

- 2026-10-05: as bocas cantavam até no instrumental, e o karaokê era espalhado de forma igual pela música toda. Agora o `gerar_audios.ps1` cria `audios/<musica>.tempos.json` (palavras com início/fim, pela transcrição `scribe_v1` com tempos por palavra). Esse arquivo é refeito quando o mp3 fica mais novo que ele, então se o Tales trocar uma música, basta rodar o GERAR_AUDIOS.bat. No `index.html`, `singSync` abre a boca só dentro das palavras, por sílaba, e o karaokê do `m2` usa o início de cada palavra. Medido: no m2 as bocas abrem só entre 2,0 e 10,0 s, e as palavras acendem com até 0,03 s de diferença. As falas continuam com a boca pelo volume (`lipSync`). Obs.: no painel do navegador do app o requestAnimationFrame cai para ~3 quadros/s quando a janela não está em foco; para medir, troque-o por `setTimeout(cb,16)` na aba de teste.

- 2026-10-05: o Tales passou a letra oficial da música tema ("Pula, pula, a Cacá chegou!…", 3 estrofes + refrão "Balança o bumbum" + final "Ninguém fica na cuca!"). Ela está no `m1_tema` do `gerar_audios.ps1` e bate palavra por palavra com a transcrição da gravação.

- 2026-10-05: os bichos e as frutas foram redesenhados (SVG no `index.html`, `ART` e `FRUITS`). O estilo é de livro ilustrado impresso: helper `sh()` com traço no lugar e cor deslocada 2px (fresta de papel `#FFFDF6`). Bichos de corpo inteiro: Cacá com focinho largo e flor de ipê, Zeca com olhos saltados, Nina com rosetas de onça (`rosette()`), Tuca com bico de ponta preta. A boca aberta de cada um continua na classe `.mouth`. As frutas ficaram maiores, e as 5 aparecem no campo inicial. O jogo anterior está em `versoes_antigas/index_antes_visual.html`.

- 2026-10-05: nova etapa no começo de cada rodada. O bicho mostra a fruta da rodada grande e pergunta "Que fruta é essa? Fala pra mim!" (`rN_pergunta_*`). A criança responde tocando na fruta ou pelo microfone (veja a entrada sobre o microfone mais abaixo). Depois de 5 s sem toque, a fruta pulsa e o balão diz "Toque na fruta!". O bicho responde "É uma manga!" (`rN_resposta_*`) e começa a contagem (`startCounting()` no `index.html`). `r1_resposta_caca` saía com entonação de pergunta 3 vezes em 4 (os ajustes da Cacá são bem expressivos: estabilidade 0,30, estilo 1,0); `r3_resposta_nina` saía "É o morango". As duas foram refeitas com contexto até a transcrição sair certa.

- 2026-10-05: cenas novas no `index.html`.
  - Vitória (m2): `kidsHtml()` desenha um menino e uma menina no `#fruits` durante a música, pulando e batendo palmas a 0,5 s por batida (os braços giram no ombro, `.arm-l/.arm-r`).
  - Ninar (m3): o campo virou camadas `.scene` (céu, pôr do sol, noite, `.starfield`, sol, lua, grama). Com a classe `.night` (no `#field` e no `body`), o dia vira noite durante a introdução; `--dusk` é o tempo da primeira palavra cantada, 14,6 s. Cada bicho dorme (`.sleep`: olhos fechados por `closedEyes()` e "z" subindo) 0,5 s depois de a letra falar dele (`SLEEP_WORD`, sobre o `m3_ninar.tempos.json`). No fim da música todos roncam (`.snore`: respiração e "Zzz" grandes), e a tela "Que show!" aparece 5 s depois, escura e transparente. `wakeAll()` desfaz tudo ao jogar de novo.
  - Cuidado: a classe `.stars` é a da pontuação do topo; as estrelas do céu são `.starfield`.
  - Versão anterior: `versoes_antigas/index_antes_noite.html`.

- 2026-10-05: barra de músicas sempre visível, abaixo do palco, com os botões "Música tema", "Música de dormir" e "Pular música".
  - Tema e dormir alternam entre tocar e "Parar música" e pausam a partida (`interruptGame`). Ao acabar ou ao parar, `endSpecial` volta para onde estava: tela inicial, a mesma rodada desde a pergunta, ou a tela final.
  - Se a interrupção acontecer durante a vitória, a rodada conta como feita.
  - "Pular música" só fica ativo durante a vitória (`skipVictory`).
  - Os passos agendados da partida usam `later()`, que guarda o "número da vez" (`gen`); ao interromper, `gen++` e os passos antigos são ignorados. Todo novo `setTimeout` do fluxo do jogo deve usar `later()`.
  - `bedtime()` faz o anoitecer e o sono, e serve tanto ao fim do jogo quanto ao botão.
  - Na música tema, as crianças dançam no ritmo dela (`--beat` 0,536 s, 112 bpm).
  - O botão "Ouvir a Canção da Bicharada" da tela inicial saiu.
  - Versão anterior: `versoes_antigas/index_antes_barra_musicas.html`.

- 2026-10-05: hora de dormir mais caprichada.
  - Quando a letra fala do bicho, `fallAsleep()` faz: olhos pesados (`.drowsy`: meia pálpebra descendo em 1,1 s) → bocejo aos 0,5 s (`.yawn`: boca bem aberta, corpo esticado, som `sfx_bocejo`) → olhos fechados aos 2,5 s (`.sleep`), já respirando fundo (`breathe`, 2,8 s).
  - No fim da música, `snoreAll()` toca `sfx_ronco` em loop para cada bicho, defasados 0,7 s; o som some aos 12 s. A respiração (`.snore`) segue o ritmo do som (`--snore` = duração ÷ tom).
  - Cada bicho tem seu tom (`SFX_RATE`): Cacá 0,85, Zeca 1,0, Nina 1,2, Tuca 1,35.
  - Os efeitos vêm do ElevenLabs Sound Effects (`/v1/sound-generation`), na lista `$efeitos` do `gerar_audios.ps1`. A transcrição os reconheceu como [yawning] e [snoring].
  - Pelo botão "Música de dormir", o dia volta 13 s depois do fim da música, para o ronco tocar até sumir.
  - Versão anterior: `versoes_antigas/index_antes_bocejo.html`.

- 2026-10-05: o Tales achou o som do ronco "monstruoso". Ele foi tirado (`audios_antigos/sfx_ronco__monstruoso.mp3`) e saiu do `$efeitos`; o ronco agora é só visual. O bocejo caiu de 0,7 para 0,18 de volume, porque atrapalhava a música.
- 2026-10-05: microfone na pergunta da fruta. O Tales antes tinha escolhido não usar e depois pediu.
  - Botão 🎤 "Falar" ao lado da fruta (só aparece se o navegador tem `SpeechRecognition`/`webkitSpeechRecognition`). Escuta uma vez, `pt-BR`, 5 alternativas, e só quando alguém toca.
  - Usa `processLocally` (no aparelho) quando `SpeechRecognition.available` diz `available`; senão, usa o serviço do navegador (Google ou Apple). Isso está avisado no rodapé "Para pais".
  - `heardFruit()` procura o nome da fruta (singular ou plural, sem acento). Se for a certa, chama `answer()` (igual a tocar na fruta). Se for outra fruta: "Hmm, não é uma banana. Tenta de novo!". Se não ouviu nada: "Não ouvi direitinho…".
  - Testado com um reconhecedor falso no navegador; com voz de verdade, não foi testado.
  - Versão anterior: `versoes_antigas/index_antes_microfone.html`.

- 2026-10-05: o microfone passou a escutar sozinho, porque criança não toca em botão.
  - Escuta só na pergunta da fruta, começando 0,3 s depois de o bicho terminar de perguntar (para não ouvir a própria voz).
  - Escuta em ciclos (`listen()`, recomeça a cada fim de frase) até acertar ou passar `LISTEN_MAX` = 40 s; aí mostra "Toque na fruta!".
  - O ícone coral "Ouvindo" pulsa enquanto escuta; um adulto pode tocar nele para pausar ou religar.
  - A permissão é pedida no "Brincar" (`prepareMic()`, com `getUserMedia`, em paralelo, sem travar a abertura). Se negada ou se der erro fatal (`not-allowed`, `network`…), `micBlocked` e o jogo segue só por toque.
  - Avisos para o adulto na tela inicial (`.micnote`) e no rodapé.
  - Testado com reconhecedor falso: começa aos 3,4 s (a pergunta da Cacá tem 3,1 s); silêncio, fruta errada e acerto funcionam; para por volta de 45 s; com o microfone negado, não aparece.
  - No site publicado, o microfone exige HTTPS.
  - Versão anterior: `versoes_antigas/index_antes_microfone_automatico.html`.

- 2026-10-05: Cacá em 3D. O Tales criou o modelo no Tripo (`D:\downloads\caca 3d model.glb`; cópia de trabalho em `modelos_3d/caca_original.glb`, 59 MB).
  - O arquivo é uma malha única com 8 poses (2 fileiras de 4), sem esqueleto e sem animação, mais 9 barras separadoras. São 1,8 milhão de triângulos e 3 texturas de 4096 px.
  - `modelos_3d/separar.js` separa os pedaços que não se encostam (8 Cacás com cerca de 200 mil triângulos cada; as barras são descartadas). `modelos_3d/ver.html` é o visualizador (three.js 0.160 via jsdelivr).
  - Cada pose foi renderizada de frente (câmera ortográfica, a mesma escala para todas, quadro de 0,25, pés alinhados) em WebP 512 px com fundo transparente: `imagens/caca_<pose>.webp`, de 15 a 19 KB cada.
  - Poses: acenando, feliz (sem uso), dancando, pulando, sonolenta, dormindo, bocejando, falando.
  - No jogo, `SPRITES = { caca: true }`. A pose segue o estado do bicho (classes), via MutationObserver, nesta prioridade: dormindo > bocejando > sonolenta > dança (alterna dancando/pulando a cada `--beat`) > pulando (`.sing`, que agora termina em 450 ms) > falando (`.host`) > acenando.
  - Falando, a imagem dá uma balançadinha (não há boca para mexer). A imagem tem escala de 1,12 para ficar do tamanho dos outros.
  - Para salvar as renderizações do navegador, foi usado um servidor de trabalho temporário (porta 8767, servindo a pasta e aceitando POST), porque o navegador do app bloqueia envio para outra porta.
  - Próximos: Zeca, Nina e Tuca, quando o Tales mandar os modelos. O mesmo processo serve: `pedacos()` → render por pose → `SPRITES[id] = true`.
  - Versão anterior: `versoes_antigas/index_antes_caca_3d.html`.
- 2026-10-05: o Tales achou que as imagens 3D "saltam" e não mexem a boca. A Cacá voltou ao desenho (`SPRITES = {}`); as imagens e o mecanismo ficam guardados.
  - Caminho escolhido: 3D animado de verdade.
  - O Tales vai gerar no Tripo uma Cacá única, em pose neutra (em pé, braços afastados, boca fechada), leve (20 a 40 mil faces), em .glb.
  - O Claude fará esqueleto, boca e animações no Blender (por script) e colocará no jogo com three.js.
  - O Tales instalou o Blender 5.2.2 LTS em `D:\Blender\blender.exe`. Roda por script (`--background --factory-startup --python ...`) e importa .glb (`bpy.ops.import_scene.gltf`).
  - Falta o modelo novo da Cacá.

- 2026-10-06: Cacá 3D animada no jogo.
  - **Modelo:** gerado pelo Tales no Tripo a partir de uma imagem em pose T (Malha Smart P2.0, Quad, 15 mil polígonos, textura), com Rig Humanoide/Mixamo pelo Tripo (`modelos_3d/caca_rig.glb`, 65 ossos `mixamorig:*`).
  - **Rosto** (`modelos_3d/rosto_3d.py`, Blender 5.2 em `D:\Blender`, rodado em segundo plano):
    - corta a malha na linha da boca por um caminho de arestas alisado, colado na base dos dentes;
    - beiço com espessura (faixa marrom), "saquinho" preto fosco e língua;
    - formas-alvo `boca_aberta` (24°) e `bocejo` (38°); os cantos abrem menos (boca oval);
    - pálpebras ovais (meia esfera medida nos pontos pretos do olho, com cílios), num pivô preso ao osso `mixamorig:Head`; giram em X: `90 - 150*t` graus, escondidas quando `t < 0.02`.
    - Para gerar o .glb: `blender --background --factory-startup --python rosto_3d.py -- caca_rig.glb x.png fecha_max=150 saida_glb=modelos/caca.glb`.
  - **Jogo:** `modelos/caca.glb` (2,2 MB). `window.BICHOS_3D = { caca: "modelos/caca.glb" }` + `bicho3d.js` (módulo, three.js 0.160 por import map do jsdelivr).
    - O módulo põe um canvas no botão do bicho (classe `tem3d` esconde o desenho) e anima por código a partir das classes `talk/host/sing/dance/drowsy/yawn/sleep/snore` e de `botao._voz` (volume da voz, posto pelo `lipSync`/`singSync`).
    - Animações: respiração, piscar, boca pela voz, gesto na vez dela, pulinho, dança no `--beat`, sono, bocejo e dormindo. A luz diminui à noite.
    - Ossos no three.js perdem o ":" (`LeftArm`). Todo giro é somado ao descanso do osso (ângulo direto deformava os ombros). Braços em X: −1,2 = abaixado, + sobe; o direito é espelhado (sinal trocado). Cabeça: X− abaixa.
    - `window.__bichos3d.caca` mostra o estado (para conferência).
  - O painel do navegador do app desenha ~3 quadros/s fora de foco e o módulo para quando `document.hidden`; para testar, troque `requestAnimationFrame` por `setTimeout(16)` e mantenha o painel visível.
  - Versão anterior do jogo: `versoes_antigas/index_antes_caca3d_animada.html`.

- 2026-10-06: o Tales pausou o 3D ("bichos em 3D dão muito mais trabalho"; vai procurar outra forma). A Cacá voltou ao desenho: `window.BICHOS_3D = {}`. Com a lista vazia, o jogo nem carrega o `bicho3d.js`/three.js. Tudo continua guardado para retomar: `modelos/caca.glb`, `bicho3d.js`, `modelos_3d/` (scripts, .blend, testes). Para religar: `window.BICHOS_3D = { caca: "modelos/caca.glb" }`.

- 2026-10-06: bichos desenhados articulados (opção "2" escolhida pelo Tales; a opção "1", Character Animation Skill com Gemini, fica para frutas e visual mais rico).
  - No `ART`, cada bicho virou partes `parte(nome, ox, oy, …)` = `<g class="pt pt-NOME" style="transform-origin:…">`, com `transform-box:view-box`: `corpo`, `cabeca` (no sapo, só olhos e rosto), `braco-e`/`braco-d` (bracinhos novos, desenhados na frente da cabeça, `braco()`), `rabo` (Nina, Tuca), `asa` (Tuca).
  - Movimentos só em CSS (`ptRespira`, `ptCabeca`, `ptRabo`, `ptAsa` sempre).
    - `.host`: tchauzinho (`ptAceno`, uma vez) e cabeça conversando.
    - `.dance`: braços alternados e cabeça no `--beat`.
    - `.drowsy`/`.sleep`: cabeça pende. `.yawn`: braços para cima (±112°).
    - Ângulos dos braços: + gira o esquerdo para fora/cima e − o direito. Acima de ~120° (somado à abertura de repouso) o braço gruda na cabeça.
  - `prefers-reduced-motion` desliga as partes.
  - Versão anterior: `versoes_antigas/index_antes_bichos_articulados.html`.

- 2026-10-06: comemoração no fim da música da vitória. `comemora()` roda 0,15 s depois da última palavra cantada (pelo `m2_comemora.tempos.json`; ~10,2 s de 12,1 s): som `sfx_vibra` (crianças "Yay!" e palmas, ElevenLabs Sound Effects, 3,5 s, volume 0,8), 70 confetes espalhados por 1,2 s, pulinho dos quatro bichos e crianças do campo com `.vibra`. `victoryDone` só solta confete se a música foi pulada antes da comemoração. Versão anterior: `versoes_antigas/index_antes_ovacao.html`.

- 2026-10-06: resposta soletrada, para quem está aprendendo a ler.
  - As falas `rN_resposta_*` agora são "Essa é a manga! Man... ga... Manga!" ("essa é a / esse é o" evita o "um" que a Nina errava).
  - O `gerar_audios.ps1` faz o alinhamento (`/v1/forced-alignment`, texto + áudio) e salva `audios/rN_resposta_*.tempos.json`; é refeito quando o mp3 fica mais novo.
  - No jogo, `FRUITS[x].silabas` (MAN·GA, BA·NA·NA, MO·RAN·GO, U·VA, CA·JU) aparece em letra de forma embaixo da fruta (`soletra()`). Cada sílaba acende quando é falada; no fim elas se juntam na palavra inteira.
  - A 1ª geração da Cacá saiu "manga, manga" sem separar; uma nova geração do mesmo texto separou (a antiga está em `audios_antigos/r1_resposta_caca__junto.mp3`). Conferir sempre pela transcrição se as sílabas saíram separadas.
  - Versão anterior: `versoes_antigas/index_antes_silabas.html`.

- 2026-10-06: na música da vitória, as crianças desenhadas foram trocadas por um vídeo do Tales (os quatro bichos dançando na floresta, 2D).
  - Original: `D:\downloads\Bicharada 10-06 06_26_06\A_lively_2D_vector_cartoon_20261006033119.mp4` (1280×720, 10 s, com áudio, 6 MB).
  - No jogo: `videos/vitoria.mp4` (854×480, sem áudio, H.264, 1,3 MB, convertido com ffmpeg `-crf 26 -movflags +faststart`).
  - `sing()` põe `<video class="vitoria" muted playsinline>` direto no `#field`, ocupando o quadro inteiro (`object-fit:cover`, atrás da letra), e dá `play()`. Durante a música a letra fica sem cartão (branca com contorno; palavra cantada em amarelo) e a cesta some. No celular em pé, o vídeo (16:9) é cortado nas laterais. `clearSongScene()` remove o vídeo. O vídeo toca em `playbackRate = duração do vídeo ÷ duração da música` (10 s ÷ 12,07 s = 0,83) para terminar junto com a música (medido: vídeo acaba aos 12,1 s). Ele começa com a música e acaba aos 10 s, na comemoração, parado no último quadro.
  - `loadClips()` adianta o download do vídeo. As crianças continuam só na música tema (`playSpecial("tema")`).
  - Versão anterior: `versoes_antigas/index_antes_video_vitoria.html`.

- 2026-10-06: videoclipe da Canção da Bicharada, editado pelo Claude a partir dos vídeos do Tales em `D:\downloads\3` (video 1 70 s, video 2 60 s, e três de 10 s: Nina se escondendo, turma dançando, Zeca nas vitórias-régias).
  - `videos/montar_clipe.py` (ffmpeg) tem a lista de cortes (EDL) presa aos versos, pelos tempos de `m1_tema.tempos.json`. Ex.: "Zeca Sapo dá um salto" → Zeca pulando nas vitórias-régias; "se esconde atrás da mangueira" → Nina atrás da mangueira; "Olha pro céu" → Tuca voando.
  - Corta as telas "Made with Google Flow Music", a moldura branca (v1 23–31 s, zoom 0,88) e a borda lilás do video 2 (zoom 0,94). O último quadro fica parado no encerramento instrumental e escurece no fim.
  - Gera `videos/clipe_cancao_da_bicharada.mp4` (1280×720, com a música, 134 s, 43 MB, para assistir/compartilhar) e `videos/tema.mp4` (640×360, sem som, 6 MB, para o jogo).
  - No jogo, o botão "Música tema" usa `poeVideo("videos/tema.mp4")` no quadro inteiro (as crianças saíram; `kidsHtml()` ficou sem uso).
  - `poeVideo()` (classe `video.clipe`) serve à vitória e ao tema.
  - Versão anterior: `versoes_antigas/index_antes_clipe_tema.html`.

- 2026-10-06: botão "Início" (casinha, `#homeBtn`) no topo, ao lado do som. Pergunta antes ("Voltar para o começo?", overlay `#confirmHome`), porque criança pode tocar sem querer; na tela inicial não faz nada. `voltarInicio()` para tudo (música do botão, vozes, microfone, sono, vídeo; `gen++` invalida os passos agendados), zera estrelas e volta à tela inicial com `frutasIniciais()`. Em telas ≤ 400 px as estrelas encolhem para caber. Versão anterior: `versoes_antigas/index_antes_botao_inicio.html`.

- 2026-10-06: teste de entonação. A conta (Starter) tem `eleven_v4`, `eleven_v4_turbo`, `eleven_v3` (todos com pt), além do `eleven_multilingual_v2` usado hoje.
  - `comparar_vozes/gerar_comparacao.ps1` gerou 8 falas (2 por bicho) em v3 e v4, com marcações de emoção em inglês (`[curious]`, `[excited]`, `[laughs]`…). No v3, a estabilidade só aceita 0 / 0,5 / 1.
  - A transcrição entendeu todas; nenhuma leu a marcação em voz alta, e o v4 riu no "[laughs]".
  - A medida de variação do tom ficou inconclusiva. A escolha é do Tales, de ouvido: `http://localhost:8000/comparar_vozes/comparar.html`.
- 2026-10-06: o Tales escolheu o **Eleven v4**. As 46 falas foram refeitas com emoção. Os áudios anteriores estão em `audios_antigos/antes_v4/`; os scripts anteriores, em `versoes_antigas/*_antes_v4.*`.
  - `gerar_audios.ps1`:
    - lê o `modelo`;
    - `$emocoes` dá o texto marcado de cada fala, que só é usado se, sem as marcações, for igual ao texto atual;
    - se o texto (ou o do Tales, em `textos`) já tiver `[...]`, ele vai do jeito que está;
    - no v2 as marcações são tiradas;
    - o alinhamento das sílabas usa o texto sem marcações.
  - No v4, a contagem vai **sem** o pedido como contexto (`previous_text`). Com contexto, "Duas!" saía como pergunta ("Duas?").
  - Na tela AJUSTAR_VOZES, cada fala já aparece com as marcações e pode ser editada; usa o modelo do json.
  - Transcrição: as 46 bateram com o texto. "Um!" aparece como "Hum!", mas soa igual em português.
  - "Man... ga..." a transcrição junta como "Manga", mas o áudio tem pausa entre as sílabas (2,64–2,82 s), igual ao "Ca... ju...", que ela separa. As 5 respostas foram realinhadas.

- 2026-10-06: **cantinho da Cacá** (bichinho virtual), no próprio quadro do jogo. Versão anterior: `versoes_antigas/index_antes_cantinho_caca.html`.
  - Quando abre: na tela inicial ou na tela do fim, tocar na Cacá da banda (tem um coraçãozinho pulando em cima dela) faz ela vir pulando para o meio do quadro (`abrePet`). Durante a partida, tocar nela continua só fazendo ela se apresentar. A tela inicial ganhou a frase "Ou toque na Cacá…".
  - Bandeja embaixo, com três abas:
    - **Enfeitar**: 14 enfeites desenhados (`ENFEITES`), em três lugares.
      - Cabeça: coroa de flores, flor grande, chapéu de palha, chapéu de festa, coroa, laço.
      - Olhos: óculos redondos, de coração, de estrela, escuros.
      - Pescoço: colar de contas, colar de flores, gravata borboleta, medalha.
      - Um enfeite por lugar; tocar de novo tira.
      - Os enfeites ficam salvos no aparelho (`localStorage` `bicharada.enfeites.caca`) e ela continua com eles na banda, inclusive no jogo.
      - O desenho da capivara tem os encaixes `data-slot` (cabeca/olhos/pescoco). O ipê da cabeça some quando ela usa um enfeite de cabeça.
    - **Comer**: a criança toca na fruta ou arrasta a fruta até a Cacá. A fruta voa até a boca, ela mastiga, diz "Hum, que delícia de X!" e soletra; as sílabas acendem no balão.
    - **Brincar**:
      - bola: ela dá uma cabeçada;
      - bolhas de sabão: a criança estoura;
      - dançar: um trecho da música da vitória, `m2_comemora`;
      - cócegas: também dá para fazer tocando nela.
  - Botão "Tchau": ela acena, se despede e volta pulando para a banda. O botão Início fecha o cantinho na hora, sem perguntar. As músicas da barra e o "Brincar" também fecham.
  - `critterEl(c)` devolve a Cacá do cantinho enquanto ele está aberto, então `hop`, `playClip`, a boca e a dança funcionam nela sem mudar mais nada.
  - 14 falas novas `pet_*_caca` (v4 com emoção), no gerador e no `CLIP_NAMES`. As `pet_come_*` têm tempos de sílaba (o alinhamento agora inclui `^pet_come_`).
    - Transcrição: todas certas.
    - "Man... ga..." e "U... va..." foram conferidos pela pausa no áudio; a uva foi refeita uma vez porque saiu grudada.
  - Ideias combinadas para depois:
    - etapa 2: pedidos por microfone com palavras-chave ("tô com fome", nome da fruta, "vamos brincar", "canta");
    - etapa 3: conversa com IA. Depende de custo, de autorização dos pais (LGPD) e de regras de segurança.
    - Repetir o cantinho para Zeca, Nina e Tuca. Os enfeites usam coordenadas da capivara; cada bicho vai precisar dos seus encaixes.

- 2026-10-06: **número grandão na contagem**: a cada fruta certa, o algarismo aparece enorme no meio do quadro, com a palavra embaixo ("1 / UMA"), e some em 1,6 s (`numerao()`, chamado no `tapFruit`). Cada número tem uma cor. Não bloqueia os toques (`pointer-events:none`). Versão anterior: `versoes_antigas/index_antes_numerao.html`.

- 2026-10-06: **passos de dança**. Versão anterior: `versoes_antigas/index_antes_passos_danca.html`.
  - Cada bicho ganhou o desenho **de costas** (`VERSO`). O SVG agora tem `<g class="frente">` e `<g class="verso">`, e a classe `.de-costas` troca entre os dois.
    - Na capivara de costas, o encaixe de cabeça é espelhado, então o chapéu aparece atrás.
    - Na oncinha de costas, o rabo aparece por cima do corpo.
    - No tucano de costas, o bico aparece virado para o outro lado.
  - O coreógrafo (`setInterval` de 250 ms, perto do fim do script) roda enquanto o bicho tem `.dance`: na vitória, na música tema e na dança do cantinho.
    - De tempos em tempos (3 a 8 tempos), cada bicho faz um passo no ritmo do `--beat`.
    - Em cerca de 35% das vezes, a turma toda faz o mesmo passo junto.
  - Os passos (classes `passo-*`) são:
    - **rodopio**: volta inteira com `rotateY`, mostrando as costas no meio;
    - **rebolado**: vira de costas, rebola 4 tempos (quadril e rabo) e vira de volta;
    - **palmas**: bracinhos batendo na frente da barriga; o tucano bate a asa;
    - **agachadinha**;
    - **passinho**: de lado;
    - **pulão**: braços para cima.
  - Quem prefere menos movimento no aparelho (`prefers-reduced-motion`) não vê os passos.

- 2026-10-06: **"Balança o bumbum" coreografado** na música tema: em cada refrão a turma toda vira de costas 0,4 s antes de "Balança" e rebola até o fim do segundo verso ("…tudo outra vez").
  - `trechosBumbum()` acha os versos nos tempos da música (`m1_tema.tempos.json`) e junta os versos seguidos. São 3 trechos: cerca de 25,5–33,4 s, 66–74 s e 101–109 s.
  - `rebolaTurma(ms)` chama `fazPasso(b, "rebolado", ms)` para todos que dançam.
  - Conferido no navegador: os 4 bichos ficaram de costas de 25,0 a 32,8 s.
  - Versão anterior: `versoes_antigas/index_antes_bumbum.html`.

- 2026-10-06: **palmas e troca de lugar**. Versão anterior: `versoes_antigas/index_antes_palmas_troca.html`.
  - **"Bata palmas"** na música da vitória e na dança do cantinho:
    - `palmasNaLetra()` acha os versos nos tempos de `m2_comemora` (cerca de 4,0 a 10,0 s) com `trechosLetra()`, a função genérica que também serve ao bumbum.
    - A turma faz `passo-palmas` junto: um ciclo por tempo, e as mãos se encontram na metade do ciclo.
    - Toca `sfx_palma` em cada tempo, no relógio do áudio. As palmas agendadas param no `stopClip()`.
  - **Palmas sorteadas** pelo coreógrafo também soam, mais baixo.
  - **Som da palma:** o Tales achou a primeira (seca) horrível e escolheu em `comparar_palmas/` a "Palma macia", com volume 0,7 e palma em todo tempo.
    - O arquivo é `opcao_macia.mp3` cortado em 0,35 s e com pico em -3 dB. A palma seca está em `audios_antigos/sfx_palma_seca.mp3`.
  - **Troca de lugar** na música tema: nos trechos só de música, quando há mais de 4 s sem palavra (42,8–49,9 s e 83,5–91,4 s, logo depois dos refrões), a banda troca de lugar pulando (`trocaLugares`, com animação FLIP).
    - A sequência é: troca em pares, troca de ponta a ponta e volta para a ordem normal.
    - O `clearSongScene` sempre devolve a ordem normal.

- 2026-10-06: **Tuca redesenhado** para ficar parecido com o tucano dos vídeos.
  - Peito e rosto amarelos, com topo da cabeça preto.
  - Bico verde-amarelado com manchas vermelha e azul e ponta vermelha.
  - Pés azuis.
  - O desenho de costas também foi atualizado.
  - Versão anterior: `versoes_antigas/index_antes_tucano_novo.html`.

- 2026-10-06: **cenário da floresta** no quadro principal. É o mesmo do videoclipe novo: `imagens/cenario_floresta.webp`, 1600 px, 140 KB, vindo da imagem que o Tales mandou.
  - Fica na camada `.floresta` da `.scene`, com `cover` centrado na clareira (72%). O sol de desenho foi escondido.
  - Na música de dormir, o pôr do sol e a noite pintam a floresta por cima (`mix-blend-mode: multiply`), e a lua e as estrelas ficam na frente.
  - Versão anterior: `versoes_antigas/index_antes_cenario_floresta.html`.

- 2026-10-06: **videoclipe novo da música tema**, feito pelo Tales (`D:\downloads\vide tema.mp4`, 1366×768, 134 s, com música).
  - A música do vídeo é idêntica ao `m1_tema.mp3` e começa no mesmo instante: correlação 1,0 e deslocamento 0, conferidos pelo envelope do áudio. Por isso karaokê, bocas, bumbum e troca de lugar continuam sincronizados.
  - O jogo usa `videos/clipe_tema.mp4` (854×480, sem som, 13,6 MB). O nome é novo para escapar do cache do navegador. O som continua vindo do `m1_tema` pelo WebAudio.
  - A cada 1 s, `sincroniza()` em `playSpecial` puxa o vídeo para a hora da música se a diferença passar de 0,3 s.
  - A montagem antiga (`montar_clipe.py`) gerou `videos/tema.mp4` e `clipe_cancao_da_bicharada.mp4`. Eles ficaram, mas não são mais usados no jogo.
  - Versão anterior do jogo: `versoes_antigas/index_antes_clipe_novo.html`.

- 2026-10-06: **sem vídeo na música da vitória**, a pedido do Tales. A cena agora é a floresta, a letra em karaokê por cima e a banda dançando (passos, palmas e confetes continuam). Saíram o `poeVideo("videos/vitoria.mp4")`, o ajuste de velocidade do vídeo e o pré-carregamento. O arquivo `videos/vitoria.mp4` ficou na pasta, sem uso. Versão anterior: `versoes_antigas/index_antes_sem_video_vitoria.html`.

- 2026-10-06: **comemoração no fim da vitória**: quando entra a torcida (`sfx_vibra`, cerca de 10,2 s depois do início), a turma toda faz o passo `vibra` por 3,4 s (`VIBRA_MS`): pulinhos rápidos, bracinhos para cima balançando, cabeça mexendo e boca aberta gritando. A cena só fecha depois da torcida (`afterSong` espera a comemoração; antes fechava em 12,4 s, no meio da torcida). No cantinho, a Cacá também vibra no fim da dança. Conferido no navegador: vibram de 10,2 a 13,6 s da música e a cena fecha logo depois. Versão anterior: `versoes_antigas/index_antes_vibra.html`.

- 2026-10-06: **Tuca de volta à versão anterior**, a pedido do Tales: peito creme, mancha azul no olho, bico laranja com ponta preta e pés laranja. O redesenho parecido com o vídeo ficou em `versoes_antigas/index_antes_caca_nova.html`.
- 2026-10-06: **Cacá redesenhada** pela referência do Tales (folha de poses da capivara do videoclipe).
  - O desenho de costas também foi atualizado.
  - Formas:
    - cabeça alta e quadradinha de cantos redondos;
    - orelhinhas pequenas e redondas em cima;
    - **focinho grande e escuro** ocupando a parte de baixo do rosto, com narinas;
    - barriga clara.
  - Rosto: sorriso simples; falando, a boca abre com a língua rosa.
  - **Flor rosa** (`florRosa`, cinco pétalas redondas) no lugar do ipê; continua na classe `.ipe-padrao`, que some quando ela usa enfeite de cabeça.
  - Cores: pelo `#C8915F`, focinho `#9E6D4C`, barriga `#F3CDA6`, pés `#8D5F43`.
  - Os olhos ficaram em y 38 e os enfeites continuam servindo (conferido com chapéu, óculos e colar). A fruta do cantinho mira na boca nova (76/120).
  - Versão anterior: `versoes_antigas/index_antes_caca_nova.html`.

- 2026-10-06: **focinho de roedor na Cacá**. O Tales achou o focinho anterior (retângulo escuro com contorno) estranho.
  - Agora é uma área mais escura e arredondada, sem contorno, que se alarga embaixo como um bulbo (`#A87252`), com um brilho em cima.
  - Tem duas narinas inclinadas e a boquinha de roedor em "ω": risquinho do nariz e lábio dividido (os dentinhos foram tirados a pedido do Tales).
  - Falando, a boca abre embaixo do "ω", com a língua rosa.
  - Versão anterior: `versoes_antigas/index_antes_focinho_roedor.html`.

- 2026-10-06: **Cacá v3**, mais fiel à folha de poses da referência. Versão anterior: `versoes_antigas/index_antes_caca_v3.html`.
  - **Silhueta única**, sem pescoço: a cúpula da cabeça alarga para baixo e continua no corpo, como um feijão de pé.
    - O contorno da cabeça só passa pelo alto e pelos lados; a parte de baixo da cabeça termina em y 89, sem traço.
    - O corpo vem por baixo, com a barriga clara (oval em 60,100).
  - **Focinho**: oval estreito e mais escuro (`#A06F4F`, rx 13,5 × ry 19,5), sem contorno.
    - Risco do nariz até a boca e lábio dividido. Narinas inclinadas em "V" (\ /), como na referência; o Tales apontou que estavam ao contrário.
    - Boca logo abaixo das narinas.
  - **Olhos**: pequenos e afastados, em x 38 e 82, y 41. Os óculos dos enfeites foram reposicionados para esses olhos.
  - Orelhinhas pequenas no alto. Flor rosa ao lado da orelha direita.
  - A fruta do cantinho mira na boca em 70/120.

- 2026-10-06: **videoclipe tema atualizado** (`D:\downloads\video tema.mp4`, mesma música, deslocamento 0). O jogo usa `videos/clipe_tema2.mp4` (854×480, sem som; nome novo por causa do cache). O `clipe_tema.mp4` anterior ficou na pasta.

- 2026-10-06: **Cacá v4**. O Tales achou a v3 (cabeça e corpo numa peça só) parecida com urso e mandou uma folha "capybara kawaii" só como guia de formato de cabeça e corpo de frente; o modelo continua o do videoclipe, com flor, focinho oval estreito e narinas em "V".
  - **Cabeça** separada do corpo: quadradinha, com topo quase reto, cantos bem redondos e bochechas mais largas. Embaixo ela se apoia no corpo, com um recuo nas laterais.
  - **Orelhinhas** pequenas, meio ovais, apontando para cima nos cantos.
  - **Corpo** em pera sentada, com barriga clara entre as patinhas.
    - As patinhas da frente ficaram finas e descem retas: são os `braco` com ângulo de 5°, e continuam animando na dança.
    - As patas de trás ficam escuras, dos lados.
  - **De costas**: rabinho escuro redondo.
  - Os óculos foram ajustados para os olhos em y 43. A fruta do cantinho mira em 69/120.
  - Página de comparação (não usada no jogo): `comparar_caca/`, com Atual, Cabeça separada e Três-quartos.
  - Versão anterior: `versoes_antigas/index_antes_caca_v4.html`.

- 2026-10-06: **Cacá v5, bochechuda**, pela referência kawaii que o Tales mandou.
  - A cabeça é uma cúpula com **bochechas que estufam embaixo**.
  - O **contorno não fecha no pescoço**: termina numa curvinha para dentro em cada bochecha (`CABECA_TRACO`, caminho aberto). O preenchimento continua no corpo, sem linha separando.
  - O corpo tem traço só nos lados e embaixo (`CORPO_TRACO`), começando um pouco abaixo das bochechas.
  - **Patinhas da frente com a ponta escura**, da cor dos pés (`pata()`, no lugar de `braco` na capivara). As classes `pt-braco-e`/`pt-braco-d` continuam, então as danças funcionam.
  - O rosto continua o mesmo: flor, focinho oval estreito, narinas em "V", risco e lábio dividido. Os olhos estão um pouco maiores e o blush fica nas bochechas.
  - Versão anterior: `versoes_antigas/index_antes_caca_v5.html`.

- 2026-10-06: **girassol, bola e bolhas maiores**. Versão anterior: `versoes_antigas/index_antes_girassol.html`.
  - O enfeite "Flor grande" (rosa, parecido com a flor da Cacá) virou **Girassol** (id `girassol`): 14 pétalas amarelas, miolo marrom e folha. Quem tinha `hibisco` salvo passa a ver o girassol.
  - **Bola** do cantinho: de 44 para 72 px. As contas da trajetória usam metade do tamanho.
  - **Bolhas de sabão**: de 34–62 para 56–96 px.

- 2026-10-06: **publicado no GitHub**: https://github.com/efreetales/Tpointic-Kids (branch `main`).
  - O `.gitignore` deixa de fora:
    - a chave (`chave_elevenlabs.dat`), `erros.txt` e outros arquivos de trabalho;
    - os backups (`versoes_antigas/`, `audios_antigos/`, `tentativas_vozes/`);
    - os modelos 3D;
    - os vídeos que o jogo não usa e as imagens antigas da Cacá 3D.
  - O envio teve cerca de 21 MB.
  - Para publicar mudanças: `git add -A`, `git commit` e `git push`.
  - **Vercel:** o Tales criou o projeto `tpointic-kids` (`prj_9skdQCaZawmNxNQRjJO6B9yEwcps`, time `team_jVeLX8H1FBzzBClzvVNwEtAG`), ligado ao repositório. A conexão MCP só lê; não cria projeto (erro 403).
    - **Site: https://tpointic-kids.vercel.app**
    - Cada `git push` na `main` publica sozinho.
    - Conferido no site: todos os áudios, tempos, vídeo e cenário respondem 200, a chave dá 404 e a primeira rodada começa normalmente.

- 2026-10-06: **segunda música de vitória e ronco**. Versão anterior: `versoes_antigas/index_antes_brilha_ronco.html`.
  - **`m4_brilha`**: "Brilha e Palmas", de `D:\downloads\Brilha E Palmas.wav`, convertida para mp3, 10 s.
    - Letra: "Muito bem, você conseguiu! Eba! / Bate palmas que foi genial! / Clap, clap, clap!".
    - Tempos das palavras pela transcrição do ElevenLabs (13 palavras, batendo com a letra).
  - As vitórias **se revezam** (`VITORIAS`, `vitoriaVez`): rodadas 1, 3 e 5 usam `m2_comemora`; rodadas 2 e 4 usam `m4_brilha`. A dança do cantinho continua com a `m2`.
  - **Palmas:**
    - `trechosPalmas` aceita "bata" ou "bate palmas" e vai até 3 palavras depois.
    - Cada palavra "clap" ganha uma palma no instante dela, com a turma batendo palmas.
    - Conferido no navegador na `m4`: palmas de 4,1 a 5,7 s e de 6,4 a 7,7 s, depois `vibra`. Com o ajuste final, a primeira parte vai até o "genial".
  - **Ronco**: `sfx_ronco`, de `D:\downloads\dog_snore.mp3`, com dois roncos em 4,76 s.
    - No fim da canção de ninar (`snoreAll`), cada bicho ronca em loop no seu tom (`SFX_RATE`), volume 0,16. A animação `--snore` acompanha um ronco (2,38 s ÷ tom).
    - O som some sozinho em 2,5 s depois de 15 s (`roncoSome`). O `wakeAll` também para tudo.

- 2026-10-06: **vídeo de divulgação** (LinkedIn e portfólio): `video_divulgacao/bicharada_cantante_divulgacao.mp4`, 1080×1350 (4:5), 30 fps, cerca de 57 s, 13 MB.
  - `grava.mjs`, com Node 24, controla um Chrome sem janela pelo protocolo de depuração (porta 9333, perfil próprio, `--force-device-scale-factor=2`):
    - joga sozinho, com legendas e cartazes injetados na página e marcas de cena;
    - grava os quadros (screencast);
    - anota cada áudio tocado: arquivo, hora, tom, volume e fim.
    - Durante a gravação esconde o rodapé e a barra de músicas e, no cantinho, a banda.
  - `monta_video.py` remonta o vídeo contínuo e o som com os mp3 reais (os tons sintetizados ficam de fora) e corta 15 trechos (`CORTES`).
  - Para refazer: servidor em :8000, depois `node grava.mjs` (cerca de 3,5 min) e `python monta_video.py`.
- 2026-10-06: **telas baixas no cantinho**: o balão flutua no topo (`position:absolute`) e o palco reserva espaço para ele. Com altura de até 760 px, a bandeja fica compacta.
- 2026-10-06: **noite na floresta**: `night-sky` vai só até 0,78 de opacidade, para a floresta continuar aparecendo.

- 2026-10-07: **melhor uso da tela do celular**. Num celular de 375×812, o quadro principal passou de 389 para 551 px. Versão anterior: `versoes_antigas/index_antes_celular.html`.
  - O texto longo "Para pais" do rodapé (113 px) virou um link de uma linha, "ⓘ Informações para pais" (`#paisBtn`). Ele abre a janelinha `#infoPais` com o texto completo e o botão "Entendi".
  - Até 440 px de largura, a barra de músicas fica numa linha só, com rótulos curtos ("Tema", "Dormir", "Pular", "Parar"). Quem faz isso é o `updateBar`, que acompanha a mudança de largura (`matchMedia`). O `aria-label` continua com o nome completo.
  - `.app` usa `height:100dvh`: a altura real do celular, sem a barra de endereço.

## Pendência atual
- Esperando o Tales ouvir as falas novas (v4 com emoção) no jogo. Se alguma não agradar, ele pode refazer pela tela AJUSTAR_VOZES (texto e marcações editáveis) ou pedir aqui.
- Ao trocar o texto de `oba_*` ou `rN_erro_*` pela tela, atualizar também `OBA` / `PLAN[].erro` no `index.html` (são os balões).

Nina (histórico dos testes):
- Ela fala rápido demais: cerca de 10 sílabas/s, contra ~6 da Cacá. Com velocidade 0,70 (o mínimo) caiu para ~5,7 sílabas/s, ainda sem pronúncia ruim. A voz foi criada com "fala rápido" na descrição.
- "Um!" sozinho sai como "Hum!", "Sim" ou até japonês, mesmo com contexto. "Um morango!" saiu certo na maioria das vezes, e "Um, dois, três... Um!" também. Para o "Um!" puro funcionar, talvez seja preciso uma voz nova.
