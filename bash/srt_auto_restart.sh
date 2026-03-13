#!/bin/bash

# =============================================================================
# SRT Stream - FFmpeg auto-restart script (listener & caller)
# Génère un flux SRT avec relance automatique et journalisation des événements
# =============================================================================

# =============================================================================
# --- CONFIGURATION UTILISATEUR ---
# =============================================================================

# Mode SRT : "listener" (attend une connexion) ou "caller" (se connecte à une cible)
SRT_MODE="listener"

# Port SRT (listener : port d'écoute local / caller : port de destination)
SRT_PORT=3310

# Adresse de destination - utilisée UNIQUEMENT en mode caller
# Ex: "192.168.1.100" ou "mon-serveur.example.com"
SRT_HOST="192.168.1.100"

# Options SRT supplémentaires (optionnel, séparées par &)
# Ex: "latency=200&passphrase=secret"
SRT_OPTIONS=""

# Source vidéo :
#   "" (vide)               → mire noire animée (comportement original)
#   "/chemin/fichier.mp4"   → lecture en boucle du fichier MP4
INPUT_FILE=""

# Relance automatique de ffmpeg en cas de déconnexion/arrêt
# "true" = relance automatique (défaut) / "false" = arrêt définitif
AUTO_RESTART="true"

# Délai en secondes entre chaque relance de ffmpeg (ignoré si AUTO_RESTART=false)
RESTART_DELAY=2

# Fichier de log
LOG_FILE="$HOME/srt_stream.log"

# Chemin vers ffmpeg
FFMPEG_BIN="ffmpeg"

# =============================================================================
# --- FIN DE LA CONFIGURATION UTILISATEUR ---
# =============================================================================

# --- Variables internes ---
FFMPEG_PID=""
SCRIPT_START=$(date '+%Y-%m-%d %H:%M:%S')

# =============================================================================
# Fonctions de logging
# =============================================================================
log() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local line="[$timestamp] [$level] $message"
    echo "$line"
    echo "$line" >> "$LOG_FILE"
}

log_info()    { log "INFO   " "$1"; }
log_connect() { log "CONNECT" "$1"; }
log_disconn() { log "DISCONN" "$1"; }
log_warn()    { log "WARN   " "$1"; }
log_error()   { log "ERROR  " "$1"; }

# =============================================================================
# Gestion des signaux - arrêt propre du script
# =============================================================================
cleanup() {
    log_info "Signal d'arrêt reçu (SIGINT/SIGTERM)"
    if [[ -n "$FFMPEG_PID" ]] && kill -0 "$FFMPEG_PID" 2>/dev/null; then
        log_info "Arrêt de ffmpeg (PID=$FFMPEG_PID)"
        kill -TERM "$FFMPEG_PID" 2>/dev/null
        wait "$FFMPEG_PID" 2>/dev/null
    fi
    local stop_time
    stop_time=$(date '+%Y-%m-%d %H:%M:%S')
    log_info "============================================"
    log_info "Script arrêté à        : $stop_time"
    log_info "Démarré le             : $SCRIPT_START"
    log_info "============================================"
    exit 0
}

trap cleanup SIGINT SIGTERM

# =============================================================================
# Validation de la configuration
# =============================================================================
validate_config() {
    if [[ "$AUTO_RESTART" != "true" && "$AUTO_RESTART" != "false" ]]; then
        echo "ERREUR : AUTO_RESTART doit être 'true' ou 'false' (valeur actuelle : '$AUTO_RESTART')" >&2
        exit 1
    fi

    if [[ "$SRT_MODE" != "listener" && "$SRT_MODE" != "caller" ]]; then
        echo "ERREUR : SRT_MODE doit être 'listener' ou 'caller' (valeur actuelle : '$SRT_MODE')" >&2
        exit 1
    fi

    if [[ "$SRT_MODE" == "caller" && -z "$SRT_HOST" ]]; then
        echo "ERREUR : SRT_HOST doit être défini en mode caller" >&2
        exit 1
    fi

    if ! command -v "$FFMPEG_BIN" &>/dev/null; then
        echo "ERREUR : ffmpeg introuvable dans le PATH" >&2
        exit 1
    fi

    if [[ -n "$INPUT_FILE" ]]; then
        if [[ ! -f "$INPUT_FILE" ]]; then
            echo "ERREUR : INPUT_FILE introuvable : '$INPUT_FILE'" >&2
            exit 1
        fi
        if [[ ! -r "$INPUT_FILE" ]]; then
            echo "ERREUR : INPUT_FILE non lisible : '$INPUT_FILE'" >&2
            exit 1
        fi
    fi
}

# =============================================================================
# Construction de l'URL SRT selon le mode
# =============================================================================
build_srt_url() {
    local base_opts="mode=${SRT_MODE}"
    [[ -n "$SRT_OPTIONS" ]] && base_opts="${base_opts}&${SRT_OPTIONS}"

    if [[ "$SRT_MODE" == "listener" ]]; then
        echo "srt://0.0.0.0:${SRT_PORT}?${base_opts}"
    else
        echo "srt://${SRT_HOST}:${SRT_PORT}?${base_opts}"
    fi
}

