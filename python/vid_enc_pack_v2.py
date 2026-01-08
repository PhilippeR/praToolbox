# -*- coding: utf-8 -*-
import os
import argparse
#################################################################################
# V2 du script avec l'introduction d'argument -i -o 
#################################################################################

# Argument parser
parser = argparse.ArgumentParser(description='Usage: Encoder et packager une video dans les differents profils pour produire les ismv')
parser.add_argument('-i', '--input', default='/mnt/d/ftv/origin_usp/fmp4/', help='Input folder')
parser.add_argument('-o', '--output', default='/mnt/d/temp/outputs/', help='Output folder')
args = parser.parse_args()

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
inputfolder = args.input
outputfolder = args.output

print(f"Input folder: {inputfolder}")
print(f"Output folder: {outputfolder}")
confirmation = input("Do you want to continue? (y/n): ")

if confirmation.lower() == 'n':
    parser.print_help()
    exit()

inputs = [os.path.join(inputfolder, file) for file in os.listdir(inputfolder) if file.lower().endswith((".mp4", ".ts"))]

for input in inputs:
    base = os.path.splitext(os.path.basename(input))[0]
    outputfilesfolder = os.path.join(outputfolder, base)
    #os.makedirs(outputfolder, exist_ok=True)
    os.makedirs(outputfilesfolder, exist_ok=True)

    for rung in range(len(heights)):
        height = heights[rung]
        bitrate = bitrates[rung]
        maxrate = maxrates[rung]
        bufsize = bufsizes[rung]
        profil = profils[rung]
        level = levels[rung]

        outputmp4 = f"{outputfilesfolder}/{base}_{height}p_{bitrate}_{preset}.mp4"
        outputismv = f"{outputfilesfolder}/{base}_{height}p_{bitrate}_{preset}.ismv"
        #encodage video
        cmd = (
            f"ffmpeg -y -i {input} -an -c:v libx264 "
            f"-vf scale=-1:{height} -b:v {bitrate} "
            f"-maxrate {maxrate} -bufsize {bufsize} "
            f"-profile:v {profil} -level {level} "
            f"-keyint_min {gop} -sc_threshold 0 "
            f"-preset {preset} {outputmp4}"
        )
        
        os.system(cmd )
        #packaging ftv
        cmd = (
            f"mp4split --license_key=/etc/usp-license.key --brand=piff --brand=iso9"  
            f" -o {outputismv} {outputmp4} --track_type=video"
        )
        os.system(cmd)
