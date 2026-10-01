# 🎓 Client Pronote 2026 sous Linux (via Wine)

Un script d'installation **multi-distributions** permettant d'installer le **Client Pronote 2026 (v2.7)** sur Linux grâce à Wine.

---

## ⚠️ Attention

Si Wine est déjà installé sur votre machine et que votre distribution est basée sur Ubuntu avec une version **inférieure à la Wine 11**, le script mettra automatiquement Wine à jour.

---

## Installation

1. Ouvrez un terminal et placez-vous dans le dossier contenant le script.
2. Lancez l'installation :

   ```bash
   bash install_pronote_wine-0.6.sh
   ```

3. Si le script vous le demande, installez **Mono**.
4. Installez le **Client Pronote** de préférence dans le répertoire par défaut proposé.

---

## Lancer le Client Pronote

Une fois l'installation terminée, lancez le client avec la commande suivante :

```bash
~/.local/bin/pronote 
```

---

## Compatibilité

Le script a été testé sur plusieurs distributions, sur un serveur de démonstration (trombinoscope, appel, notes, bulletin, etc.), et le client fonctionne **exactement comme sous Windows**.

### 🟢 Linux Mint 22.3 Cinnamon

<p align="center">
  <img width="1680" height="1050" alt="Installation Mint 22.3 - Script 0.4" src="https://github.com/user-attachments/assets/a98dce05-20a2-4ce8-8437-32298658772f" />
  <img width="1680" height="1050" alt="Écran de connexion sous Mint" src="https://github.com/user-attachments/assets/08ef4e8d-7534-4a3f-9ab5-cd649ea53472" />
  <img width="1680" height="1050" alt="Notes sous Mint" src="https://github.com/user-attachments/assets/b2702a8f-bec8-4f89-87f8-71a728061f8e" />
  <img width="1680" height="1050" alt="Trombinoscope sous Mint" src="https://github.com/user-attachments/assets/96a5071f-f7ea-4ba2-ac09-a5fa38aaf679" />
</p>

### 🔵 Fedora Linux 44

<p align="center">
  <img width="1680" height="1050" alt="Installation sous Fedora" src="https://github.com/user-attachments/assets/491be48f-8bae-4680-97b4-9b5e5397c2c4" />
  <img width="1680" height="1050" alt="Appel sous Fedora" src="https://github.com/user-attachments/assets/a0b4a4b3-effc-4368-9e06-3e028aaf1045" />
</p>

### 🟠 Ubuntu 24.04.4

<p align="center">
  <img width="1366" height="768" alt="Capture d'écran sous Ubuntu" src="https://github.com/user-attachments/assets/72795b5e-e0c0-4c99-8817-b754b63937f5" />
</p>

### 🟣 Arch Linux (KDE Plasma & GNOME)

<p align="center">
  <img width="1680" height="1050" alt="Capture d'écran sous Arch Linux" src="https://github.com/user-attachments/assets/d87624d8-0b35-4781-9690-4b23cb8dd14a" />
</p>

---

## 📄 Licence
GNU General Public License v3.0
- Laurent le Poittevin
- Bertrand BELFORT, élève de 1G au LPO Blaise Pascal de Châteauroux
