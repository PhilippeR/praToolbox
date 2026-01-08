#!/bin/bash

# objectif
# encoder/packager en une fois les differents profils videos
# sans l'audio
# ajout des profils

# variables
gop=50
preset="fast"

# array variables define the rungs
heights=(216 360 540 720 1080)
bitrates=(400k 950k 1.4M 2M 5M)
maxrates=(800k 2M 2.8M 4M 10M)
bufsizes=(800k 2M 2.8M 4M 10M)
profils=(baseline main main high high)
levels=("3" "3.1" "3.1" "3.1" "4.1")

# list of source files
#inputfolder=./sources
inputfolder=.
inputs=$( ls $inputfolder/*.mp4 )

for input in $inputs
do
    base=$(basename ${input%.*})
    outputfolder="./outputs/$base"
    mkdir -p $outputfolder 

    for rung in ${!heights[@]}
    do
        height=${heights[$rung]}
        bitrate=${bitrates[$rung]}
        maxrate=${maxrates[$rung]}
        bufsize=${bufsizes[$rung]}
        profil=${profils[$rung]}
        level=${levels[$rung]}

        output="${outputfolder}/${base}_${height}p_${bitrate}_${preset}.mp4"
        outputv="${outputfolder}/${base}_${height}p_${bitrate}_${preset}.ismv"

        cmd="
          ffmpeg -y -i ${input} -an -c:v libx264
            -vf scale=-1:${height} -b:v ${bitrate}
            -maxrate ${maxrate} -bufsize ${bufsize}
            -profile:v ${profil} -level ${level}
            -keyint_min ${gop} -sc_threshold 0 
            -preset ${preset} ${output} 
        "

        $($cmd) >> log.txt
        
        cmd="
        mp4split --license_key=/etc/usp-license.key --brand=piff --brand=iso9  
        -o ${outputv} ${output} --track_type=video
        "
        $($cmd) >> log.txt
    done 
done