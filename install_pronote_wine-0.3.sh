#!/usr/bin/env bash
#
# install_pronote_wine.sh
# Automatise l'installation du client PRONOTE (PRNclient) sous Linux via Wine.
# le poittevin laurent licence CCbySA avec l'aide de Claude AI
# script modifié par Bertrand BELFORT le 23/09/2026 - licence CCbySA avec l'aide de ChatGPT
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

    # Détection de la version Ubuntu
    # WineHQ utilise notamment "noble" pour Ubuntu 24.04.
    . /etc/os-release

    if [ "${ID:-}" != "ubuntu" ]; then
        err "Cette fonction d'installation de Wine 11 est prévue pour Ubuntu."
        err "Distribution détectée : ${ID:-inconnue}"
        exit 1
    fi

    UBUNTU_CODENAME="${VERSION_CODENAME:-}"

    if [ -z "${UBUNTU_CODENAME}" ]; then
        err "Impossible de déterminer le nom de code Ubuntu."
        exit 1
    fi

    log "Version Ubuntu détectée : ${UBUNTU_CODENAME}"

    # Dépôt officiel WineHQ correspondant à Ubuntu
    log "Ajout du dépôt WineHQ pour ${UBUNTU_CODENAME}..."
    sudo wget -NP /etc/apt/sources.list.d/ \
        "https://dl.winehq.org/wine-builds/ubuntu/dists/${UBUNTU_CODENAME}/winehq-${UBUNTU_CODENAME}.sources"

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

    if [[ "${WINE_VERSION}" != wine-11.* ]]; then
        err "La version installée n'est pas Wine 11."
        err "Version détectée : ${WINE_VERSION}"
        exit 1
    fi

    log "Wine 11 est correctement installé."
}

install_dependencies() {
    local family
    family=$(detect_distro_family)

    log "Distribution détectée : ${family}"

    case "${family}" in
        debian)
            # Si Ubuntu est utilisé, on installe Wine 11 depuis WineHQ.
            if [ -f /etc/os-release ]; then
                . /etc/os-release

                if [ "${ID:-}" = "ubuntu" ]; then
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
# Vérification / installation des prérequis
# ---------------------------------------------------------------------------
log "Vérification des dépendances (wine, wget, curl, cabextract, unzip)..."

missing=0

for cmd in wine wget curl cabextract unzip; do
    if ! check_dependency "${cmd}"; then
        missing=1
        break
    fi
done

if [ "${missing}" -eq 1 ]; then
    log "Certaines dépendances sont manquantes, installation en cours (sudo requis)..."
    install_dependencies

    # On revérifie après installation
    for cmd in wine wget curl cabextract unzip; do
        if ! check_dependency "${cmd}"; then
            err "La commande '${cmd}' est toujours introuvable après installation."
            err "Installe-la manuellement puis relance ce script."
            exit 1
        fi
    done
else
    log "Toutes les dépendances sont déjà présentes."
fi

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
if [ "${IS_UPDATE}" = true ] && [ -f "${VERSION_MARKER}" ] \
    && [ "$(cat "${VERSION_MARKER}")" = "${PRONOTE_EXE}" ]; then
    log "La version installée (${PRONOTE_EXE}) est déjà la plus récente. Rien à faire."
    log "Pour forcer une réinstallation, supprime : ${VERSION_MARKER}"
    exit 0
fi

if [ "${IS_UPDATE}" = true ]; then
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

log "Tu peux relancer PRONOTE plus tard avec :"
echo "    WINEPREFIX=\"${WINEPREFIX}\" wine \"${WINEPREFIX}/drive_c/Program Files/Index Education/Réseau/Client/Client Pronote.exe\""

echo ""
echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║                         INFORMATIONS                                 ║"
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
