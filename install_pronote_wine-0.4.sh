#!/usr/bin/env bash
#
# install_pronote_wine.sh
# Automatise l'installation du client PRONOTE (PRNclient) sous Linux via Wine.
# le poittevin laurent licence CCbySA avec l'aide de Claude AI
# script modifié par Bertrand BELFORT le 23/09/2026 - licence CCbySA avec l'aide de ChatGPT
#
# Comportement :
#  - Le script vérifie et met à jour Wine à chaque exécution (que PRONOTE
#    soit déjà installé ou non) : si la version présente est trop ancienne
#    (ex : Wine 9.0 fourni par la distribution), elle est remplacée
#    automatiquement par WineHQ Stable.
#  - Si PRONOTE n'est pas encore installé, il est installé pour la première
#    fois (préparation du préfixe Wine avec winetricks incluse).
#  - Si PRONOTE est déjà installé et que la dernière version disponible est
#    déjà celle installée, le script ne retélécharge/réinstalle rien : il
#    passe directement à la fin du script, comme une installation classique
#    terminée avec succès.
#  - Si PRONOTE est déjà installé mais qu'une nouvelle version est
#    disponible, elle est téléchargée et installée par-dessus.
# pour être utilisé, rendre le fichier utilisable :
#   chmod +x install_pronote_wine.sh
# puis démarrez le dans une console :
#   ./install_pronote_wine.sh
#
set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
PRONOTE_DOWNLOAD_PAGE="https://www.index-education.com/fr/telecharger-pronote.php"

WINEPREFIX_DIR="${HOME}/.pronote"
WINETRICKS_URL="https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks"

# ---------------------------------------------------------------------------
# Fonctions utilitaires
# ---------------------------------------------------------------------------
log()  { echo -e "\033[1;34m[INFO]\033[0m $*"; }
err()  { echo -e "\033[1;31m[ERREUR]\033[0m $*" >&2; }

check_dependency() {
    if ! command -v "$1" &>/dev/null; then
        return 1
    fi
    return 0
}

# ---------------------------------------------------------------------------
# Détection de la distribution et installation des dépendances système
# ---------------------------------------------------------------------------
# Paquets nécessaires : wine, wget, curl, cabextract et unzip (requis par
# certains verbes winetricks comme corefonts / win10).
DEPENDENCY_PACKAGES="wget curl cabextract unzip"

# Version majeure minimale de Wine souhaitée (fournie par WineHQ Stable).
# Si la version installée (ex: celle des dépôts Linux Mint) est inférieure,
# le script la met à jour automatiquement.
REQUIRED_WINE_MAJOR=11

get_wine_major_version() {
    # Renvoie le numéro de version majeure de Wine (ex: "9" pour "wine-9.0"),
    # ou une chaîne vide si Wine n'est pas installé ou si la version n'a pas
    # pu être lue.
    if ! command -v wine &>/dev/null; then
        echo ""
        return
    fi

    wine --version 2>/dev/null | grep -oE '[0-9]+' | head -n1
}

detect_distro_family() {
    if [ ! -f /etc/os-release ]; then
        echo "unknown"
        return
    fi

    # shellcheck disable=SC1091
    . /etc/os-release

    local id="${ID:-}"
    local id_like="${ID_LIKE:-}"

    case "${id} ${id_like}" in
        *debian*|*ubuntu*)
            echo "debian" ;;
        *fedora*|*rhel*)
            echo "fedora" ;;
        *opensuse*|*suse*)
            echo "opensuse" ;;
        *mageia*|*mandriva*)
            echo "mageia" ;;
        *arch*)
            echo "arch" ;;
        *)
            echo "unknown" ;;
    esac
}

