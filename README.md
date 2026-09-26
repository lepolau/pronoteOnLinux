Voici un petit script multi-distributions qui installe le Client Pronote 2026 2.7. 
Attention, si vous avez déjà Wine sur votre machine mais que c'est une version inférieure à la 11, le script la mettra à jour automatiquement.

Utilisation : 
- Dans votre terminal, placez-vous dans le dossier contenant le fichier. 
- Tapez "sudo bash install_pronote_wine-0.4.sh".
- Ensuite installez Mono si il vous le demande, et le Client Pronote de préférence dans le répertoire par défaut.
- A la fin, quand le script aura terminer, il vous suffit de taper :
  sudo wine "/root/.pronote/drive_c/Program Files/Index Education/Pronote 2026/Réseau/Client/Client PRONOTE.exe" si votre utilisateur est dans sudoers.

Le script est testé sous plusieurs distrib sur un serveur de démonstration (trombinoscope, appel, notes, bulletin...) et le Client fonctionne exactement comme sous Windows

- Linux Mint 22.3 Cinnamon :
<img width="1680" height="1050" alt="Mint 22 3 - Script 0 4" src="https://github.com/user-attachments/assets/a98dce05-20a2-4ce8-8437-32298658772f" />
<img width="1680" height="1050" alt="login mint" src="https://github.com/user-attachments/assets/08ef4e8d-7534-4a3f-9ab5-cd649ea53472" />
<img width="1680" height="1050" alt="Notes Mint" src="https://github.com/user-attachments/assets/b2702a8f-bec8-4f89-87f8-71a728061f8e" />
<img width="1680" height="1050" alt="Trombinoscope Mint" src="https://github.com/user-attachments/assets/96a5071f-f7ea-4ba2-ac09-a5fa38aaf679" />

- Fedora Linux 44 :
<img width="1680" height="1050" alt="fedora install" src="https://github.com/user-attachments/assets/491be48f-8bae-4680-97b4-9b5e5397c2c4" />
<img width="1680" height="1050" alt="appel fedora" src="https://github.com/user-attachments/assets/a0b4a4b3-effc-4368-9e06-3e028aaf1045" />

- Ubuntu 24.04.4 : 
<img width="1366" height="768" alt="Capture d’écran du 2026-09-26 16-15-51" src="https://github.com/user-attachments/assets/72795b5e-e0c0-4c99-8817-b754b63937f5" />


- ArchLinux en KDE Plasma et Gnome : 
<img width="1680" height="1050" alt="Capture d&#39;écran_20260926_142942" src="https://github.com/user-attachments/assets/d87624d8-0b35-4781-9690-4b23cb8dd14a" />

