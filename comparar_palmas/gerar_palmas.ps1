# Gera opções de som de palma para comparar (página comparar_palmas/index.html).
$ErrorActionPreference = 'Stop'
$raiz = Split-Path $PSScriptRoot -Parent
$s = Get-Content (Join-Path $raiz 'chave_elevenlabs.dat') | ConvertTo-SecureString
$key = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($s))
$headers = @{ 'xi-api-key' = $key.Trim() }
$opcoes = @(
  @('turma',   'A group of happy young children clapping their hands together exactly once, one single unison clap, warm and bright, no voices, no music'),
  @('macia',   'One soft warm hand clap, gentle and round, cozy small room, children''s cartoon sound effect, no music, no voices'),
  @('desenho', 'A cute cartoon clap sound effect, bouncy and playful, for a children''s animation, one single hit, no music, no voices'),
  @('crianca', 'A small child clapping hands once, light natural clap with a little room ambience, no music, no voices')
)
foreach ($o in $opcoes) {
  $corpo = @{ text = $o[1]; duration_seconds = 1.0; prompt_influence = 0.7 } | ConvertTo-Json
  $destino = Join-Path $PSScriptRoot ("bruto_" + $o[0] + ".mp3")
  Invoke-WebRequest -Uri 'https://api.elevenlabs.io/v1/sound-generation' -Method Post -Headers $headers -ContentType 'application/json; charset=utf-8' `
    -Body ([Text.Encoding]::UTF8.GetBytes($corpo)) -OutFile $destino -UseBasicParsing -TimeoutSec 120 | Out-Null
  "ok " + $o[0]
}
