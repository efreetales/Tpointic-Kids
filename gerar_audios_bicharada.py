#!/usr/bin/env python3
"""
Bicharada Cantante — gera as 36 falas e as 3 músicas no ElevenLabs.

Como usar (no seu computador, ou peça ao Claude Code para fazer):
  1. Defina a chave SEM colar no código:
       Windows (PowerShell):  $env:ELEVENLABS_API_KEY="sua_chave"
       Mac/Linux:             export ELEVENLABS_API_KEY="sua_chave"
  2. Rode uma vez sem vozes configuradas para listar as vozes da sua conta:
       python gerar_audios_bicharada.py
  3. Escolha uma voz para cada personagem, cole os IDs em VOZES abaixo e rode de novo.
     Os arquivos saem na pasta "audios". Se cair no meio, rode de novo: o que já existe é pulado.

Só usa a biblioteca padrão do Python (3.8+). Nada para instalar.
"""
import json
import os
import sys
import time
import urllib.error
import urllib.request

API = "https://api.elevenlabs.io/v1"
SAIDA = "audios"

# Cole aqui o ID da voz de cada personagem (aparece no ElevenLabs em "My Voices" / Voice Library).
VOZES = {
    "caca": "",  # Cacá, capivara: feminina, média-grave, calma e carinhosa
    "zeca": "",  # Zeca, sapo: masculina jovem, animada, levemente rouca
    "nina": "",  # Nina, oncinha: menina, aguda, curiosa e rápida
    "tuca": "",  # Tuca, tucano: bem aguda, teatral, quase cantando
}

# Ajuste fino por personagem: estabilidade menor = mais expressivo.
AJUSTES = {
    "caca": {"stability": 0.55, "similarity_boost": 0.8, "style": 0.35},
    "zeca": {"stability": 0.35, "similarity_boost": 0.8, "style": 0.6},
    "nina": {"stability": 0.40, "similarity_boost": 0.8, "style": 0.55},
    "tuca": {"stability": 0.30, "similarity_boost": 0.8, "style": 0.7},
}

FALAS = [
    ("abertura_nina", "nina", "Oi! Vamos contar e cantar com a Bicharada?"),
    ("fim_caca", "caca", "Que show! Agora a Bicharada vai descansar. Até a próxima!"),
    ("apresenta_caca", "caca", "Eu sou a Cacá, a capivara!"),
    ("apresenta_zeca", "zeca", "Eu sou o Zeca! Cuá, cuá!"),
    ("apresenta_nina", "nina", "Eu sou a Nina, a oncinha! Rrrá!"),
    ("apresenta_tuca", "tuca", "Eu sou o Tuca, o tucano cantor!"),
    ("oba_caca", "caca", "Ebaaa! Conseguimos!"),
    ("oba_zeca", "zeca", "Uhuuu! Muito bem!"),
    ("oba_nina", "nina", "Isso aí! Você é demais!"),
    ("oba_tuca", "tuca", "Que lindo! Bravo, bravo!"),
    ("r1_pedido_caca", "caca", "Me ajuda a pegar duas mangas?"),
    ("r2_pedido_zeca", "zeca", "Me ajuda a pegar três bananas?"),
    ("r3_pedido_nina", "nina", "Me ajuda a pegar três morangos?"),
    ("r4_pedido_tuca", "tuca", "Me ajuda a pegar quatro uvas?"),
    ("r5_pedido_caca", "caca", "Agora o último! Me ajuda a pegar cinco cajus?"),
    ("r1_conta1_caca", "caca", "Uma!"),
    ("r1_conta2_caca", "caca", "Duas!"),
    ("r2_conta1_zeca", "zeca", "Uma!"),
    ("r2_conta2_zeca", "zeca", "Duas!"),
    ("r2_conta3_zeca", "zeca", "Três!"),
    ("r3_conta1_nina", "nina", "Um!"),
    ("r3_conta2_nina", "nina", "Dois!"),
    ("r3_conta3_nina", "nina", "Três!"),
    ("r4_conta1_tuca", "tuca", "Uma!"),
    ("r4_conta2_tuca", "tuca", "Duas!"),
    ("r4_conta3_tuca", "tuca", "Três!"),
    ("r4_conta4_tuca", "tuca", "Quatro!"),
    ("r5_conta1_caca", "caca", "Um!"),
    ("r5_conta2_caca", "caca", "Dois!"),
    ("r5_conta3_caca", "caca", "Três!"),
    ("r5_conta4_caca", "caca", "Quatro!"),
    ("r5_conta5_caca", "caca", "Cinco!"),
    ("r2_erro_zeca", "zeca", "Opa! Essa não é banana. Procura a banana amarelinha!"),
    ("r3_erro_nina", "nina", "Hum, essa não é morango! Cadê o morango vermelhinho?"),
    ("r4_erro_tuca", "tuca", "Ih, essa não é uva! A uva é roxinha!"),
    ("r5_erro_caca", "caca", "Quase! Essa não é caju. Procura o caju!"),
]

