#!/usr/bin/env bash
#
# install_pronote_wine.sh
# Automatise l'installation du client PRONOTE (PRNclient) sous Linux via Wine.
# le poittevin laurent licence CCbySA avec l'aide de Claude AI
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
DEPENDENCY_PACKAGES="wine wget curl cabextract unzip"
 
# PRONOTE nécessite Wine 10 minimum. Les paquets "wine" des dépôts standards
# de certaines distributions (ex. Linux Mint 22, Ubuntu 24.04 "noble") ne
# fournissent encore que Wine 9, insuffisant.
WINE_MIN_MAJOR_VERSION=10
 
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
 
# Renvoie le nom de code Ubuntu sur lequel repose la distribution.
# Linux Mint 22 comme Ubuntu 24.04 exposent UBUNTU_CODENAME="noble" dans
# /etc/os-release, ce qui permet de les traiter de façon identique.
detect_ubuntu_codename() {
    [ -f /etc/os-release ] || { echo ""; return; }
 
    # shellcheck disable=SC1091
    . /etc/os-release
 
    echo "${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}"
}
 
# Renvoie le numéro de version majeure de Wine installé (ex. "9", "10"),
# ou une chaîne vide si Wine n'est pas installé.
get_wine_major_version() {
    command -v wine &>/dev/null || { echo ""; return; }
    wine --version 2>/dev/null | grep -oE '[0-9]+' | head -n1
}
 
# Ajoute le dépôt officiel WineHQ pour Ubuntu 24.04 "noble" et installe
# winehq-staging (couvre Ubuntu Noble et Linux Mint 22, basé dessus).
install_winehq_noble() {
    log "Ajout du dépôt WineHQ (noble) pour obtenir Wine ${WINE_MIN_MAJOR_VERSION}+..."
 
    sudo dpkg --add-architecture i386
    sudo mkdir -pm755 /etc/apt/keyrings
    wget -O - https://dl.winehq.org/wine-builds/winehq.key \
        | sudo gpg --dearmor -o /etc/apt/keyrings/winehq-archive.key -
    sudo wget -NP /etc/apt/sources.list.d/ \
        https://dl.winehq.org/wine-builds/ubuntu/dists/noble/winehq-noble.sources
    sudo apt-get update
    sudo apt-get install --install-recommends -y winehq-staging
}
 
# Vérifie que la version de Wine installée satisfait le minimum requis par
# PRONOTE. Tente une mise à niveau via WineHQ sur les distributions basées
# sur Ubuntu Noble (Ubuntu 24.04, Linux Mint 22) ; échoue proprement sinon.
ensure_wine_version() {
    local current
    current=$(get_wine_major_version)
    log "Version de Wine détectée : ${current:-non installée}"
 
    if [ -n "${current}" ] && [ "${current}" -ge "${WINE_MIN_MAJOR_VERSION}" ]; then
        return 0
    fi
 
    log "PRONOTE nécessite Wine ${WINE_MIN_MAJOR_VERSION} minimum (version actuelle : ${current:-aucune})."
 
    local codename
    codename=$(detect_ubuntu_codename)
 
    if [ "${codename}" = "noble" ]; then
        log "Distribution basée sur Ubuntu Noble détectée (Ubuntu 24.04 / Linux Mint 22) : mise à niveau via WineHQ..."
        install_winehq_noble
 
        current=$(get_wine_major_version)
        if [ -z "${current}" ] || [ "${current}" -lt "${WINE_MIN_MAJOR_VERSION}" ]; then
            err "Wine ${WINE_MIN_MAJOR_VERSION}+ toujours indisponible après l'installation via WineHQ."
            err "Vérifie manuellement : https://dl.winehq.org/wine-builds/ubuntu/"
            exit 1
        fi
        log "Wine ${current} installé avec succès via WineHQ."
    else
        err "Wine ${WINE_MIN_MAJOR_VERSION}+ n'est pas disponible pour cette distribution via ce script (version actuelle : ${current:-aucune})."
        err "Aucune procédure de mise à niveau automatique n'est prévue en dehors d'Ubuntu 24.04 / Linux Mint 22."
        err "Installe manuellement Wine ${WINE_MIN_MAJOR_VERSION}+ (voir https://dl.winehq.org/wine-builds/) puis relance ce script."
        exit 1
    fi
}
 
install_dependencies() {
    local family
    family=$(detect_distro_family)
 
    log "Distribution détectée : ${family}"
 
    case "${family}" in
        debian)
            log "Installation des dépendances via apt..."
            sudo apt-get update
            sudo apt-get install -y ${DEPENDENCY_PACKAGES}
            ;;
        fedora)
            log "Installation des dépendances via dnf..."
            sudo dnf install -y ${DEPENDENCY_PACKAGES}
            ;;
        opensuse)
            log "Installation des dépendances via zypper..."
            sudo zypper --non-interactive install ${DEPENDENCY_PACKAGES}
            ;;
        mageia)
            log "Installation des dépendances via urpmi..."
            sudo urpmi --auto ${DEPENDENCY_PACKAGES}
            ;;
        arch)
            log "Installation des dépendances via pacman..."
            log "Note : le dépôt 'multilib' doit être activé dans /etc/pacman.conf pour Wine sur un système 64 bits."
            sudo pacman -Sy --needed --noconfirm ${DEPENDENCY_PACKAGES}
            ;;
        *)
            err "Distribution non reconnue automatiquement."
            err "Installe manuellement ces paquets avant de relancer : ${DEPENDENCY_PACKAGES}"
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
# Vérification de la version de Wine (PRONOTE nécessite Wine 10 minimum)
# ---------------------------------------------------------------------------
ensure_wine_version
 
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
echo "    WINEPREFIX=\"${WINEPREFIX}\" wine \"${WINEPREFIX}/drive_c/Program Files/Index Education/PRONOTE.net Client/PRNclient.exe\""
