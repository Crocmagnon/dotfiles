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
pub  rsa4096 [C]   clé maîtresse : hors ligne, dans le KeePassXC du bureau ; expire à 2 ans
sub  rsa4096 [E]   chiffrement : YubiKey (sauvegardée avant keytocard)
sub  rsa4096 [S]   signature laptop : YubiKey
sub  rsa4096 [S]   signature serveur : logicielle, sur le serveur uniquement
sub  ed25519 [A]   SSH du laptop : YubiKey
```

- Le serveur signe seul (agents actifs laptop déconnecté) : d'où sa sous-clé logicielle, protégée
  par une passphrase propre au serveur, saisie après chaque reboot (cache gpg-agent de 400 jours
  en headless). Le serveur garde sa propre clé SSH ed25519, logicielle.
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
- [ ] Étapes 0 à 11 ci-dessous.

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
contenant quoi (keytocard les écrase) ; capacités et expiration de la clé actuelle ; `Linger=yes`
sur le serveur (sinon `loginctl enable-linger`, à lancer par Gabriel : sans lui, gpg-agent et son
cache meurent à la dernière déconnexion).

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
scp $d/srv.asc <serveur>:/run/user/<uid>/ && shred -u $d/srv.asc
```
Serveur (interactif : pinentry-curses) :
```sh
gpg --import /run/user/$(id -u)/srv.asc && shred -u /run/user/$(id -u)/srv.asc
gpg --passwd $KEY                              # passphrase propre au serveur
echo "$KEY:6:" | gpg --import-ownertrust
gpg -K                                          # attendu : sec# (absente), ssb seulement pour S_SRV
```

### 5. YubiKey (laptop)

```sh
gpg --card-edit      # admin → passwd : changer PIN (123456) et Admin PIN (12345678)
                     # admin → key-attr : RSA 4096 (sig), RSA 4096 (enc), ECC Curve 25519 (auth)
ykman openpgp keys set-touch sig off; ykman openpgp keys set-touch dec off
ykman openpgp keys set-touch aut off
gpg --edit-key $KEY  # key N (S_LAPTOP) → keytocard → 1 ; key N (désélection)
                     # key M (E) → keytocard → 2 ; key M
                     # key P (A) → keytocard → 3 ; save
```

### 6. Retirer la clé maîtresse et S_SRV du laptop

```sh
gpg -K --with-keygrip                                   # keygrips de la maîtresse et de S_SRV
gpg-connect-agent "DELETE_KEY --force <keygrip>" /bye   # une fois par keygrip
gpg -K                                                  # attendu : sec#, ssb> (carte), ssb# (S_SRV)
```

### 7. Publier la clé publique

`gpg --send-keys $KEY` (keyserver du bureau, dans `gpg.conf`), puis remplacer la clé publique
(`gpg --armor --export $KEY`) dans le profil CDS et dans Stash.

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

- Laptop : `gpg --export-ssh-key "$A!" > ~/.ssh/id_yubikey.pub` ; déclarer cette clé sur Stash,
  et sur GitHub/Codeberg (auth + signature). gpg-agent la sert d'office (clé de carte). Rendre
  `perso.config` template pour pointer `user.signingkey` sur `~/.ssh/id_yubikey.pub` sur le laptop
  boulot (`work` et pas `headless`).
- Serveur : sa clé ed25519 actuelle, à déclarer sur GitHub/Codeberg comme clé de signature.
- Ajouter les deux dans `dot_config/git/allowed_signers`.

### 10. Tests

- Laptop et serveur, dépôt boulot : commit, `git log -1 --format='%G? %GK'` → `G` et la bonne
  sous-clé ; pipeline CDS accepté.
- Serveur : laptop déconnecté, un agent committe et pousse ; puis reboot + procédure de l'étape 8.
- Dépôt perso depuis chaque machine : `%G?` = `G`, « Verified » sur GitHub et Codeberg.
- Chiffrement : `echo ok | gpg -e -r $KEY | gpg -d` sur le laptop.

### 11. Ménage (quelques semaines après)

Retirer l'ancienne clé SSH logicielle du laptop de Stash et des forges ; rappel calendrier dans
~22 mois pour prolonger l'expiration :
```sh
export GNUPGHOME=$(mktemp -d -p $XDG_RUNTIME_DIR)
gpg --import boulot-2ans.asc       # depuis KeePassXC
gpg --quick-set-expire $KEY 2y; gpg --quick-set-expire $KEY 2y '*'
gpg --armor --export $KEY > pub.asc; rm -rf $GNUPGHOME; unset GNUPGHOME
gpg --import pub.asc               # puis étape 7
```
