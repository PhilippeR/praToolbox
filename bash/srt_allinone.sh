#!/usr/bin/env bash

# A valider.....

############################################
# CONFIGURATION (valeurs par défaut)
############################################

# Mode SRT : caller ou listener
SRT_MODE="listener"        # caller | listener

# Chiffrement SRT
SRT_ENCRYPTION="on"        # on | off
SRT_PASSPHRASE="supersecret"
SRT_PBKEYLEN=16            # 16, 24 ou 32

# Adresse et port
SRT_IP="0.0.0.0"           # listener : souvent 0.0.0.0
SRT_PORT=9000

# Latence SRT (ms)
SRT_LATENCY=200

############################################
# CONSTRUCTION DE L'URL SRT
############################################

SRT_URL="srt://${SRT_IP}:${SRT_PORT}"
SRT_OPTIONS="mode=${SRT_MODE}&latency=${SRT_LATENCY}"

if [[ "${SRT_ENCRYPTION}" == "on" ]]; then
    SRT_OPTIONS+="&passphrase=${SRT_PASSPHRASE}&pbkeylen=${SRT_PBKEYLEN}"
fi

SRT_ADDRESS="${SRT_URL}?${SRT_OPTIONS}"

echo "➡️  SRT address : ${SRT_ADDRESS}"

############################################
# FFmpeg
############################################

ffmpeg -f lavfi -re -i "color=black:size=1280x720:rate=25" \
       -f lavfi -i "sine=frequency=1000:sample_rate=48000:duration=0" \
       -vf "drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf: \
            text='%{localtime\\:%X}':fontsize=72:fontcolor=white:x=(w-tw)/2:y=(h-th)/2" \
       -c:v libx264 -preset veryfast -tune zerolatency -pix_fmt yuv420p -r 25 \
       -minrate 2M -maxrate 2M -bufsize 2M -x264-params nal-hrd=cbr \
       -c:a aac -b:a 128k -ar 48000 -ac 2 \
       -f mpegts "${SRT_ADDRESS}"
