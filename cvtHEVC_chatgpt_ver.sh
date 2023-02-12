#!/bin/bash
input_folder="./input_videos"
output_folder="./output_videos"
batch_size=10
bitrate_percent=45

if [ ! -d "$input_folder" ]; then
  mkdir -p "$input_folder"
fi

if [ ! -d "$output_folder" ]; then
  mkdir -p "$output_folder"
fi

videos=($(ls "$input_folder"))
num_videos=${#videos[@]}

for (( i=0; i<num_videos; i+=batch_size )); do
  batch_videos=("${videos[@]:$i:$batch_size}")
  for video in "${batch_videos[@]}"; do
    input_file="$input_folder/$video"
    output_file="$output_folder/${video%.*}.mp4"
    target_bitrate=$(ffprobe -v error -select_streams v:0 -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 "$input_file")
    target_bitrate=$(echo "($target_bitrate * $bitrate_percent) / 100" | bc)
    ffmpeg -y -i "$input_file" -c:v hevc_nvenc -b:v "${target_bitrate}k" -c:a copy -profile:v main10 -level 4.1 -x265-params "qp=20:vbv-maxrate=9000:vbv-bufsize=12000" -movflags +faststart "$output_file"
  done
done
