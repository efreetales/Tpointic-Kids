# Bicharada Cantante - tela para ajustar as vozes dos personagens.
# Abra pelo AJUSTAR_VOZES.bat. Roda so neste computador (127.0.0.1); a chave do ElevenLabs nunca vai para a pagina.
import json, os, re, shutil, subprocess, sys, time, urllib.request, urllib.error, webbrowser
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler

PASTA = os.path.dirname(os.path.abspath(__file__))
AUDIOS = os.path.join(PASTA, 'audios')
TENTATIVAS = os.path.join(PASTA, 'tentativas_vozes')
BACKUPS = os.path.join(PASTA, 'audios_antigos')
ARQ_AJUSTES = os.path.join(PASTA, 'ajustes_vozes.json')
API = 'https://api.elevenlabs.io/v1'
PORTA = 8765
NOMES = {'caca': 'Cacá', 'zeca': 'Zeca', 'nina': 'Nina', 'tuca': 'Tuca'}


def ler_chave():
    # A chave fica criptografada pelo Windows (DPAPI); so o PowerShell deste usuario consegue abrir.
    arq = os.path.join(PASTA, 'chave_elevenlabs.dat').replace("'", "''")
    cmd = ("$s = Get-Content '%s' | ConvertTo-SecureString; "
           "[Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($s))") % arq
    r = subprocess.run(['powershell', '-NoProfile', '-Command', cmd], capture_output=True, text=True)
    chave = r.stdout.strip()
    if not chave:
        sys.exit('Nao achei a chave do ElevenLabs. Rode o GERAR_AUDIOS.bat uma vez para cadastrar a chave.')
    return chave


CHAVE = ler_chave()


def ler_falas():
    # As falas ficam no gerar_audios.ps1, no formato @('nome', 'quem', 'texto').
    with open(os.path.join(PASTA, 'gerar_audios.ps1'), encoding='utf-8-sig') as f:
        src = f.read()
    falas = [{'nome': n, 'quem': q, 'texto': t.replace("''", "'")}
             for n, q, t in re.findall(r"@\('(\w+)', '(caca|zeca|nina|tuca)', '((?:[^']|'')*)'\)", src)]
    ajustes = ler_ajustes()
    # Emoções de cada fala (bloco $emocoes do gerar_audios.ps1): a tela mostra o texto já com as marcações,
    # do jeito que o gerador manda para o modelo novo.
    emocoes = {n: t.replace("''", "'") for n, t in re.findall(r"^  '(\w+)' = '((?:[^']|'')*)'$", src, re.M)}
    v2 = modelo() == 'eleven_multilingual_v2'
    for f in falas:
        f['texto'] = ajustes.get('textos', {}).get(f['nome'], f['texto'])
        e = emocoes.get(f['nome'])
        if not v2 and '[' not in f['texto'] and e and sem_marcas(e) == f['texto']:
            f['texto'] = e
        f['sem_marcas'] = sem_marcas(f['texto'])
        m = re.match(r'(r\d+)_conta', f['nome'])
        if m and v2:  # no Multilingual v2 as contagens usam o pedido da rodada como contexto, igual ao script
            f['contexto'] = next((sem_marcas(p['texto']) for p in falas if p['nome'].startswith(m.group(1) + '_pedido_')), '')
    return falas


def sem_marcas(t):
    return re.sub(r'\s+', ' ', re.sub(r'\[[^\]]*\]\s*', '', t)).strip()


def modelo():
    return ler_ajustes().get('modelo', 'eleven_multilingual_v2')


def ler_vozes():
    vozes = {}
    with open(os.path.join(PASTA, 'vozes_escolhidas.txt'), encoding='utf-8-sig') as f:
        for linha in f:
            if '=' in linha:
                k, v = linha.strip().split('=', 1)
                vozes[k] = v
    return vozes


def ler_ajustes():
    with open(ARQ_AJUSTES, encoding='utf-8-sig') as f:
        return json.load(f)


def gravar_ajustes(dados):
    with open(ARQ_AJUSTES, 'w', encoding='utf-8') as f:
        json.dump(dados, f, ensure_ascii=False, indent=2)


def eleven(caminho, corpo=None):
    req = urllib.request.Request(API + caminho, headers={'xi-api-key': CHAVE, 'Content-Type': 'application/json'},
                                 data=json.dumps(corpo).encode('utf-8') if corpo is not None else None)
    try:
        with urllib.request.urlopen(req, timeout=120) as r:
            return r.read()
    except urllib.error.HTTPError as e:
        corpo_erro = e.read().decode('utf-8', 'replace')
        try:
            msg = json.loads(corpo_erro)['detail']['message']
        except Exception:
            msg = corpo_erro[:300]
        raise RuntimeError(msg)


def creditos():
    try:
        s = json.loads(eleven('/user/subscription'))
        return {'usados': s['character_count'], 'limite': s['character_limit']}
    except Exception:
        return None


def mp3_valido(nome):
    return re.fullmatch(r'[\w-]+\.mp3', nome or '') is not None


