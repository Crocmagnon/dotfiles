# Defined interactively
function kobosavehl
    pushd "/Users/gaugendre/Nextcloud/Perso/50-59 - Divertissements & projets/51 - Mes lectures/51.02 - Book notes"
    cp -R /Volumes/KOBOeReader/.adds/koreader/clipboard/ ./
    python ./parse.py -f KOReaderClipping.json
    diskutil eject KOBOeReader
end
