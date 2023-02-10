#!/bin/bash

in_video_dir_path=$1
video=$2

ffmpeg -hide_banner -i $in_video_dir_path/"$video" -c:v copy -tag:v hvc1 -c:a copy $in_video_dir_path/abc"$video"
rm $in_video_dir_path/"$video"
mv $in_video_dir_path/abc"$video" $in_video_dir_path/"$video"