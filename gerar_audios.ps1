# Bicharada Cantante - gera as falas e as musicas no ElevenLabs.
# Abra pelo arquivo GERAR_AUDIOS.bat (dois cliques). A chave e pedida na tela e nao fica salva.
$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$API = 'https://api.elevenlabs.io/v1'
$pasta = Join-Path $PSScriptRoot 'audios'
New-Item -ItemType Directory -Force -Path $pasta | Out-Null
$arqVozes = Join-Path $PSScriptRoot 'vozes_escolhidas.txt'

Write-Host ''
Write-Host '=== Bicharada Cantante: gerador de vozes e musicas ===' -ForegroundColor Yellow
Write-Host ''
# A chave fica guardada, criptografada pelo Windows, num arquivo que so o seu usuario consegue abrir.
$arqChave = Join-Path $PSScriptRoot 'chave_elevenlabs.dat'
function Ler-ChaveSalva {
  if (-not (Test-Path $arqChave)) { return $null }
  try {
    $s = Get-Content $arqChave | ConvertTo-SecureString
    return [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($s))
  } catch { return $null }
}
function Pedir-Chave {
  $s = Read-Host 'Cole a chave do ElevenLabs (clique com o botao direito para colar) e aperte Enter' -AsSecureString
  $s | ConvertFrom-SecureString | Set-Content $arqChave
  return [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($s))
}

$key = Ler-ChaveSalva
if ($key) { Write-Host 'Usando a chave do ElevenLabs guardada neste computador.' -ForegroundColor DarkGray }
else { $key = Pedir-Chave }

$lista = $null
for ($tentativa = 1; $tentativa -le 2 -and -not $lista; $tentativa++) {
  $headers = @{ 'xi-api-key' = $key.Trim() }
  try {
    $lista = (Invoke-RestMethod -Uri "$API/voices" -Headers $headers -UseBasicParsing).voices
  } catch {
    Write-Host ''
    Write-Host 'A chave nao funcionou (talvez tenha sido apagada no ElevenLabs).' -ForegroundColor Red
    Write-Host $_.ErrorDetails.Message
    Remove-Item $arqChave -ErrorAction SilentlyContinue
    if ($tentativa -eq 1) { Write-Host 'Crie uma chave nova no ElevenLabs e cole aqui.'; $key = Pedir-Chave } else { exit 1 }
  }
}

$personagens = @(
  @('caca', 'Caca, a capivara: voz feminina, calma e carinhosa'),
  @('zeca', 'Zeca, o sapo: voz masculina jovem, animada'),
  @('nina', 'Nina, a oncinha: voz de menina, aguda e alegre'),
  @('tuca', 'Tuca, o tucano: voz bem aguda e teatral')
)

$vozes = @{}
if (Test-Path $arqVozes) {
  Get-Content $arqVozes | ForEach-Object { $p = $_ -split '=', 2; if ($p.Count -eq 2) { $vozes[$p[0]] = $p[1] } }
}

$faltam = @($personagens | Where-Object { -not $vozes.ContainsKey($_[0]) })
if ($faltam.Count -gt 0) {
  Write-Host ''
  Write-Host 'Vozes da sua conta:' -ForegroundColor Cyan
  for ($i = 0; $i -lt $lista.Count; $i++) {
    $v = $lista[$i]
    $rot = @()
    if ($v.labels) { $v.labels.PSObject.Properties | ForEach-Object { if ($_.Value) { $rot += $_.Value } } }
    Write-Host ("  {0,2}. {1}  ({2})" -f ($i + 1), $v.name, ($rot -join ', '))
  }
  Write-Host ''
  Write-Host 'Dica: para ouvir as vozes antes, abra o site do ElevenLabs. Para ter vozes em portugues,'
  Write-Host 'adicione vozes da Voice Library (filtro Portuguese) e abra este arquivo de novo.'
  Write-Host ''
  foreach ($p in $faltam) {
    do {
      $n = Read-Host ("Numero da voz para " + $p[1])
      $ok = ($n -match '^\d+$') -and ([int]$n -ge 1) -and ([int]$n -le $lista.Count)
      if (-not $ok) { Write-Host 'Digite um dos numeros da lista.' -ForegroundColor Red }
    } until ($ok)
    $vozes[$p[0]] = $lista[[int]$n - 1].voice_id
  }
  ($vozes.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) | Set-Content $arqVozes
}

