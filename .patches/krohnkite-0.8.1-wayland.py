# Filtre chezmoi (.chezmoiexternal.toml) : lit le .kwinscript de Krohnkite 0.8.1 sur stdin, écrit son
# script.js corrigé pour KWin 5.27 sous Wayland. Les fenêtres Wayland n'ont ni basicUnit ni windowId, et
# aucune n'a plus clientSize : une fenêtre XWayland avec un pas de redimensionnement (Webex) y menait.
# Sans ça, chaque placement lève une TypeError que Krohnkite avale, et rien n'est tuilé. Sans clientSize,
# le pas de redimensionnement est ignoré.
import io
import sys
import zipfile

js = zipfile.ZipFile(io.BytesIO(sys.stdin.buffer.read())).read("contents/code/script.js").decode()
for old, new in (
    ("if (!(this.client.basicUnit.width", "if (this.client.basicUnit && this.client.clientSize && !(this.client.basicUnit.width"),
    ("this.client.windowId.toString(16)", "String(this.client.windowId)"),
):
    # Échoue si la release change : le correctif serait alors à revoir.
    assert js.count(old) == 1, old
    js = js.replace(old, new)
sys.stdout.write(js)
