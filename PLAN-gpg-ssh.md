# Plan : identités GPG et SSH (boulot + perso)

Fichier de passage entre machines, à supprimer (avec sa ligne dans `.chezmoiignore`) une fois le
plan terminé. Pas de hostname, d'email ni de secret du boulot ici : ils vont dans `.secrets/`.

Règle pour Claude (voir aussi `CLAUDE.md`) : modifications versionnées et commandes en lecture
libres ; tout ce qui touche hors du repo (`chezmoi apply`, `host.config`, clés, YubiKey,
keyserver, CDS, Stash) est lancé par Gabriel : lui donner les commandes, une étape à la fois, et
vérifier le résultat en lecture avant de passer à la suivante.

## Décisions

**Boulot** — une seule clé GPG (même fingerprint qu'aujourd'hui, on ajoute des sous-clés) :

```
pub  rsa4096 [SC]  clé maîtresse : logicielle sur le laptop (hors ligne plus tard), copie KeePassXC ; 2 ans
sub  rsa4096 [E]   chiffrement : YubiKey (sauvegardée avant keytocard)
sub  rsa4096 [S]   signature laptop : YubiKey
sub  rsa4096 [S]   signature serveur : logicielle, sur le serveur uniquement
sub  ed25519 [A]   SSH du laptop : YubiKey
```

