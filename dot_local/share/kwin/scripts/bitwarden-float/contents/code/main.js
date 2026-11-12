// Krohnkite décide à l'ouverture d'une fenêtre si elle flotte. La fenêtre détachée de Bitwarden s'ouvre
// sous le titre « Mozilla Firefox », comme toute fenêtre Firefox, et ne prend le sien
// (« Extension: (Bitwarden Password Manager) - … ») qu'ensuite : une règle floatConfig par titre ne la
// voit donc pas. Ce script attend ce titre, une seule fois par fenêtre, et la bascule en flottant avec
// le raccourci de Krohnkite, qui agit sur la fenêtre active.
workspace.windowAdded.connect(function (w) {
    if (w.resourceClass !== "firefox") return;
    function check() {
        if (w.caption.indexOf("(Bitwarden Password Manager)") < 0) return;
        w.captionChanged.disconnect(check);
        workspace.activeWindow = w;
        callDBus("org.kde.kglobalaccel", "/component/kwin", "org.kde.kglobalaccel.Component",
                 "invokeShortcut", "KrohnkiteToggleFloat");
    }
    w.captionChanged.connect(check);
});