# =============================================================================
# Construction des arguments d'entrée ffmpeg selon la source
# Stockés dans le tableau global FFMPEG_INPUT_ARGS
# =============================================================================
build_ffmpeg_input_args() {
    if [[ -n "$INPUT_FILE" ]]; then
        # Fichier MP4 : boucle infinie, lecture temps réel
        FFMPEG_INPUT_ARGS=( -stream_loop -1 -re -i "$INPUT_FILE" )
    else
        # Mire noire animée avec timecode
        FFMPEG_INPUT_ARGS=(
            -f lavfi -re -i "color=black:size=1280x720:rate=25"
            -f lavfi -i "sine=frequency=1000:sample_rate=48000:duration=0"
            -vf "drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf:\
text='%{localtime\:%Hh%Mm%Ss}\:%{eif\:mod(n\,25)\:d\:2}':\
fontsize=72:fontcolor=white:x=(w-tw)/2:y=(h-th)/2"
        )
    fi
}

# =============================================================================
# Préparation
# =============================================================================

LOG_DIR=$(dirname "$LOG_FILE")
mkdir -p "$LOG_DIR" 2>/dev/null || {
    LOG_FILE="/tmp/srt_stream.log"
    echo "[WARN] Impossible d'écrire dans $LOG_DIR, log redirigé vers $LOG_FILE"
}

validate_config

SRT_URL=$(build_srt_url)
build_ffmpeg_input_args  # remplit le tableau FFMPEG_INPUT_ARGS

# Arguments de sortie communs aux deux sources
FFMPEG_OUTPUT_ARGS=(
    -c:v libx264 -preset veryfast -tune zerolatency -pix_fmt yuv420p -r 25
    -b:v 2M -minrate 2M -maxrate 2M -bufsize 2M -x264-params nal-hdr=cbr
    -c:a aac -b:a 128k -ar 48000 -ac 2
    -f mpegts
)

# =============================================================================
# Démarrage
# =============================================================================
log_info "============================================"
log_info "Démarrage du script SRT Stream"
log_info "Mode SRT     : $SRT_MODE"
if [[ "$SRT_MODE" == "caller" ]]; then
    log_info "Cible        : ${SRT_HOST}:${SRT_PORT}"
else
    log_info "Écoute       : 0.0.0.0:${SRT_PORT}"
fi
if [[ -n "$INPUT_FILE" ]]; then
    log_info "Source       : fichier MP4 en boucle → $INPUT_FILE"
else
    log_info "Source       : mire noire animée (par défaut)"
fi
log_info "Auto-restart : $AUTO_RESTART"
[[ -n "$SRT_OPTIONS" ]] && log_info "Options SRT  : $SRT_OPTIONS"
log_info "URL SRT      : $SRT_URL"
log_info "Log          : $LOG_FILE"
log_info "FFmpeg       : $($FFMPEG_BIN -version 2>&1 | head -1)"
log_info "============================================"

# =============================================================================
# Boucle principale de relance
# =============================================================================
SESSION=0

while true; do
    SESSION=$((SESSION + 1))
    log_info "--- Session #$SESSION : lancement de ffmpeg (mode=$SRT_MODE) ---"
    log_info "Commande : $FFMPEG_BIN ${FFMPEG_INPUT_ARGS[*]} ${FFMPEG_OUTPUT_ARGS[*]} $SRT_URL"

    $FFMPEG_BIN "${FFMPEG_INPUT_ARGS[@]}" "${FFMPEG_OUTPUT_ARGS[@]}" "$SRT_URL" \
        2> >(
            while IFS= read -r line; do
                # Décommenter pour afficher les logs bruts ffmpeg :
                # echo "[ffmpeg] $line"

                if echo "$line" | grep -qiE "(srt.*connect|accepted.*connection|client.*connect|new.*session)"; then
                    if [[ "$SRT_MODE" == "listener" ]]; then
                        log_connect "Nouveau client connecté sur le port $SRT_PORT"
                    else
                        log_connect "Connexion établie vers ${SRT_HOST}:${SRT_PORT}"
                    fi
                fi

                if echo "$line" | grep -qiE "(srt.*disconnect|connection.*lost|broken.*pipe|eof|client.*gone|connection.*reset|peer.*closed)"; then
                    if [[ "$SRT_MODE" == "listener" ]]; then
                        log_disconn "Client déconnecté du port $SRT_PORT"
                    else
                        log_disconn "Connexion perdue vers ${SRT_HOST}:${SRT_PORT}"
                    fi
                fi

                if echo "$line" | grep -qiE "^(Error|Fatal)"; then
                    log_error "FFmpeg : $line"
                fi
            done
        ) &

    FFMPEG_PID=$!
    log_info "FFmpeg démarré (PID=$FFMPEG_PID) → $SRT_URL"

    wait "$FFMPEG_PID"
    EXIT_CODE=$?
    FFMPEG_PID=""

    if [[ $EXIT_CODE -eq 130 || $EXIT_CODE -eq 143 ]]; then
        log_info "FFmpeg terminé par signal (code=$EXIT_CODE)"
        break
    fi

    log_disconn "FFmpeg s'est arrêté (code de sortie=$EXIT_CODE)"

    if [[ "$AUTO_RESTART" == "false" ]]; then
        log_info "AUTO_RESTART désactivé - arrêt du script"
        break
    fi

    log_info "Relance dans ${RESTART_DELAY}s... (Ctrl+C pour arrêter)"
    sleep "$RESTART_DELAY"
done