- Le serveur signe seul (agents actifs laptop déconnecté) : d'où sa sous-clé logicielle, protégée
  par une passphrase propre au serveur, saisie après chaque reboot (cache gpg-agent de 400 jours
  en headless). Le serveur a sa propre clé SSH ed25519, logicielle (nouvelle : l'actuelle est partagée avec le laptop).
- YubiKey sans toucher (touch policy `off` sur sig/dec/aut), PIN demandé une fois par
  branchement (`forcesig` désactivé).
- Chaque machine choisit sa sous-clé par `user.signingkey = <FPR>!` dans `~/.config/git/host.config`.
- Sauvegarde : export de la clé complète (protégé par sa passphrase, différente du mot de passe
  KeePassXC et absente de la base) + certificat de révocation, en pièces jointes KeePassXC.
- Le support de `ssh -A` dans `config.fish` reste (pas utilisé au boulot, mais doit marcher).

**Perso** — pas de GPG : chaque machine signe avec sa clé SSH ed25519 (`gpg.format = ssh`),
enregistrée sur GitHub et Codeberg comme clé d'authentification **et** de signature.

**Routage git** (déjà dans le repo) : sur les machines boulot, identité boulot (GPG) par défaut,
`git/perso.config` (SSH) pour les remotes GitHub/Codeberg ; sur les machines perso, toujours
`perso.config`. Donc les clés SSH du laptop et du serveur du boulot doivent aussi être déclarées
comme clés de signature sur GitHub et Codeberg, et listées dans `dot_config/git/allowed_signers`.

## État

- [x] Config git versionnée (`perso.config`, `allowed_signers`, `includeIf`, email boulot dans
      `.secrets/encrypted_work_email`).
- [x] framework-gab : clé dans `allowed_signers`, déclarée sur GitHub et Codeberg (auth + signature).
- [ ] Desktop perso : clé à ajouter dans `allowed_signers` et sur les forges.
- [x] Étape 0 (2026-10-14), constats ci-dessous.
- [x] Étape 1 (2026-10-14) : export et certificat de révocation dans KeePassXC.
- [x] Étape 2 (2026-10-15) : sous-clés créées, tout expire le 2028-10-13.
- [x] Étape 3 (2026-10-15) : `boulot-2ans.asc` (5 clés secrètes) dans KeePassXC.
- [x] Étape 4 (2026-10-15) : serveur en `sec#`/`ssb#`, seule S_SRV en clair, passphrase propre.
- [x] Étape 5 (2026-10-15) : carte en rsa4096/rsa4096/ed25519 (S_LAPTOP, E, A), `forcesig` coupé,
      touch `off` partout ; trousseau du laptop en `ssb>` sauf S_SRV.
- [x] Étape 6 (2026-10-15) : S_SRV retirée du laptop ; la clé maîtresse y reste (décision).
- [x] Étape 8, laptop (2026-10-15) : `signingkey = S_LAPTOP!`, `email` retiré. Les remotes
      `ssh://git@github.com/…` et `ssh://git@codeberg.org/…` n'activaient pas `perso.config` :
      motifs `includeIf` ajoutés.
- [x] Étape 7 (2026-10-15) : CDS à jour (5 sous-clés), Stash et People (sans A) importés, trousseau
      public du serveur à jour. Le keyserver du bureau reprend People, avec du retard.
- [x] Étape 9 (2026-10-15) : clé A (`id_yubikey.pub`) déclarée sur People, Stash, GitHub et
      Codeberg ; clé dans `allowed_signers`. Laptop : ancienne clé en
      `id_ed25519.old`, `id_ed25519.pub` = clé A (`perso.config` inchangé). `ForwardAgent` retiré de
      `~/.ssh/host.config` (sdev, bastion) : le serveur n'utilise que sa propre clé. Serveur : nouvelle
      `id_ed25519` (dans son gpg-agent, déclarée partout), l'ancienne en `.old`.
- [x] PIN redemandé à chaque signature : scdaemon passait par l'applet PIV ; `disable-application piv`
      dans `scdaemon.conf`, versionné pour le laptop du bureau.
- [x] PIN et Admin PIN OpenPGP changés (2026-10-15).
- [x] Étape 8 serveur (2026-10-15) : `signingkey = S_SRV!`, dotfiles à jour (`chezmoi update`).
- [x] Étape 10 (2026-10-15) : signatures (laptop : S_LAPTOP et YubiKey perso ; serveur : S_SRV et
      clé SSH perso), chiffrement, SSH, « Verified » Codeberg, pipeline CDS depuis les deux
      machines, agent seul sur le serveur, reboot du serveur : tout OK.
- [~] Étape 11 : ancienne clé commune retirée de Stash, People, GitHub, Codeberg et du `sshcontrol`
      du laptop (2026-10-15). Restent : clé YubiKey à autoriser sur sdev (`authorized_keys`), puis
      `sshcontrol` du serveur ; fichiers `.old` et `gaugendre@bw` plus tard.

Fingerprints (publics) :
```
KEY       3A85F46E66CD7EABE5C1E5D40073D1CD7EC5A253
E         154D0C067EF550DDEF34873CE981A1B9D0437B7D
S_LAPTOP  A8841A0F83B116FECDB60ED672854AFCBB02E2E5
S_SRV     60D393872490131F2E84A746265B650812E3DCD6
A         EE55D23569386653257BECA21B836F73966153BC
```

## Constats de l'inventaire

- Clé boulot : RSA 4096 `[SC]` + sous-clé RSA 4096 `[E]`, toutes deux jusqu'au 2027-04-02. Pas de
  certificat de révocation (`openpgp-revocs.d` absent) : à générer à l'étape 1.
- YubiKey 5 NFC, firmware 5.4.3 (ed25519 OK). **Le slot OTP déverrouille le disque du laptop**
  (`yubikey-luks`, challenge-response HMAC-SHA1 dans `crypttab`) : ne jamais lancer `ykman otp …`,
  ne pas désactiver l'interface OTP (`ykman config usb`), pas de reset global. OpenPGP, PIV et FIDO2
  sont des applets séparés, sans effet sur l'OTP.
- Applet OpenPGP déjà rempli : 3 clés nistp384 de 2021, titulaire « Daniel Goncalves », absentes du
  trousseau, à écraser. PIN et Admin PIN inconnus : `ykman openpgp reset` à l'étape 5. `forcesig` actif (à couper à l'étape 5).
