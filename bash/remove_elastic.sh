#!/bin/bash

# Vérifier si le script est exécuté avec les droits root
if [ "$EUID" -ne 0 ]; then
  echo "Veuillez exécuter ce script avec les droits root (sudo)." >&2
  exit 1
fi

echo "Arrêt du service Elasticsearch..."
systemctl stop elasticsearch

echo "Désinstallation d'Elasticsearch..."
if command -v apt >/dev/null 2>&1; then
  # Pour Ubuntu/Debian
  apt remove --purge -y elasticsearch
elif command -v yum >/dev/null 2>&1; then
  # Pour Red Hat/CentOS
  yum remove -y elasticsearch
else
  echo "Gestionnaire de paquets non reconnu. Veuillez supprimer Elasticsearch manuellement." >&2
  exit 1
fi

echo "Suppression des fichiers résiduels..."
rm -rf /var/lib/elasticsearch/ # Données
rm -rf /var/log/elasticsearch/ # Logs
rm -rf /etc/elasticsearch/     # Configuration
rm -rf /usr/share/elasticsearch # Fichiers d'installation (si installé manuellement)

echo "Elasticsearch a été complètement désinstallé."
