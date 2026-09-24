Pour les utilisateurs de Linux Mint, vous devez installer la version 10 de Wine en lieu et place de la 9
la procédure :
Linux Mint 22.x étant  basé sur Noble.

    sudo mkdir -pm755 /etc/apt/keyrings

    wget -O - https://dl.winehq.org/wine-builds/winehq.key | sudo gpg --dearmor -o /etc/apt/keyrings/winehq-archive.key -

    sudo wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/noble/winehq-noble.sources

    sudo apt install --install-recommends winehq-staging

    rédémarrer wine (wineserver -k ou wineboot ou wincfg dans un terminal) et / ou refaire une instalaltion complète avec le script


    Je modifierais le scrip d'ici peu pour incorporer ce besoin spécifique.
