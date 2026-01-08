#!/bin/bash

# objectif
# encoder en une fois les differentes pistes audio
# 
# 

# variables
#gop=50
#preset="fast"

# array variables define how many track you want to convert. 
How_many_tracks=1
tracks=$((How_many_tracks-1))


# list of source files
#inputfolder=./sources
inputfolder=.
inputs=$( ls $inputfolder/*.mp4 )

for input in $inputs
do
    base=$(basename ${input%.*})
    outputfolder="./outputs/$base"
    mkdir -p $outputfolder 

    for ((track=0; track<=tracks; track++ ))
    
    do
        output="${outputfolder}/${base}_${track}.mp4"
        outputv="${outputfolder}/${base}_${track}.isma"


        cmd="ffmpeg -y -i ${input} -vn -map 0:a:${track} -c:a aac -b:a 96k ${output} "
        echo "---------------------------------------"
        echo $cmd
        echo "---------------------------------------"
        $($cmd) >> log.txt
        
        # cmd="
        # mp4split --license_key=/etc/usp-license.key --brand=piff --brand=iso9  
        # -o ${outputv} ${output} --track_type=video
        # "
        # $($cmd) >> log.txt
    done 
done