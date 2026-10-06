# Monta o vídeo de divulgação a partir da gravação (grava.mjs):
#  1) quadros (frames/ + quadros.json) -> bruto.mp4, 30 quadros por segundo
#  2) sons (sons.json: arquivo, hora, tom, volume, quando parou) -> bruto.wav com os áudios reais do jogo
#  3) corta os trechos de cada cena (CORTES, em segundos a partir das marcas) -> bicharada_cantante_divulgacao.mp4
import json, os, subprocess

PASTA = os.path.dirname(os.path.abspath(__file__))
AUDIOS = os.path.join(PASTA, "..", "audios")
q = json.load(open(os.path.join(PASTA, "quadros.json")))
sons = json.load(open(os.path.join(PASTA, "sons.json")))
marcas = dict(json.load(open(os.path.join(PASTA, "marcas.json"))))
T0 = q[0]
M = {k: (v - T0) / 1000 for k, v in marcas.items()}
TOTAL = (q[-1] - T0) / 1000 + 0.5
sr = lambda nome: next(e for e in sons if e["nome"] == nome)
S = lambda nome: (sr(nome)["t"] - T0) / 1000

def roda(cmd):
    subprocess.run(cmd, check=True, cwd=PASTA)

# 1) vídeo contínuo
with open(os.path.join(PASTA, "lista.txt"), "w") as f:
    for i in range(len(q)):
        dur = ((q[i + 1] - q[i]) if i + 1 < len(q) else 500) / 1000
        f.write(f"file 'frames/{i:06d}.jpg'\nduration {dur:.4f}\n")
    f.write(f"file 'frames/{len(q) - 1:06d}.jpg'\n")
if not os.path.exists(os.path.join(PASTA, "bruto.mp4")):
    roda(["ffmpeg", "-v", "error", "-y", "-f", "concat", "-safe", "0", "-i", "lista.txt",
          "-vf", "fps=30,format=yuv420p", "-c:v", "libx264", "-crf", "16", "-preset", "fast", "bruto.mp4"])

# 2) som contínuo: cada áudio entra na hora em que tocou, no tom e volume do jogo, até a hora em que parou
entradas, filtros = [], []
for k, e in enumerate(sons):
    ini = (e["t"] - T0) / 1000
    if ini < 0: continue
    fim = ((e.get("fim") or (T0 + TOTAL * 1000)) - T0) / 1000
    dur = max(0.05, fim - ini)
    entradas += ["-i", os.path.join(AUDIOS, e["nome"] + ".mp3")]
    n = len(entradas) // 2 - 1
    cad = f"[{n}:a]aresample=44100,aformat=channel_layouts=stereo"
    if e.get("loop"): cad += ",aloop=loop=-1:size=2000000"
    rate = e.get("rate") or 1
    if abs(rate - 1) > 0.001: cad += f",asetrate={44100 * rate:.0f},aresample=44100"
    cad += f",atrim=duration={dur:.3f},afade=t=out:st={max(0, dur - 0.04):.3f}:d=0.04,volume={e.get('ganho', 1):.3f},adelay={int(ini * 1000)}|{int(ini * 1000)}[a{n}]"
    filtros.append(cad)
mix = "".join(f"[a{i}]" for i in range(len(filtros)))
filtros.append(f"{mix}amix=inputs={len(filtros)}:normalize=0:duration=longest,apad=whole_dur={TOTAL:.2f},alimiter=limit=0.95[aout]")
roda(["ffmpeg", "-v", "error", "-y", *entradas, "-filter_complex", ";".join(filtros), "-map", "[aout]", "-ar", "44100", "bruto.wav"])

# 3) cortes (início, fim) em segundos da gravação
bumbum = S("m1_tema") + 25.1          # "Balança o bumbum" na música tema
CORTES = [
    (M["abertura"] + 0.25, M["abertura"] + 3.0),          # cartaz com a turma
    (S("r1_pergunta_caca") - 0.15, M["resposta"] + 0.05),  # "Que fruta é essa? Fala pra mim!"
    (M["resposta"] + 0.05, S("r1_resposta_caca") + 4.95),  # "Essa é a manga! Man... ga... Manga!"
    (M["conta1"] - 0.45, M["conta2"] + 1.2),               # 1, 2 com o número grandão
    (S("m2_comemora") + 3.3, S("m2_comemora") + 7.6),      # "Bata palmas com alegria" com palmas
    (M["vibra"] - 0.15, M["vibra"] + 2.6),                 # torcida e confetes
    (M["pet"] + 0.7, M["pet"] + 3.4),                      # a Cacá chega pulando no cantinho (banda ainda aparece)
    (M["enfeitar"], M["enfeitar"] + 3.6),                  # chapéu, óculos, colar
    (M["comer"] + 0.1, S("pet_come_banana_caca") + 6.0),   # banana: come e soletra
    (M["bolhas"] + 0.9, M["bolhas"] + 4.0),                # bolhas de sabão
    (bumbum - 0.6, bumbum + 5.2),                          # todo mundo de costas rebolando
    (M["ninar"] + 9.0, M["ninar"] + 11.5),                 # anoitecendo
    (S("sfx_bocejo") - 0.4, S("sfx_bocejo") + 2.6),        # a Cacá boceja e dorme
    (S("sfx_ronco") + 2.0, S("sfx_ronco") + 5.5),          # a turma roncando
    (M["final"] + 0.2, M["fim"]),                          # cartaz final com o link
]
partes = []
for i, (a, b) in enumerate(CORTES):
    d = b - a
    partes.append(f"[0:v]trim=start={a:.3f}:end={b:.3f},setpts=PTS-STARTPTS[v{i}];"
                  f"[1:a]atrim=start={a:.3f}:end={b:.3f},asetpts=PTS-STARTPTS,"
                  f"afade=t=in:d=0.08,afade=t=out:st={d - 0.12:.3f}:d=0.12[a{i}]")
junta = "".join(f"[v{i}][a{i}]" for i in range(len(CORTES))) + f"concat=n={len(CORTES)}:v=1:a=1[v][a]"
roda(["ffmpeg", "-v", "error", "-y", "-i", "bruto.mp4", "-i", "bruto.wav",
      "-filter_complex", ";".join(partes) + ";" + junta, "-map", "[v]", "-map", "[a]",
      "-c:v", "libx264", "-crf", "20", "-preset", "slow", "-pix_fmt", "yuv420p", "-r", "30",
      "-c:a", "aac", "-b:a", "160k", "-movflags", "+faststart", "bicharada_cantante_divulgacao.mp4"])
total = sum(b - a for a, b in CORTES)
print("ok", round(total, 1), "s", round(os.path.getsize(os.path.join(PASTA, "bicharada_cantante_divulgacao.mp4")) / 1e6, 1), "MB")
