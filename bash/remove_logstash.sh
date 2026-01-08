#!/bin/bash

# Vérifier si le script est exécuté avec les droits root
if [ "$EUID" -ne 0 ]; then
  echo "Veuillez exécuter ce script avec les droits root (sudo)." >&2
  exit 1
fi

echo "Arrêt du service Logstash..."
systemctl stop logstash

echo "Désinstallation de Logstash..."
if command -v apt >/dev/null 2>&1; then
  # Pour Ubuntu/Debian
  apt remove --purge -y logstash
elif command -v yum >/dev/null 2>&1; then
  # Pour Red Hat/CentOS
  yum remove -y logstash
else
  echo "Gestionnaire de paquets non reconnu. Veuillez supprimer Logstash manuellement." >&2
  exit 1
fi

echo "Suppression des fichiers résiduels..."
rm -rf /var/lib/logstash/ # Données
rm -rf /var/log/logstash/ # Logs
rm -rf /etc/logstash/     # Configuration
rm -rf /usr/share/logstash # Fichiers d'installation (si installé manuellement)

echo "Logstash a été complètement désinstallé."