install_wine_11_ubuntu() {
    log "Installation de Wine 11 depuis le dépôt officiel WineHQ..."

    # Activation de l'architecture 32 bits nécessaire à Wine
    log "Activation de l'architecture i386..."
    sudo dpkg --add-architecture i386

    # Installation des outils nécessaires
    log "Installation des prérequis..."
    sudo apt-get update
    sudo apt-get install -y wget ca-certificates

    # Clé officielle WineHQ
    log "Installation de la clé du dépôt WineHQ..."
    sudo mkdir -pm755 /etc/apt/keyrings
    sudo wget -O /etc/apt/keyrings/winehq-archive.key \
        https://dl.winehq.org/wine-builds/winehq.key

    # Détection du nom de code Ubuntu attendu par le dépôt WineHQ
    # (ex: "noble" pour Ubuntu 24.04).
    . /etc/os-release

    # Sur Ubuntu, VERSION_CODENAME donne directement le bon nom de code.
    # Sur les dérivées d'Ubuntu (Linux Mint, Pop!_OS, Zorin, elementary...),
    # VERSION_CODENAME contient le nom de code DE LA DÉRIVÉE (ex: "xia" pour
    # Mint), ce qui est invalide pour le dépôt WineHQ : il faut utiliser
    # UBUNTU_CODENAME, exposée par ces distributions dans /etc/os-release
    # pour justement indiquer la base Ubuntu réelle.
    local codename="${UBUNTU_CODENAME:-}"

    if [ -z "${codename}" ] && [ "${ID:-}" = "ubuntu" ]; then
        codename="${VERSION_CODENAME:-}"
    fi

    if [ -z "${codename}" ]; then
        err "Impossible de déterminer le nom de code Ubuntu correspondant."
        err "Distribution détectée : ${ID:-inconnue} (ID_LIKE=${ID_LIKE:-})"
        err "Ni UBUNTU_CODENAME ni VERSION_CODENAME exploitable n'ont été trouvés dans /etc/os-release."
        exit 1
    fi

    log "Nom de code Ubuntu utilisé pour le dépôt WineHQ : ${codename}"

    # Dépôt officiel WineHQ correspondant à Ubuntu
    log "Ajout du dépôt WineHQ pour ${codename}..."
    sudo wget -NP /etc/apt/sources.list.d/ \
        "https://dl.winehq.org/wine-builds/ubuntu/dists/${codename}/winehq-${codename}.sources"

    # Si une version de Wine fournie par la distribution est déjà installée
    # (paquet "wine" natif, comme le Wine 9.0 des dépôts Linux Mint), on la
    # retire avant d'installer winehq-stable afin d'éviter tout conflit de
    # paquets et de garantir une mise à jour propre.
    if dpkg -s wine &>/dev/null 2>&1 && ! dpkg -s winehq-stable &>/dev/null 2>&1; then
        log "Une version de Wine fournie par la distribution a été détectée, suppression avant mise à jour..."
        sudo apt-get remove -y wine wine64 wine32 wine-stable wine-development libwine fonts-wine 2>/dev/null || true
        sudo apt-get autoremove -y || true
    fi

    # Mise à jour des dépôts
    log "Mise à jour des dépôts..."
    sudo apt-get update

    # Installation de WineHQ Stable
    log "Installation de WineHQ Stable..."
    sudo apt-get install -y --install-recommends winehq-stable

    # Vérification
    if ! command -v wine &>/dev/null; then
        err "Wine n'a pas été installé correctement."
        exit 1
    fi

    WINE_VERSION="$(wine --version)"
    log "Version de Wine installée : ${WINE_VERSION}"

    local wine_major
    wine_major="$(get_wine_major_version)"
    if [ -z "${wine_major}" ] || [ "${wine_major}" -lt "${REQUIRED_WINE_MAJOR}" ]; then
        err "La mise à jour n'a pas abouti à une version suffisamment récente."
        err "Version détectée : ${WINE_VERSION}"
        exit 1
    fi

    log "Wine ${wine_major} est correctement installé."
}

install_dependencies() {
    local family
    family=$(detect_distro_family)

    log "Distribution détectée : ${family}"

    case "${family}" in
        debian)
            # Si Ubuntu (ou une dérivée d'Ubuntu comme Linux Mint, Pop!_OS,
            # Zorin, elementary OS...) est utilisé, on installe Wine 11
            # depuis WineHQ. La présence de UBUNTU_CODENAME dans
            # /etc/os-release est le signal fiable pour les dérivées, car
            # ID_LIKE seul (ex: "ubuntu") ne suffit pas à savoir quel dépôt
            # WineHQ utiliser.
            if [ -f /etc/os-release ]; then
                . /etc/os-release

                if [ "${ID:-}" = "ubuntu" ] || [ -n "${UBUNTU_CODENAME:-}" ]; then
                    install_wine_11_ubuntu

                    log "Installation des autres dépendances via apt..."
                    sudo apt-get install -y ${DEPENDENCY_PACKAGES}
                else
                    log "Installation des dépendances via apt..."
                    sudo apt-get update
                    sudo apt-get install -y wine ${DEPENDENCY_PACKAGES}
                fi
            fi
            ;;
        fedora)
            log "Installation des dépendances via dnf..."
            sudo dnf install -y wine ${DEPENDENCY_PACKAGES}
            ;;
        opensuse)
            log "Installation des dépendances via zypper..."
            sudo zypper --non-interactive install wine ${DEPENDENCY_PACKAGES}
            ;;
        mageia)
            log "Installation des dépendances via urpmi..."
            sudo urpmi --auto wine ${DEPENDENCY_PACKAGES}
            ;;
        arch)
            log "Installation des dépendances via pacman..."
            log "Note : le dépôt 'multilib' doit être activé dans /etc/pacman.conf pour Wine sur un système 64 bits."
            sudo pacman -Sy --needed --noconfirm wine ${DEPENDENCY_PACKAGES}
            ;;
        *)
            err "Distribution non reconnue automatiquement."
            err "Installe manuellement ces paquets avant de relancer : wine ${DEPENDENCY_PACKAGES}"
            exit 1
            ;;
    esac
}

