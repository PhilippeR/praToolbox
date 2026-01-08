# -*- coding: utf-8 -*-
import os

# objectif
# encoder/packager en une fois les differents profils videos
# version simple et basique

# variables
gop = 50
preset = "fast"

# array variables define the rungs
heights = [216, 360, 540, 720, 1080]
bitrates = ["400k", "950k", "1.4M", "2M", "5M"]
maxrates = ["800k", "2M", "2.8M", "4M", "10M"]
bufsizes = ["800k", "2M", "2.8M", "4M", "10M"]
profils = ["baseline", "main", "main", "high", "high"]
levels = ["3", "3.1", "3.1", "3.1", "4.1"]

# list of source files
# inputfolder = "./sources"
inputfolder = "."
inputs = [file for file in os.listdir(inputfolder) if file.lower().endswith((".mp4", ".ts"))]

for input in inputs:
    base = os.path.splitext(os.path.basename(input))[0]
    outputfolder = f"/mnt/d/temp/outputs/{base}"
    os.makedirs(outputfolder, exist_ok=True)

    for rung in range(len(heights)):
        height = heights[rung]
        bitrate = bitrates[rung]
        maxrate = maxrates[rung]
        bufsize = bufsizes[rung]
        profil = profils[rung]
        level = levels[rung]

        output = f"{outputfolder}/{base}_{height}p_{bitrate}_{preset}.mp4"
        outputv = f"{outputfolder}/{base}_{height}p_{bitrate}_{preset}.ismv"
        outputvsimple = f"{outputfolder}/{base}_{height}p_{bitrate}_{preset}_simple.ismv"
        #encodage video
        cmd = (
            f"ffmpeg -y -i {input} -an -c:v libx264 "
            f"-vf scale=-1:{height} -b:v {bitrate} "
            f"-maxrate {maxrate} -bufsize {bufsize} "
            f"-profile:v {profil} -level {level} "
            f"-keyint_min {gop} -sc_threshold 0 "
            f"-preset {preset} {output}"
        )
        
        os.system(cmd )
        #packaging ftv
        cmd = (
            f"mp4split --license_key=/etc/usp-license.key --brand=piff --brand=iso9"  
            f" -o {outputv} {output} --track_type=video"
        )
        os.system(cmd)
