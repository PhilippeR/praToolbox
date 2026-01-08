  GNU nano 7.2                                        remove_kibana.sh                                                  #!/bin/bash

# Vérifier si le script est exécuté avec les droits root
if [ "$EUID" -ne 0 ]; then
  echo "Veuillez exécuter ce script avec les droits root (sudo)." >&2
  exit 1
fi

echo "Arrêt du service Kibana..."
systemctl stop kibana

echo "Désinstallation de Kibana..."
if command -v apt >/dev/null 2>&1; then
  # Pour Ubuntu/Debian
  apt remove --purge -y kibana
elif command -v yum >/dev/null 2>&1; then
  # Pour Red Hat/CentOS
  yum remove -y kibana
else
  echo "Gestionnaire de paquets non reconnu. Veuillez supprimer Kibana manuellement." >&2
  exit 1
fi

echo "Suppression des fichiers résiduels..."
rm -rf /var/log/kibana/  # Logs
rm -rf /etc/kibana/      # Configuration
rm -rf /var/lib/kibana/  # Cache/Temp
rm -rf /usr/share/kibana # Fichiers d'installation (si installé manuellement)

echo "Kibana a été complètement désinstallé."
echo "Si nécessaire, vous pouvez maintenant réinstaller Kibana."