# Qual voz gerou os audios atuais de cada personagem: se a voz mudar, os audios dele sao refeitos.
$arqUsadas = Join-Path $PSScriptRoot 'vozes_usadas.txt'
$usadas = @{}
if (Test-Path $arqUsadas) {
  Get-Content $arqUsadas | ForEach-Object { $p = $_ -split '=', 2; if ($p.Count -eq 2) { $usadas[$p[0]] = $p[1] } }
}
$falhouQuem = @{}

# Audios listados em refazer.txt (um nome por linha, sem .mp3) sao refeitos mesmo que ja existam.
$arqRefazer = Join-Path $PSScriptRoot 'refazer.txt'
$refazer = @{}
if (Test-Path $arqRefazer) {
  Get-Content $arqRefazer | ForEach-Object { $n = ($_.Trim() -replace '\.mp3$', ''); if ($n) { $refazer[$n] = $true } }
}
if ($refazer.Count -gt 0) { Write-Host ('Para refazer: ' + ($refazer.Keys -join ', ')) -ForegroundColor Cyan }

# Ajustes de voz de cada personagem e textos trocados ficam em ajustes_vozes.json (editado pela tela AJUSTAR_VOZES.bat).
$ajustes = @{}; $textosNovos = @{}
$cfg = Get-Content (Join-Path $PSScriptRoot 'ajustes_vozes.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$cfg.personagens.PSObject.Properties | ForEach-Object { $ajustes[$_.Name] = $_.Value }
$modeloVoz = if ($cfg.modelo) { $cfg.modelo } else { 'eleven_multilingual_v2' }
Write-Host "Modelo de voz: $modeloVoz" -ForegroundColor DarkGray
if ($cfg.textos) { $cfg.textos.PSObject.Properties | ForEach-Object { $textosNovos[$_.Name] = $_.Value } }

$falas = @(
  @('abertura_nina', 'nina', 'Oi! Vamos contar e cantar com a Bicharada?'),
  @('fim_caca', 'caca', 'Que show! Agora a Bicharada vai descansar. Até a próxima!'),
  @('apresenta_caca', 'caca', 'Eu sou a Cacá, a capivara!'),
  @('apresenta_zeca', 'zeca', 'Eu sou o Zeca! Cuá, cuá!'),
  @('apresenta_nina', 'nina', 'Eu sou a Nina, a oncinha! Rrrá!'),
  @('apresenta_tuca', 'tuca', 'Eu sou o Tuca, o tucano cantor!'),
  @('oba_caca', 'caca', 'Ebaaa! Conseguimos!'),
  @('oba_zeca', 'zeca', 'Muito bem!'),
  @('oba_nina', 'nina', 'Isso aí! Você é demais!'),
  @('oba_tuca', 'tuca', 'Que lindo! Bravo, bravo!'),
  @('r1_pedido_caca', 'caca', 'Me ajuda a pegar duas mangas?'),
  @('r2_pedido_zeca', 'zeca', 'Me ajuda a pegar três bananas?'),
  @('r3_pedido_nina', 'nina', 'Me ajuda a pegar três morangos?'),
  @('r4_pedido_tuca', 'tuca', 'Me ajuda a pegar quatro uvas?'),
  @('r5_pedido_caca', 'caca', 'Agora o último! Me ajuda a pegar cinco cajus?'),
  @('r1_conta1_caca', 'caca', 'Uma!'),
  @('r1_conta2_caca', 'caca', 'Duas!'),
  @('r2_conta1_zeca', 'zeca', 'Uma!'),
  @('r2_conta2_zeca', 'zeca', 'Duas!'),
  @('r2_conta3_zeca', 'zeca', 'Três!'),
  @('r3_conta1_nina', 'nina', 'Um!'),
  @('r3_conta2_nina', 'nina', 'Dois!'),
  @('r3_conta3_nina', 'nina', 'Três!'),
  @('r4_conta1_tuca', 'tuca', 'Uma!'),
  @('r4_conta2_tuca', 'tuca', 'Duas!'),
  @('r4_conta3_tuca', 'tuca', 'Três!'),
  @('r4_conta4_tuca', 'tuca', 'Quatro!'),
  @('r5_conta1_caca', 'caca', 'Um!'),
  @('r5_conta2_caca', 'caca', 'Dois!'),
  @('r5_conta3_caca', 'caca', 'Três!'),
  @('r5_conta4_caca', 'caca', 'Quatro!'),
  @('r5_conta5_caca', 'caca', 'Cinco!'),
  @('r2_erro_zeca', 'zeca', 'Opa! Essa não é banana. Procura a banana amarelinha!'),
  @('r3_erro_nina', 'nina', 'Hum, essa não é morango! Cadê o morango vermelhinho?'),
  @('r4_erro_tuca', 'tuca', 'Ih, essa não é uva! A uva é roxinha!'),
  @('r5_erro_caca', 'caca', 'Quase! Essa não é caju. Procura o caju!'),
  @('r1_pergunta_caca', 'caca', 'Que fruta é essa? Fala pra mim!'),
  @('r2_pergunta_zeca', 'zeca', 'Que fruta é essa? Fala pra mim!'),
  @('r3_pergunta_nina', 'nina', 'Que fruta é essa? Fala pra mim!'),
  @('r4_pergunta_tuca', 'tuca', 'Que fruta é essa? Fala pra mim!'),
  @('r5_pergunta_caca', 'caca', 'Que fruta é essa? Fala pra mim!'),
  # Respostas soletradas (para quem está aprendendo a ler): nome, sílabas pausadas, nome de novo.
  @('r1_resposta_caca', 'caca', 'Essa é a manga! Man... ga... Manga!'),
  @('r2_resposta_zeca', 'zeca', 'Essa é a banana! Ba... na... na... Banana!'),
  @('r3_resposta_nina', 'nina', 'Esse é o morango! Mo... ran... go... Morango!'),
  @('r4_resposta_tuca', 'tuca', 'Essa é a uva! U... va... Uva!'),
  @('r5_resposta_caca', 'caca', 'Esse é o caju! Ca... ju... Caju!'),
  # Cantinho da Cacá (bichinho virtual): ela chega, se enfeita, come as frutas (soletrando) e brinca.
  @('pet_chega_caca', 'caca', 'Oba! Você veio brincar comigo! O que vamos fazer?'),
  @('pet_tchau_caca', 'caca', 'Foi muito divertido! Tchau, tchau!'),
  @('pet_enfeite1_caca', 'caca', 'Fiquei linda!'),
  @('pet_enfeite2_caca', 'caca', 'Adorei! Combinou comigo!'),
  @('pet_enfeite3_caca', 'caca', 'Uau! Que chique!'),
  @('pet_come_manga_caca', 'caca', 'Hum, que delícia de manga! Man... ga... Manga!'),
  @('pet_come_banana_caca', 'caca', 'Hum, que delícia de banana! Ba... na... na... Banana!'),
  @('pet_come_morango_caca', 'caca', 'Hum, que delícia de morango! Mo... ran... go... Morango!'),
  @('pet_come_uva_caca', 'caca', 'Hum, que delícia de uva! U... va... Uva!'),
  @('pet_come_caju_caca', 'caca', 'Hum, que delícia de caju! Ca... ju... Caju!'),
  @('pet_cocegas_caca', 'caca', 'Hihihi! Para, faz cócegas!'),
  @('pet_bola_caca', 'caca', 'Peguei! Joga de novo!'),
  @('pet_bolhas_caca', 'caca', 'Olha quantas bolhas! Estoura!'),
  @('pet_danca_caca', 'caca', 'Vamos dançar!')
)

$musicas = @(
  @('m1_tema', 90000, 'Música infantil brasileira original, alegre, 112 bpm, ukulele, percussão de brinquedo, palmas, xilofone. Vozes de personagens fofos de desenho animado cantando em português do Brasil, letra bem articulada, coro no refrão. Letra:
[Verse]
Pula, pula, a Cacá chegou!
Nossa Capivara que o mato gostou.
Mexe o corpinho pra lá e pra cá,
Na beira do rio, ela quer dançar.
[Chorus]
Balança o bumbum, um, dois, três!
Balança o bumbum, tudo outra vez!
Dança na floresta, que festa legal,
Dança na floresta, é pura alegria no quintal!
[Verse]
O Zeca Sapo dá um salto assim,
Lá na lagoa, perto do capim.
A Nina Oncinha, pintada e faceira,
Corre e se esconde atrás da mangueira.
[Chorus]
Balança o bumbum, um, dois, três!
Balança o bumbum, tudo outra vez!
Dança na floresta, que festa legal,
Dança na floresta, é pura alegria no quintal!
[Verse]
Olha pro céu, quem é que vem lá?
O Tuca Tucano quer nos visitar.
Bate as asinhas, o bico é grandão,
Faz um barulho e bate o pé no chão.
[Chorus]
Balança o bumbum, um, dois, três!
Balança o bumbum, tudo outra vez!
Dança na floresta, que festa legal,
Dança na floresta, é pura alegria no quintal!
[Outro]
Cacá e o Zeca,
A Nina e o Tuca,
Todo mundo dança,
Ninguém fica na cuca!'),
  @('m2_comemora', 12000, 'Vinheta infantil brasileira curta e alegre, 120 bpm, palmas no ritmo, ukulele, coro alegre de crianças e personagens fofos de desenho animado, português do Brasil, letra bem articulada. Letra:
Muito bem, você acertou!
Bata palmas com alegria!
Bata palmas, bate, bate!
Bata palmas, que energia!'),
  @('m3_ninar', 60000, 'Canção de ninar brasileira original, 70 bpm, voz feminina suave e acolhedora, violão dedilhado, caixinha de música, calma, português do Brasil. Letra:
Dorme, dorme, Bicharada,
que a lua já chegou.
A capivara boceja,
o sapinho cochilou.
A oncinha faz ronrom,
o tucano se aninhou.
Amanhã tem cantoria,
a brincadeira acabou.')
)

function Enviar($url, $corpo, $destino, $tempo) {
  $json = $corpo | ConvertTo-Json -Depth 6
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
  for ($t = 1; $t -le 3; $t++) {
    try {
      $tmp = "$destino.tmp"
      Invoke-WebRequest -Uri $url -Method Post -Headers $headers -ContentType 'application/json; charset=utf-8' `
        -Body $bytes -OutFile $tmp -UseBasicParsing -TimeoutSec $tempo | Out-Null
      Move-Item -Force $tmp $destino
      return $true
    } catch {
      $msg = $_.ErrorDetails.Message
      if (-not $msg) { $msg = $_.Exception.Message }
      if ($t -lt 3) { Start-Sleep -Seconds (5 * $t) } else {
        Write-Host "   erro: $msg" -ForegroundColor Red
        Add-Content -Path (Join-Path $PSScriptRoot 'erros.txt') -Value ("[" + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + "] " + (Split-Path $destino -Leaf) + ": " + $msg)
      }
      if (Test-Path "$destino.tmp") { Remove-Item "$destino.tmp" -ErrorAction SilentlyContinue }
    }
  }
  return $false
}

# Emoções de cada fala (marcações do Eleven v3/v4, em inglês; o bicho não lê as marcações).
# Só valem se o texto sem as marcações for igual ao texto atual da fala. Se o Tales trocar o texto pela tela
# de ajuste, vale o texto dele (com as marcações que ele puser, ou nenhuma), para nunca falar um texto velho.
$emocoes = @{
  'abertura_nina' = '[excited] Oi! [cheerfully] Vamos contar e cantar com a Bicharada?'
  'fim_caca' = '[happily] Que show! [softly] Agora a Bicharada vai descansar. [warmly] Até a próxima!'
  'apresenta_caca' = '[cheerfully] Oie! [warmly] Eu sou a Cacá. A capivara!'
  'apresenta_zeca' = '[playfully] E aí! [proudly] Eu sou o Zeca.'
  'apresenta_nina' = '[excited] Eu sou a Nina, a oncinha! [playfully] Rrrá!'
  'apresenta_tuca' = '[dramatically] Eu sou o Tuca, [proudly] o tucano cantor!'
  'oba_caca' = '[excited] Eba! [laughs] Conseguimos!!'
  'oba_zeca' = '[excited] Muito bem!'
  'oba_nina' = '[excited] Isso aí! [proudly] Você é demais!'
  'oba_tuca' = '[amazed] Que lindo! [excited] Bravo, bravo!'
  'r1_pedido_caca' = '[cheerfully] Me ajuda a pegar duas mangas?'
  'r2_pedido_zeca' = '[cheerfully] Me ajuda a pegar três bananas?'
  'r3_pedido_nina' = '[cheerfully] Me ajuda a pegar três morangos?'
  'r4_pedido_tuca' = '[cheerfully] Me ajuda a pegar quatro uvas?'
  'r5_pedido_caca' = '[excited] Agora o último! [cheerfully] Me ajuda a pegar cinco cajus?'
  'r2_erro_zeca' = '[surprised] Opa! [playfully] Essa não é banana. [encouragingly] Procura a banana amarelinha!'
  'r3_erro_nina' = '[playfully] Hum, essa não é morango! [curious] Cadê o morango vermelhinho?'
  'r4_erro_tuca' = '[surprised] Ih, essa não é uva! [encouragingly] A uva é roxinha!'
  'r5_erro_caca' = '[gently] Quase! Essa não é um caju. [encouragingly] Procura o caju!'
  'r1_resposta_caca' = '[cheerfully] Essa é a manga! [slowly] Man... ga... [excited] Manga!'
  'r2_resposta_zeca' = '[cheerfully] Essa é a banana! [slowly] Ba... na... na... [excited] Banana!'
  'r3_resposta_nina' = '[cheerfully] Esse é o morango! [slowly] Mo... ran... go... [excited] Morango!'
  'r4_resposta_tuca' = '[cheerfully] Essa é a uva! [slowly] U... va... [excited] Uva!'
  'r5_resposta_caca' = '[cheerfully] Esse é o caju! [slowly] Ca... ju... [excited] Caju!'
  'pet_chega_caca' = '[excited] Oba! Você veio brincar comigo! [curious] O que vamos fazer?'
  'pet_tchau_caca' = '[warmly] Foi muito divertido! [cheerfully] Tchau, tchau!'
  'pet_enfeite1_caca' = '[happily] Fiquei linda!'
  'pet_enfeite2_caca' = '[excited] Adorei! [proudly] Combinou comigo!'
  'pet_enfeite3_caca' = '[amazed] Uau! Que chique!'
  'pet_come_manga_caca' = '[happily] Hum, que delícia de manga! [slowly] Man... ga... [excited] Manga!'
  'pet_come_banana_caca' = '[happily] Hum, que delícia de banana! [slowly] Ba... na... na... [excited] Banana!'
  'pet_come_morango_caca' = '[happily] Hum, que delícia de morango! [slowly] Mo... ran... go... [excited] Morango!'
  'pet_come_uva_caca' = '[happily] Hum, que delícia de uva! [slowly] U... va... [excited] Uva!'
  'pet_come_caju_caca' = '[happily] Hum, que delícia de caju! [slowly] Ca... ju... [excited] Caju!'
  'pet_cocegas_caca' = '[laughs] Hihihi! [playfully] Para, faz cócegas!'
  'pet_bola_caca' = '[excited] Peguei! [playfully] Joga de novo!'
  'pet_bolhas_caca' = '[amazed] Olha quantas bolhas! [playfully] Estoura!'
  'pet_danca_caca' = '[excited] Vamos dançar!'
  'r1_pergunta_caca' = '[curious] Que fruta é essa? [playfully] Fala pra mim!'
  'r2_pergunta_zeca' = '[curious] Que fruta é essa? [playfully] Fala pra mim!'
  'r3_pergunta_nina' = '[curious] Que fruta é essa? [playfully] Fala pra mim!'
  'r4_pergunta_tuca' = '[curious] Que fruta é essa? [playfully] Fala pra mim!'
  'r5_pergunta_caca' = '[curious] Que fruta é essa? [playfully] Fala pra mim!'
  'r1_conta1_caca' = '[excited] Uma'
  'r1_conta2_caca' = '[excited] Duas!'
  'r2_conta1_zeca' = '[excited] Uma!'
  'r2_conta2_zeca' = '[excited] Duas!'
  'r2_conta3_zeca' = '[excited] Três!'
  'r3_conta1_nina' = '[excited] Um!'
  'r3_conta2_nina' = '[excited] Dois!'
  'r3_conta3_nina' = '[excited] Três!'
  'r4_conta1_tuca' = '[excited] Uma!'
  'r4_conta2_tuca' = '[excited] Duas!'
  'r4_conta3_tuca' = '[excited] Três!'
  'r4_conta4_tuca' = '[excited] Quatro!'
  'r5_conta1_caca' = '[excited] Um!'
  'r5_conta2_caca' = '[excited] Dois!'
  'r5_conta3_caca' = '[excited] Três!'
  'r5_conta4_caca' = '[excited] Quatro!'
  'r5_conta5_caca' = '[excited] Cinco!'
}
$tiraMarcas = { param($t) (($t -replace '\[[^\]]*\]\s*', '') -replace '\s+', ' ').Trim() }

$feitos = 0; $falhas = 0
Write-Host ''
Write-Host 'Gerando as falas...' -ForegroundColor Cyan
foreach ($f in $falas) {
  $nome = $f[0]; $quem = $f[1]; $texto = $f[2]
  if ($textosNovos.ContainsKey($nome)) { $texto = $textosNovos[$nome] }
  $destino = Join-Path $pasta "$nome.mp3"
  if ((Test-Path $destino) -and ($usadas[$quem] -eq $vozes[$quem]) -and -not $refazer[$nome]) { Write-Host "   pulando $nome (ja existe)"; continue }
  $aj = $ajustes[$quem]
  $falado = $texto
  if ($modeloVoz -eq 'eleven_multilingual_v2') { $falado = & $tiraMarcas $texto }   # o v2 leria as marcações em voz alta
  elseif ($texto -notmatch '\[' -and $emocoes.ContainsKey($nome) -and ((& $tiraMarcas $emocoes[$nome]) -eq $texto)) { $falado = $emocoes[$nome] }
  $corpo = @{
    text = $falado
    model_id = $modeloVoz
    voice_settings = @{ stability = $aj.stability; similarity_boost = $aj.similarity_boost; style = $aj.style; use_speaker_boost = $true; speed = $aj.speed }
  }
  # Contagens sao uma palavra so; no Multilingual v2 o pedido da rodada vai como contexto (nao e falado) para a
  # pronuncia sair clara. No v4 o contexto deixava a contagem com cara de pergunta ("Duas?"), entao fica sem.
  if ($modeloVoz -eq 'eleven_multilingual_v2' -and $nome -match '^(r\d+)_conta') {
    $pedido = $falas | Where-Object { $_[0] -like "$($Matches[1])_pedido_*" } | Select-Object -First 1
    if ($pedido) { $corpo.previous_text = $pedido[2] }
  }
  if (Enviar "$API/text-to-speech/$($vozes[$quem])?output_format=mp3_44100_128" $corpo $destino 120) {
    Write-Host "   ok  $nome" -ForegroundColor Green; $feitos++
  } else { $falhas++; $falhouQuem[$quem] = $true }
}

foreach ($p in $personagens) { if (-not $falhouQuem.ContainsKey($p[0])) { $usadas[$p[0]] = $vozes[$p[0]] } }
($usadas.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) | Set-Content $arqUsadas

Write-Host ''
Write-Host 'Compondo as musicas (cada uma pode levar alguns minutos)...' -ForegroundColor Cyan
foreach ($m in $musicas) {
  $nome = $m[0]
  $destino = Join-Path $pasta "$nome.mp3"
  if ((Test-Path $destino) -and -not $refazer[$nome]) { Write-Host "   pulando $nome (ja existe)"; continue }
  Write-Host "   compondo $nome..."
  $corpo = @{ prompt = $m[2]; music_length_ms = $m[1]; model_id = 'music_v1' }
  if (Enviar "$API/music" $corpo $destino 600) { Write-Host "   ok  $nome" -ForegroundColor Green; $feitos++ } else { $falhas++ }
}

# Tempo de cada palavra cantada (transcricao do ElevenLabs), para o jogo mexer a boca so quando ha voz e
# acender o karaoke na hora certa. Fica em audios/<musica>.tempos.json; e refeito quando a musica muda.
Write-Host ''
Write-Host 'Marcando o tempo das letras das musicas...' -ForegroundColor Cyan
Add-Type -AssemblyName System.Net.Http
foreach ($m in $musicas) {
  $nome = $m[0]
  $mp3 = Join-Path $pasta "$nome.mp3"
  $tempos = Join-Path $pasta "$nome.tempos.json"
  if (-not (Test-Path $mp3)) { continue }
  if ((Test-Path $tempos) -and (Get-Item $tempos).LastWriteTime -gt (Get-Item $mp3).LastWriteTime) { Write-Host "   pulando $nome (ja marcado)"; continue }
  try {
    $cli = New-Object System.Net.Http.HttpClient
    $cli.Timeout = [TimeSpan]::FromSeconds(300)
    $cli.DefaultRequestHeaders.Add('xi-api-key', $key.Trim())
    $form = New-Object System.Net.Http.MultipartFormDataContent
    $form.Add((New-Object System.Net.Http.StringContent 'scribe_v1'), 'model_id')
    $form.Add((New-Object System.Net.Http.StringContent 'por'), 'language_code')
    $form.Add((New-Object System.Net.Http.StringContent 'word'), 'timestamps_granularity')
    $form.Add((New-Object System.Net.Http.ByteArrayContent(, [IO.File]::ReadAllBytes($mp3))), 'file', "$nome.mp3")
    $resp = $cli.PostAsync("$API/speech-to-text", $form).Result
    $texto = $resp.Content.ReadAsStringAsync().Result
    if (-not $resp.IsSuccessStatusCode) { throw $texto }
    $palavras = @(($texto | ConvertFrom-Json).words | Where-Object { $_.type -eq 'word' } |
      ForEach-Object { [ordered]@{ p = $_.text; i = [math]::Round($_.start, 2); f = [math]::Round($_.end, 2) } })
    [IO.File]::WriteAllText($tempos, (ConvertTo-Json @($palavras) -Compress), (New-Object System.Text.UTF8Encoding $false))
    Write-Host "   ok  $nome ($($palavras.Count) palavras)" -ForegroundColor Green
  } catch {
    Write-Host "   erro: $_" -ForegroundColor Red; $falhas++
    Add-Content -Path (Join-Path $PSScriptRoot 'erros.txt') -Value ("[" + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + "] $nome.tempos.json: $_")
  }
}

# Tempo de cada palavra nas respostas soletradas (alinhamento do ElevenLabs com o texto), para o jogo
# acender cada sílaba na hora em que o bicho fala. Fica em audios/<fala>.tempos.json.
Write-Host ''
Write-Host 'Marcando o tempo das sílabas nas respostas...' -ForegroundColor Cyan
foreach ($f in $falas) {
  $nome = $f[0]
  if ($nome -notmatch '_resposta_|^pet_come_') { continue }
  $texto = $f[2]; if ($textosNovos.ContainsKey($nome)) { $texto = $textosNovos[$nome] }
  $texto = & $tiraMarcas $texto   # o alinhamento usa só as palavras faladas
  $mp3 = Join-Path $pasta "$nome.mp3"; $tempos = Join-Path $pasta "$nome.tempos.json"
  if (-not (Test-Path $mp3)) { continue }
  if ((Test-Path $tempos) -and (Get-Item $tempos).LastWriteTime -gt (Get-Item $mp3).LastWriteTime) { Write-Host "   pulando $nome (ja marcado)"; continue }
  try {
    $cli = New-Object System.Net.Http.HttpClient
    $cli.Timeout = [TimeSpan]::FromSeconds(120)
    $cli.DefaultRequestHeaders.Add('xi-api-key', $key.Trim())
    $form = New-Object System.Net.Http.MultipartFormDataContent
    $form.Add((New-Object System.Net.Http.StringContent($texto, [System.Text.Encoding]::UTF8)), 'text')
    $form.Add((New-Object System.Net.Http.ByteArrayContent(, [IO.File]::ReadAllBytes($mp3))), 'file', "$nome.mp3")
    $resp = $cli.PostAsync("$API/forced-alignment", $form).Result
    $txt = $resp.Content.ReadAsStringAsync().Result
    if (-not $resp.IsSuccessStatusCode) { throw $txt }
    $palavras = @(($txt | ConvertFrom-Json).words | Where-Object { $_.text.Trim() } |
      ForEach-Object { [ordered]@{ p = $_.text.Trim(); i = [math]::Round($_.start, 2); f = [math]::Round($_.end, 2) } })
    [IO.File]::WriteAllText($tempos, (ConvertTo-Json @($palavras) -Compress), (New-Object System.Text.UTF8Encoding $false))
    Write-Host "   ok  $nome ($($palavras.Count) palavras)" -ForegroundColor Green
  } catch {
    Write-Host "   erro: $_" -ForegroundColor Red; $falhas++
    Add-Content -Path (Join-Path $PSScriptRoot 'erros.txt') -Value ("[" + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + "] $nome.tempos.json: $_")
  }
}

# Efeitos sonoros (ElevenLabs Sound Effects). O jogo muda o tom de cada um por personagem.
$efeitos = @(
  @('sfx_bocejo', 2.0, 'One long soft sleepy yawn from a cute cartoon baby animal, children''s animation sound effect, no music, no words'),
  @('sfx_vibra', 3.5, 'A small group of happy young children cheering yay and clapping their hands excitedly, joyful celebration applause, bright and friendly, no music, no words'),
  # sfx_palma: escolhida pelo Tales em comparar_palmas ("Palma macia", cortada em 0,35 s e com pico em -3 dB).
  # Se for refeita por aqui, sai sem esse corte: prefira copiar comparar_palmas/opcao_macia.mp3.
  @('sfx_palma', 1.0, 'One soft warm hand clap, gentle and round, cozy small room, children''s cartoon sound effect, no music, no voices')
  # sfx_ronco foi tirado: o Tales achou o ronco monstruoso. O ronco no jogo e so visual.
)
Write-Host ''
Write-Host 'Gerando os efeitos sonoros...' -ForegroundColor Cyan
foreach ($e in $efeitos) {
  $nome = $e[0]
  $destino = Join-Path $pasta "$nome.mp3"
  if ((Test-Path $destino) -and -not $refazer[$nome]) { Write-Host "   pulando $nome (ja existe)"; continue }
  $corpo = @{ text = $e[2]; duration_seconds = $e[1]; prompt_influence = 0.6 }
  if (Enviar "$API/sound-generation" $corpo $destino 120) { Write-Host "   ok  $nome" -ForegroundColor Green; $feitos++ } else { $falhas++ }
}

Write-Host ''
if ($falhas -eq 0) {
  if (Test-Path $arqRefazer) { Clear-Content $arqRefazer }
  Write-Host "Pronto! Todos os audios estao na pasta 'audios', ao lado deste arquivo." -ForegroundColor Yellow
  Write-Host 'Volte para o Claude e avise que terminou.'
} else {
  Write-Host "$feitos audios gerados, $falhas com erro. Abra este arquivo de novo para tentar so os que faltaram." -ForegroundColor Yellow
  Write-Host 'Se o erro falar de creditos ou plano, o plano do ElevenLabs precisa ser maior.'
}
