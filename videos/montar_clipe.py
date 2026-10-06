# Monta o videoclipe da Canção da Bicharada (música tema, audios/m1_tema.mp3) a partir dos vídeos da
# turma em D:\downloads\3. Cada trecho da música (tempos de audios/m1_tema.tempos.json) mostra o que está
# sendo cantado. Gera:
#   videos/clipe_cancao_da_bicharada.mp4  - 1280x720 com a música (para assistir/compartilhar)
#   videos/tema.mp4                       - 854x480 sem som (para o jogo, que toca a música à parte)
import os, subprocess

ORIGEM = r"D:\downloads\3"
PASTA = os.path.dirname(os.path.abspath(__file__))
MUSICA = os.path.join(PASTA, "..", "audios", "m1_tema.mp3")
FONTES = {
    "v1": "video 1.mp4",                                        # estilo floresta exuberante
    "v2": "video 2.mp4",                                        # estilo lilás
    "nina": "2D_vector_animation._Nina_Oncinha_20261006035350.mp4",
    "turma": "A_lively_2D_vector_cartoon_20261006035350.mp4",
    "zeca": "Add_a_video_of_the_20261006035350.mp4",
}
# cortes extras para esconder bordas: v1 23-31 s tem moldura branca; v2 tem uma borda lilás fina
ZOOM = {("v1", 23, 31): 0.88, ("v2", 0, 58): 0.94}

# (início na música, fim na música, fonte, início na fonte)  — trechos em ordem, sem buracos
EDL = [
    (0.00,   5.00,  "v1",   46.0),   # intro: Cacá dançando na prainha
    (5.00,   9.96,  "v2",    0.0),   # intro: Cacá chega acenando na cachoeira
    (9.96,  13.52,  "v1",    0.0),   # "Pula, pula, a Cacá chegou"
    (13.52, 18.06,  "v1",    8.0),   # "Nossa capivara que o mato gostou" (coroa de flores no jardim)
    (18.06, 21.66,  "v2",   23.0),   # "Mexe o corpinho pra lá e pra cá"
    (21.66, 25.50,  "v2",   15.0),   # "Na beira do rio, ela quer dançar" (microfone no rio)
    (25.50, 29.40,  "v2",   54.0),   # refrão: "Balança o bumbum, um, dois, três"
    (29.40, 33.36,  "turma", 0.0),   # "Balança o bumbum, tudo outra vez"
    (33.36, 37.42,  "v2",   31.0),   # "Dança na floresta, que festa legal"
    (37.42, 42.80,  "v1",   54.0),   # "É pura alegria no quintal"
    (42.80, 47.02,  "v2",    8.0),   # instrumental: Cacá cantando
    (47.02, 49.92,  "v1",   51.0),   # instrumental: Cacá dançando no rio
    (49.92, 53.94,  "zeca",  0.0),   # "O Zeca Sapo dá um salto assim" (pula nas vitórias-régias)
    (53.94, 57.84,  "v1",   16.0),   # "Lá na lagoa, perto do capim"
    (57.84, 61.82,  "v1",   26.0),   # "A Nina Oncinha, pintada e faceira"
    (61.82, 66.16,  "v2",   46.0),   # "corre e se esconde atrás da mangueira"
    (66.16, 70.20,  "turma", 0.0),   # refrão 2
    (70.20, 74.02,  "zeca",  4.5),   # Zeca na flor de lótus, Cacá nadando
    (74.02, 78.10,  "v2",   26.6),   # Cacá dançando no tronco
    (78.10, 81.60,  "v2",   50.4),   # Cacá e Nina na mangueira
    (81.60, 83.54,  "v2",   39.0),   # Cacá e Zeca na lagoa
    (83.54, 91.42,  "nina",  2.0),   # instrumental: Nina brincando de esconder
    (91.42, 94.20,  "v1",   31.0),   # "Olha pro céu, quem é que vem lá? O Tuca Tucano"
    (94.20, 97.40,  "turma", 5.0),   # "quer nos visitar. Bate as asinhas, o bico é grandão"
    (97.40, 100.74, "v1",   35.0),   # "Faz um barulho e bate o pé no chão"
    (100.74, 104.80, "v2",  41.0),   # refrão 3: Cacá e Zeca na lagoa
    (104.80, 108.60, "v2",  35.1),   # Cacá dançando entre flores
    (108.60, 110.90, "v2",  12.3),   # Cacá cantando
    (110.90, 113.30, "v2",  19.0),   # Cacá no rio
    (113.30, 117.10, "v1",   3.6),   # Cacá na prainha
    (117.10, 118.52, "v1",  19.9),   # Zeca na lagoa
    (118.52, 126.00, "turma", 2.5),  # "Cacá e o Zeca, a Nina e o Tuca. Todo mundo dança..."
]
FIM = 134.02                          # duração da música: o último quadro fica parado até o fim e escurece

def trecho(i, ini, fim, fonte, t0, largura, altura):
    dur = fim - ini
    z = next((v for (f, a, b), v in ZOOM.items() if f == fonte and a <= t0 < b), 1.0)
    corta = f"crop=iw*{z}:ih*{z}," if z < 1 else ""
    return (f"[{list(FONTES).index(fonte)}:v]trim=start={t0:.3f}:duration={dur:.3f},setpts=PTS-STARTPTS,"
            f"{corta}scale={largura}:{altura}:flags=lanczos,setsar=1,fps=24,format=yuv420p[s{i}]")

def montar(saida, largura, altura, com_audio):
    filtros = [trecho(i, *seg, largura, altura) for i, seg in enumerate(EDL)]
    n = len(EDL)
    ultimo_fim = EDL[-1][1]
    filtros.append("".join(f"[s{i}]" for i in range(n)) + f"concat=n={n}:v=1:a=0[corpo]")
    # encerramento: congela o último quadro até o fim da música e escurece no último 1,5 s
    filtros.append(f"[corpo]tpad=stop_mode=clone:stop_duration={FIM - ultimo_fim:.3f},"
                   f"fade=t=out:st={FIM - 1.5:.3f}:d=1.5[v]")
    cmd = ["ffmpeg", "-v", "error", "-y"]
    for f in FONTES.values(): cmd += ["-i", os.path.join(ORIGEM, f)]
    if com_audio: cmd += ["-i", MUSICA]
    cmd += ["-filter_complex", ";".join(filtros), "-map", "[v]"]
    if com_audio: cmd += ["-map", f"{len(FONTES)}:a", "-c:a", "aac", "-b:a", "160k", "-shortest"]
    else: cmd += ["-an"]
    cmd += ["-c:v", "libx264", "-crf", "23" if com_audio else "30", "-preset", "slow", "-pix_fmt", "yuv420p",
            "-movflags", "+faststart", "-t", f"{FIM:.3f}", saida]
    subprocess.run(cmd, check=True)
    print("ok", saida, round(os.path.getsize(saida) / 1e6, 1), "MB")

# confere que os trechos encaixam sem buracos
for a, b in zip(EDL, EDL[1:]): assert abs(a[1] - b[0]) < 1e-6, (a, b)
montar(os.path.join(PASTA, "clipe_cancao_da_bicharada.mp4"), 1280, 720, True)
montar(os.path.join(PASTA, "tema.mp4"), 640, 360, False)
