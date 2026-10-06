# Gera amostras para comparar entonação: fala atual (Multilingual v2) x Eleven v3 x Eleven v4,
# com marcações de emoção. Confere cada amostra pela transcrição. Usado pela página comparar.html.
$ErrorActionPreference = 'Stop'
$raiz = Split-Path $PSScriptRoot -Parent
$s = Get-Content (Join-Path $raiz 'chave_elevenlabs.dat') | ConvertTo-SecureString
$key = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($s))
$vozes = @{}; Get-Content (Join-Path $raiz 'vozes_escolhidas.txt') | % { $a = $_ -split '=', 2; $vozes[$a[0]] = $a[1] }
$aj = (Get-Content (Join-Path $raiz 'ajustes_vozes.json') -Raw -Encoding UTF8 | ConvertFrom-Json).personagens
Add-Type -AssemblyName System.Net.Http
$c = New-Object System.Net.Http.HttpClient; $c.Timeout = [TimeSpan]::FromSeconds(120); $c.DefaultRequestHeaders.Add('xi-api-key', $key.Trim())

# fala atual (arquivo do jogo), texto puro, texto com marcações
$linhas = @(
  @('caca', 'r1_pergunta_caca', 'Que fruta é essa? Fala pra mim!', '[curious] Que fruta é essa? [playfully] Fala pra mim!'),
  @('caca', 'oba_caca', 'Eba! Conseguimos!!', '[excited] Eba! [laughs] Conseguimos!!'),
  @('zeca', 'r2_pedido_zeca', 'Me ajuda a pegar três bananas?', '[cheerfully] Me ajuda a pegar três bananas?'),
  @('zeca', 'r2_erro_zeca', 'Opa! Essa não é banana. Procura a banana amarelinha!', '[surprised] Opa! [playfully] Essa não é banana. [encouragingly] Procura a banana amarelinha!'),
  @('nina', 'abertura_nina', 'Oi! Vamos contar e cantar com a Bicharada?', '[excited] Oi! [cheerfully] Vamos contar e cantar com a Bicharada?'),
  @('nina', 'oba_nina', 'Isso aí! Você é demais!', '[excited] Isso aí! [proudly] Você é demais!'),
  @('tuca', 'apresenta_tuca', 'Eu sou o Tuca, o tucano cantor!', '[dramatically] Eu sou o Tuca, [proudly] o tucano cantor!'),
  @('tuca', 'oba_tuca', 'Que lindo! Bravo, bravo!', '[amazed] Que lindo! [excited] Bravo, bravo!')
)
function STT($bytes) {
  $f = New-Object System.Net.Http.MultipartFormDataContent
  $f.Add((New-Object System.Net.Http.StringContent 'scribe_v1'), 'model_id'); $f.Add((New-Object System.Net.Http.StringContent 'por'), 'language_code')
  $f.Add((New-Object System.Net.Http.ByteArrayContent(, $bytes)), 'file', 'a.mp3')
  ($c.PostAsync('https://api.elevenlabs.io/v1/speech-to-text', $f).Result.Content.ReadAsStringAsync().Result | ConvertFrom-Json).text
}
function TTS($quem, $texto, $modelo) {
  $a = $aj.$quem
  $vs = @{ stability = $a.stability; similarity_boost = $a.similarity_boost; style = $a.style; use_speaker_boost = $true }
  if ($modelo -eq 'eleven_v3') { $vs = @{ stability = 0.5; similarity_boost = $a.similarity_boost } }   # v3: 0 criativo, 0.5 natural, 1 firme
  $corpo = @{ text = $texto; model_id = $modelo; voice_settings = $vs } | ConvertTo-Json -Depth 5
  $r = $c.PostAsync("https://api.elevenlabs.io/v1/text-to-speech/$($vozes[$quem])?output_format=mp3_44100_128",
        (New-Object System.Net.Http.StringContent($corpo, [Text.Encoding]::UTF8, 'application/json'))).Result
  if (-not $r.IsSuccessStatusCode) { throw "$modelo : $($r.Content.ReadAsStringAsync().Result)" }
  return $r.Content.ReadAsByteArrayAsync().Result
}
$saida = @()
foreach ($l in $linhas) {
  $quem, $fala, $puro, $marcado = $l
  $item = [ordered]@{ quem = $quem; fala = $fala; texto = $puro; atual = "../audios/$fala.mp3"; versoes = @() }
  foreach ($modelo in 'eleven_v3', 'eleven_v4') {
    $arq = "${fala}__$modelo.mp3"
    try {
      $b = TTS $quem $marcado $modelo
      [IO.File]::WriteAllBytes((Join-Path $PSScriptRoot $arq), $b)
      $t = STT $b
      $item.versoes += [ordered]@{ modelo = $modelo; arquivo = $arq; ouvido = $t }
      "{0,-17} {1,-10} -> {2}" -f $fala, $modelo, $t
    } catch { "{0,-17} {1,-10} ERRO {2}" -f $fala, $modelo, $_ }
  }
  $saida += $item
}
[IO.File]::WriteAllText((Join-Path $PSScriptRoot 'amostras.json'), (ConvertTo-Json $saida -Depth 6), (New-Object System.Text.UTF8Encoding $false))
"SALVO amostras.json"