- Le serveur a la clé boulot **complète** (maîtresse et E en clair), plus une clé ed25519 créée le
  2026-10-02 (`[SC]`, `[A]`, `[E]`), reste d'un test : à supprimer à l'étape 4. Pas de logind ni de systemd utilisateur (sshd utilisateur,
  gpg-agent lancé en démon jusqu'au reboot) : `Linger` ne s'applique pas. Pas de `/run/user` :
  passer les fichiers secrets par `/dev/shm`.
- SSH : **le laptop et le serveur partagent la même `~/.ssh/id_ed25519`** (avec passphrase), copiée
  dans le gpg-agent des deux machines par `AddKeysToAgent`. Le gpg-agent du laptop sert aussi une
  clé RSA 4096 `gaugendre@bw`. Le `sshcontrol` du serveur garde une entrée sans clé derrière.

## Étapes

Dans les commandes : `KEY` = fingerprint de la clé maîtresse, `S_LAPTOP`, `S_SRV`, `E`, `A` =
fingerprints des sous-clés (`gpg -K --with-subkey-fingerprints`). Les fichiers secrets passent par
`$XDG_RUNTIME_DIR` (tmpfs, jamais sur disque) et sont effacés aussitôt.

### 0. Inventaire (lecture seule — Claude peut le lancer)

Laptop (YubiKey branchée) :
```sh
gpg --version | head -1
gpg -K --keyid-format long --with-subkey-fingerprints --with-keygrip
ykman info; ykman openpgp info; gpg --card-status
ls ~/.ssh/; cat ~/.config/git/host.config ~/.ssh/host.config
```
Serveur (par `ssh` depuis le laptop) :
```sh
gpg --version | head -1; gpg -K --keyid-format long
ls ~/.ssh/; cat ~/.config/git/host.config ~/.ssh/host.config
loginctl show-user $USER -p Linger
```
À vérifier : firmware YubiKey ≥ 5.2.3 (ed25519 sur la carte) ; slots de la carte vides ou
contenant quoi (keytocard les écrase) ; capacités et expiration de la clé actuelle.

### 1. Sauvegarde de l'existant (laptop)

```sh
d=$XDG_RUNTIME_DIR/gpg-backup; mkdir -m 700 $d
gpg --armor --export-secret-keys $KEY > $d/boulot-avant.asc
ls ~/.gnupg/openpgp-revocs.d/     # certificat de révocation existant, sinon :
gpg --output $d/revocation.asc --gen-revoke $KEY
```
Joindre les fichiers à une entrée KeePassXC « GPG boulot », puis `shred -u $d/*`.

### 2. Nouvelles sous-clés (laptop)

```sh
gpg --quick-add-key $KEY rsa4096 sign 2y      # S_LAPTOP
gpg --quick-add-key $KEY rsa4096 sign 2y      # S_SRV
gpg --quick-add-key $KEY ed25519 auth 2y      # A
gpg --quick-set-expire $KEY 2y                # clé maîtresse
gpg --quick-set-expire $KEY 2y $E             # si E expire avant
```

### 3. Sauvegarde complète (laptop)

Même export qu'à l'étape 1 (`boulot-2ans.asc`), qui remplace l'ancien dans KeePassXC, puis
`shred -u`. C'est la seule copie de la clé maîtresse et de E après les étapes 5-6.

### 4. Sous-clé du serveur

Laptop :
```sh
gpg --armor --export-secret-subkeys "$S_SRV!" > $d/srv.asc
scp $d/srv.asc <serveur>:/dev/shm/ && shred -u $d/srv.asc
```
Serveur (interactif : pinentry-curses) :
```sh
gpg --delete-secret-keys $KEY                  # retire la clé complète actuelle (la publique reste)
gpg --delete-secret-and-public-keys 51E3B3D5D5A398B6F2090D295A2CFC5C90EDA4A0   # clé de test
gpg --import /dev/shm/srv.asc && shred -u /dev/shm/srv.asc
gpg --passwd $KEY                              # passphrase propre au serveur
echo "$KEY:6:" | gpg --import-ownertrust
gpg -K                                          # attendu : sec# (absente), ssb seulement pour S_SRV
```

### 5. YubiKey (laptop)

```sh
ykman openpgp reset  # applet OpenPGP seul (l'OTP du LUKS n'est pas touché) ; PIN 123456 / 12345678
gpg --card-edit      # admin → passwd : changer PIN (123456) et Admin PIN (12345678)
                     # admin → key-attr : RSA 4096 (sig), RSA 4096 (enc), ECC Curve 25519 (auth)
                     # admin → forcesig (passe à « not forced »)
ykman openpgp keys set-touch sig off; ykman openpgp keys set-touch dec off
ykman openpgp keys set-touch aut off
gpg --edit-key $KEY  # key N (S_LAPTOP) → keytocard → 1 ; key N (désélection)
                     # key M (E) → keytocard → 2 ; key M
                     # key P (A) → keytocard → 3 ; save
```

### 6. Retirer S_SRV du laptop

```sh
gpg -K --with-keygrip                                   # keygrip de S_SRV
gpg-connect-agent "DELETE_KEY --force <keygrip>" /bye
gpg -K                                                  # attendu : sec, ssb> (carte), ssb# (S_SRV)
```
La clé maîtresse reste sur le laptop pour l'instant. Pour la passer hors ligne plus tard : même
`DELETE_KEY` sur son keygrip, et le renouvellement de l'étape 11 se fait depuis KeePassXC.

### 7. Publier la clé publique

`gpg --send-keys $KEY` (keyserver du bureau, dans `gpg.conf`), puis remplacer la clé publique
(`gpg --armor --export $KEY`) dans le profil CDS et dans Stash.
People (partage des clés entre collègues) refuse les clés ed25519 : lui donner un export sans la
sous-clé A, inutile aux autres (`gpg --armor --export-filter drop-subkey='usage =~ a' --export $KEY`).

### 8. host.config (chaque machine boulot)

`~/.config/git/host.config` :
```ini
[user]
    signingkey = <S_LAPTOP ou S_SRV>!
```
Retirer un éventuel `user.email` (désormais versionné). Après un reboot du serveur, avant de
relancer les agents : `echo test | gpg --clearsign >/dev/null` et une connexion SSH vers Stash,
pour remettre les passphrases en cache.

### 9. SSH

- Laptop : ancienne clé renommée en `id_ed25519.old`, puis `gpg --export-ssh-key "$A!" >
  ~/.ssh/id_ed25519.pub` (même nom partout : `perso.config` reste commun) ; déclarer cette clé sur
  People, Stash, GitHub/Codeberg (auth + signature). gpg-agent la sert d'office (clé de carte).
- Serveur : nouvelle clé ed25519 propre, à la place de l'`id_ed25519` commune (gardée en `.old`
  jusqu'à l'étape 11 ; sa copie dans gpg-agent assure la transition) :
  ```sh
  mv ~/.ssh/id_ed25519 ~/.ssh/id_ed25519.old; mv ~/.ssh/id_ed25519.pub ~/.ssh/id_ed25519.old.pub
  ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -C gaugendr@serveur-boulot   # avec passphrase
  ```
  À déclarer sur People, Stash et GitHub/Codeberg (auth + signature) ; `sshcontrol` : retirer
  l'entrée orpheline.
