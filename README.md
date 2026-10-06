# Bicharada Cantante

Jogo infantil (3 a 6 anos) de contar e cantar com a Bicharada: Cacá (capivara), Zeca (sapo), Nina (oncinha) e Tuca (tucano).

- Jogo inteiro em `index.html` (HTML, CSS e JavaScript, sem build).
- Vozes e músicas em `audios/` (geradas com ElevenLabs), videoclipe em `videos/clipe_tema2.mp4`, cenário em `imagens/`.
- Ferramentas locais (Windows): `GERAR_AUDIOS.bat` gera as vozes e `AJUSTAR_VOZES.bat` abre a tela de ajuste. Elas pedem a chave do ElevenLabs, que fica só no computador e não vai para o repositório.

Para jogar localmente: `python -m http.server 8000` nesta pasta e abrir http://localhost:8000.
O microfone precisa de HTTPS ou localhost.