MUSICAS = [
    ("m1_tema", 90_000,
     "Música infantil brasileira original, alegre, 112 bpm, ukulele, percussão de brinquedo, palmas, xilofone. "
     "Vozes de personagens fofos de desenho animado cantando em português do Brasil, letra bem articulada, coro no refrão. "
     "Letra:\n"
     "[Estrofe 1]\nLá na mata tem um palco,\ntem batuque e tem canção.\nChega a Cacá, capivara,\ncom um tambor na mão: bum, bum!\n"
     "[Estrofe 2]\nPula o Zeca, o sapinho,\nfaz cuá-cuá no refrão.\nVem a Nina, a oncinha,\nrugindo afinadinha: rrrá!\n"
     "[Estrofe 3]\nE lá do galho, o Tuca\ncanta alto, sem parar:\npi-ri-pi, pi-ri-pi,\ntodo mundo vai cantar!\n"
     "[Refrão]\nÉ a Bicharada,\nbicharada cantante!\nConta, canta e dança,\nbate palma, bate o pé!\n"
     "É a Bicharada,\nvem cantar com a gente!\nUm, dois, três… olé!"),
    ("m2_comemora", 14_000,
     "Vinheta infantil brasileira curta e explosiva, 120 bpm, palmas, ukulele, coro de personagens fofos de desenho animado, "
     "português do Brasil, termina com 'êê!' em coro. Letra:\n"
     "Bate palma, bate o pé,\nquem contou foi você!\nBate palma, bate o pé,\nêê!"),
    ("m3_ninar", 60_000,
     "Canção de ninar brasileira original, 70 bpm, voz feminina suave e acolhedora, violão dedilhado, caixinha de música, "
     "calma, português do Brasil. Letra:\n"
     "Dorme, dorme, Bicharada,\nque a lua já chegou.\nA capivara boceja,\no sapinho cochilou.\n"
     "A oncinha faz ronrom,\no tucano se aninhou.\nAmanhã tem cantoria,\na brincadeira acabou."),
]


def chamar(metodo, caminho, chave, corpo=None, tentativas=3):
    dados = json.dumps(corpo).encode("utf-8") if corpo is not None else None
    for i in range(tentativas):
        req = urllib.request.Request(API + caminho, data=dados, method=metodo, headers={
            "xi-api-key": chave, "Content-Type": "application/json", "Accept": "*/*"})
        try:
            with urllib.request.urlopen(req, timeout=300) as r:
                return r.read()
        except urllib.error.HTTPError as e:
            msg = e.read().decode("utf-8", "ignore")[:400]
            if e.code in (429, 500, 502, 503) and i < tentativas - 1:
                time.sleep(5 * (i + 1))
                continue
            raise SystemExit(f"Erro {e.code} em {caminho}: {msg}")
    return b""


def listar_vozes(chave):
    vozes = json.loads(chamar("GET", "/voices", chave)).get("voices", [])
    print("\nVozes disponíveis na sua conta (nome — ID — descrição):\n")
    for v in vozes:
        rot = v.get("labels") or {}
        desc = ", ".join(str(x) for x in rot.values() if x)
        print(f"  {v.get('name')} — {v.get('voice_id')} — {desc}")
    print("\nPara ter vozes em português de desenho animado, adicione da Voice Library do ElevenLabs "
          "(filtre por Portuguese) e rode este comando de novo para ver os IDs.")


def main():
    chave = os.environ.get("ELEVENLABS_API_KEY", "").strip()
    if not chave:
        raise SystemExit("Defina a variável ELEVENLABS_API_KEY antes de rodar (veja o topo do arquivo).")
    if not all(VOZES.values()):
        listar_vozes(chave)
        print("\nPreencha os 4 IDs em VOZES no topo do arquivo e rode de novo.")
        return

    os.makedirs(SAIDA, exist_ok=True)

    for nome, quem, texto in FALAS:
        destino = os.path.join(SAIDA, nome + ".mp3")
        if os.path.exists(destino):
            print(f"pulando  {nome}")
            continue
        corpo = {
            "text": texto,
            "model_id": "eleven_multilingual_v2",
            "language_code": "pt",
            "voice_settings": {**AJUSTES[quem], "use_speaker_boost": True},
        }
        audio = chamar("POST", f"/text-to-speech/{VOZES[quem]}?output_format=mp3_44100_128", chave, corpo)
        with open(destino, "wb") as f:
            f.write(audio)
        print(f"ok       {nome}")

    for nome, duracao, prompt in MUSICAS:
        destino = os.path.join(SAIDA, nome + ".mp3")
        if os.path.exists(destino):
            print(f"pulando  {nome}")
            continue
        print(f"compondo {nome} (pode levar alguns minutos)…")
        audio = chamar("POST", "/music", chave, {"prompt": prompt, "music_length_ms": duracao, "model_id": "music_v1"})
        with open(destino, "wb") as f:
            f.write(audio)
        print(f"ok       {nome}")

    print(f"\nPronto: {len(FALAS)} falas e {len(MUSICAS)} músicas na pasta '{SAIDA}'. "
          "Ouça no celular e mande a pasta compactada para o Claude.")


if __name__ == "__main__":
    main()