- Ajouter les deux dans `dot_config/git/allowed_signers`.

### 10. Tests

- Laptop et serveur, dépôt boulot : commit, `git log -1 --format='%G? %GK'` → `G` et la bonne
  sous-clé ; pipeline CDS accepté.
- Serveur : laptop déconnecté, un agent committe et pousse ; puis reboot + procédure de l'étape 8.
- Dépôt perso depuis chaque machine : `%G?` = `G`, « Verified » sur GitHub et Codeberg.
- Chiffrement : `echo ok | gpg -e -r $KEY | gpg -d` sur le laptop.

### 11. Ménage (quelques semaines après)

Retirer l'ancienne `id_ed25519` commune (fichiers et `sshcontrol` des deux machines, Stash, forges)
et la clé RSA `gaugendre@bw` (`sshcontrol` et `private-keys-v1.d` du laptop, là où elle est déclarée) ; rappel calendrier dans
~22 mois pour prolonger l'expiration :
```sh
export GNUPGHOME=$(mktemp -d -p $XDG_RUNTIME_DIR)
gpg --import boulot-2ans.asc       # depuis KeePassXC
gpg --quick-set-expire $KEY 2y; gpg --quick-set-expire $KEY 2y '*'
gpg --armor --export $KEY > pub.asc; rm -rf $GNUPGHOME; unset GNUPGHOME
gpg --import pub.asc               # puis étape 7
```