class Tela(BaseHTTPRequestHandler):
    def log_message(self, *a):
        pass

    def responder(self, codigo, corpo, tipo='application/json; charset=utf-8'):
        if isinstance(corpo, (dict, list)):
            corpo = json.dumps(corpo, ensure_ascii=False).encode('utf-8')
        self.send_response(codigo)
        self.send_header('Content-Type', tipo)
        self.send_header('Cache-Control', 'no-store')
        self.end_headers()
        self.wfile.write(corpo)

    def arquivo(self, pasta, nome, tipo):
        caminho = os.path.join(pasta, nome)
        if not os.path.isfile(caminho):
            return self.responder(404, {'erro': 'arquivo nao encontrado'})
        with open(caminho, 'rb') as f:
            self.responder(200, f.read(), tipo)

    def do_GET(self):
        rota = self.path.split('?')[0]
        if rota == '/':
            return self.arquivo(PASTA, 'ajustar_vozes.html', 'text/html; charset=utf-8')
        if rota.startswith('/audios/') and mp3_valido(rota[8:]):
            return self.arquivo(AUDIOS, rota[8:], 'audio/mpeg')
        if rota.startswith('/tentativas/') and mp3_valido(rota[12:]):
            return self.arquivo(TENTATIVAS, rota[12:], 'audio/mpeg')
        if rota == '/api/estado':
            ajustes = ler_ajustes()
            return self.responder(200, {
                'personagens': [{'id': k, 'nome': v, 'ajustes': ajustes['personagens'][k]} for k, v in NOMES.items()],
                'falas': ler_falas(),
                'creditos': creditos(),
            })
        self.responder(404, {'erro': 'nao encontrado'})

    def do_POST(self):
        try:
            dados = json.loads(self.rfile.read(int(self.headers.get('Content-Length', 0))) or b'{}')
            if self.path == '/api/gerar':
                return self.gerar(dados)
            if self.path == '/api/usar':
                return self.usar(dados)
            if self.path == '/api/ajustes':
                return self.salvar_ajustes(dados)
            self.responder(404, {'erro': 'nao encontrado'})
        except Exception as e:
            self.responder(500, {'erro': str(e)})

    def gerar(self, d):
        quem, nome = d['quem'], d['nome']
        if quem not in NOMES or not re.fullmatch(r'\w+', nome):
            return self.responder(400, {'erro': 'personagem ou fala invalida'})
        aj = d['ajustes']
        corpo = {
            'text': sem_marcas(d['texto']) if modelo() == 'eleven_multilingual_v2' else d['texto'],
            'model_id': modelo(),
            'voice_settings': {'stability': float(aj['stability']), 'similarity_boost': float(aj['similarity_boost']),
                               'style': float(aj['style']), 'use_speaker_boost': True, 'speed': float(aj['speed'])},
        }
        if d.get('contexto'):
            corpo['previous_text'] = d['contexto']
        try:
            audio = eleven('/text-to-speech/%s?output_format=mp3_44100_128' % ler_vozes()[quem], corpo)
        except RuntimeError as e:
            return self.responder(502, {'erro': str(e)})
        os.makedirs(TENTATIVAS, exist_ok=True)
        arq = '%s__%s.mp3' % (nome, time.strftime('%Y%m%d-%H%M%S'))
        with open(os.path.join(TENTATIVAS, arq), 'wb') as f:
            f.write(audio)
        self.responder(200, {'arquivo': arq, 'creditos': creditos()})

    def usar(self, d):
        arq, nome = d['arquivo'], d['nome']
        if not mp3_valido(arq) or not re.fullmatch(r'\w+', nome) or not arq.startswith(nome + '__'):
            return self.responder(400, {'erro': 'tentativa invalida'})
        destino = os.path.join(AUDIOS, nome + '.mp3')
        if os.path.isfile(destino):  # guarda o audio que estava no jogo antes de trocar
            os.makedirs(BACKUPS, exist_ok=True)
            shutil.copy2(destino, os.path.join(BACKUPS, '%s__%s.mp3' % (nome, time.strftime('%Y%m%d-%H%M%S'))))
        shutil.copy2(os.path.join(TENTATIVAS, arq), destino)
        # Se o texto mudou, o gerar_audios.ps1 passa a usar o texto novo para esta fala.
        original = next((f for f in ler_falas() if f['nome'] == nome), None)
        ajustes = ler_ajustes()
        textos = ajustes.setdefault('textos', {})
        if original and d.get('texto') and d['texto'] != original['texto']:
            # guarda o texto com as marcações de emoção que estiverem nele; o gerador usa do mesmo jeito
            textos[nome] = d['texto']
        gravar_ajustes(ajustes)
        self.responder(200, {'ok': True})

    def salvar_ajustes(self, d):
        if d['quem'] not in NOMES:
            return self.responder(400, {'erro': 'personagem invalido'})
        ajustes = ler_ajustes()
        ajustes['personagens'][d['quem']] = {k: round(float(d['ajustes'][k]), 2)
                                             for k in ('stability', 'similarity_boost', 'style', 'speed')}
        gravar_ajustes(ajustes)
        self.responder(200, {'ok': True})


if __name__ == '__main__':
    servidor = ThreadingHTTPServer(('127.0.0.1', PORTA), Tela)
    endereco = 'http://localhost:%d' % PORTA
    print('Tela de ajuste das vozes aberta em %s' % endereco)
    print('Deixe esta janela aberta enquanto usa a tela. Para fechar, feche esta janela.')
    if '--sem-navegador' not in sys.argv:
        webbrowser.open(endereco)
    servidor.serve_forever()