# ---------------------------------------------------------------------------
# Configuration de l'environnement Wine
# ---------------------------------------------------------------------------
export WINEARCH=win64
export WINEPREFIX="${WINEPREFIX_DIR}"

log "WINEARCH=${WINEARCH}"
log "WINEPREFIX=${WINEPREFIX}"

mkdir -p "${WINEPREFIX}"

VERSION_MARKER="${WINEPREFIX}/.pronote_installed_version"

# ---------------------------------------------------------------------------
# Détection d'une installation existante du Client PRONOTE
# ---------------------------------------------------------------------------
find_installed_pronote() {
    local search_dir="${WINEPREFIX}/drive_c"
    [ -d "${search_dir}" ] || return 1

    find "${search_dir}" -iname "PRNclient.exe" 2>/dev/null | head -n1
}

IS_UPDATE=false
INSTALLED_PATH=""

if INSTALLED_PATH=$(find_installed_pronote) && [ -n "${INSTALLED_PATH}" ]; then
    IS_UPDATE=true
    log "Client PRONOTE déjà installé : ${INSTALLED_PATH}"
else
    log "Aucune installation existante détectée, installation initiale."
fi

# ---------------------------------------------------------------------------
# Vérification / installation / mise à jour des prérequis
# ---------------------------------------------------------------------------
# Cette étape est systématique, que PRONOTE soit déjà installé ou non : on
# veut toujours s'assurer que Wine est présent et suffisamment récent avant
# de continuer (mise à jour automatique si une version trop ancienne, comme
# Wine 9.0 sur Linux Mint, est détectée).
log "Vérification des dépendances (wine, wget, curl, cabextract, unzip)..."

missing=0
for cmd in wine wget curl cabextract unzip; do
    if ! check_dependency "${cmd}"; then
        missing=1
        break
    fi
done

NEED_WINE_UPGRADE=false
if [ "${missing}" -eq 0 ]; then
    CURRENT_WINE_MAJOR="$(get_wine_major_version)"
    if [ -n "${CURRENT_WINE_MAJOR}" ] && [ "${CURRENT_WINE_MAJOR}" -lt "${REQUIRED_WINE_MAJOR}" ]; then
        log "Wine ${CURRENT_WINE_MAJOR}.x détecté : une version plus récente (Wine ${REQUIRED_WINE_MAJOR}+) est disponible via WineHQ."
        NEED_WINE_UPGRADE=true
    fi
fi

if [ "${missing}" -eq 1 ] || [ "${NEED_WINE_UPGRADE}" = true ]; then
    if [ "${missing}" -eq 1 ]; then
        log "Certaines dépendances sont manquantes, installation en cours (sudo requis)..."
    else
        log "Mise à jour de Wine vers une version plus récente (sudo requis)..."
    fi

    install_dependencies

    # On revérifie après installation/mise à jour
    for cmd in wine wget curl cabextract unzip; do
        if ! check_dependency "${cmd}"; then
            err "La commande '${cmd}' est toujours introuvable après installation."
            err "Installe-la manuellement puis relance ce script."
            exit 1
        fi
    done
else
    log "Toutes les dépendances sont déjà présentes et à jour."
fi

# ---------------------------------------------------------------------------
# Détection automatique de la dernière version du Client PRONOTE
# ---------------------------------------------------------------------------
detect_latest_pronote_url() {
    # On récupère la page officielle de téléchargement et on extrait le lien
    # direct vers l'installeur Windows 64 bits du Client PRONOTE.
    local page_content
    page_content=$(curl -sL "${PRONOTE_DOWNLOAD_PAGE}")

    local url
    url=$(echo "${page_content}" \
        | grep -oE 'https://tele[0-9]*\.index-education\.com/telechargement/pn/v[0-9.]+/exe/Install_PRNclient_FR_[0-9.]+_win64\.exe' \
        | head -n1)

    if [ -z "${url}" ]; then
        return 1
    fi

    echo "${url}"
}

log "Recherche de la dernière version du Client PRONOTE sur ${PRONOTE_DOWNLOAD_PAGE}..."

if PRONOTE_URL=$(detect_latest_pronote_url); then
    PRONOTE_EXE=$(basename "${PRONOTE_URL}")
    log "Version détectée : ${PRONOTE_EXE}"
else
    err "Impossible de détecter automatiquement la dernière version de PRONOTE."
    err "Vérifie manuellement l'URL sur : ${PRONOTE_DOWNLOAD_PAGE}"
    exit 1
fi

# ---------------------------------------------------------------------------
# Vérification de version / mise à jour
# ---------------------------------------------------------------------------
PRONOTE_NEEDS_INSTALL=true

if [ "${IS_UPDATE}" = true ] && [ -f "${VERSION_MARKER}" ] \
    && [ "$(cat "${VERSION_MARKER}")" = "${PRONOTE_EXE}" ]; then
    log "La version installée de PRONOTE (${PRONOTE_EXE}) est déjà la plus récente."
    PRONOTE_NEEDS_INSTALL=false
elif [ "${IS_UPDATE}" = true ]; then
    log "Nouvelle version disponible : ${PRONOTE_EXE}. Mise à jour en cours..."
fi

cd "${WINEPREFIX}"

# ---------------------------------------------------------------------------
# Récupération de winetricks et composants Windows (première installation uniquement)
# ---------------------------------------------------------------------------
if [ "${IS_UPDATE}" = false ]; then
    log "Initialisation du préfixe Wine (wineboot)..."
    wine wineboot

    if [ ! -f "winetricks" ]; then
        log "Téléchargement de winetricks..."
        wget -q --show-progress "${WINETRICKS_URL}"
        chmod +x winetricks
    else
        log "winetricks déjà présent, téléchargement ignoré."
    fi

    log "Installation de windowscodecs..."
    sh winetricks -q windowscodecs

    log "Installation de corefonts..."
    sh winetricks -q corefonts

    log "Configuration en mode Windows 10..."
    sh winetricks -q win10
else
    log "Préfixe Wine déjà configuré, étapes winetricks ignorées."
fi

# ---------------------------------------------------------------------------
# Téléchargement et installation (ou mise à jour) du client PRONOTE
# ---------------------------------------------------------------------------
if [ "${PRONOTE_NEEDS_INSTALL}" = true ]; then
    if [ ! -f "${PRONOTE_EXE}" ]; then
        log "Téléchargement du client PRONOTE (${PRONOTE_EXE})..."
        wget -q --show-progress "${PRONOTE_URL}" -O "${PRONOTE_EXE}"
    else
        log "Installeur PRONOTE déjà présent, téléchargement ignoré."
    fi

    if [ "${IS_UPDATE}" = true ]; then
        log "Installation de la mise à jour par-dessus la version existante (${INSTALLED_PATH})..."
    else
        log "Lancement de l'installation du client PRONOTE..."
    fi

    wine "${PRONOTE_EXE}"

    # On mémorise la version installée pour éviter une réinstallation inutile
    # au prochain lancement du script.
    echo "${PRONOTE_EXE}" > "${VERSION_MARKER}"

    if [ "${IS_UPDATE}" = true ]; then
        log "Mise à jour terminée ! Client PRONOTE mis à jour vers ${PRONOTE_EXE}."
    else
        log "Installation terminée ! Le préfixe Wine se trouve dans : ${WINEPREFIX}"
    fi
else
    log "Rien à installer : Wine est à jour et PRONOTE est déjà dans sa dernière version."
fi

log "Tu peux relancer PRONOTE plus tard avec :"
echo "    WINEPREFIX=\"${WINEPREFIX}\" wine \"${WINEPREFIX}/drive_c/Program Files/Index Education/Réseau/Client/Client Pronote.exe\""

echo ""
echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║                 Merci d'avoir utilisé notre script !                 ║"
echo "║                 Voici quelques informations utiles :                 ║"
echo "╠══════════════════════════════════════════════════════════════════════╣"
echo "║ Ce script a été réalisé par :                                       ║"
echo "║                                                                      ║"
echo "║   • Laurent Le Poittevin                                            ║"
echo "║   • Bertrand BELFORT, élève de 1G au LPO Blaise Pascal de           ║"
echo "║     Châteauroux                                                     ║"
echo "║                                                                      ║"
echo "║ Si votre utilisateur fait partie de sudoers (super-admin),          ║"
echo "║ vous pouvez lancer PRONOTE avec la commande suivante :               ║"
echo "║                                                                      ║"
echo "║ sudo wine \"/root/.pronote/drive_c/Program Files/Index Education/    ║"
echo "║ Pronote 2026/Réseau/Client/Client Pronote.exe\"                      ║"
echo "║                                                                      ║"
echo "║ Cette commande est valable si PRONOTE a été installé dans le        ║"
echo "║ répertoire par défaut.                                               ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"
