#!/bin/bash
# ffmpeg -y -vsync 0 -hwaccel cuda -hwaccel_output_format cuda -i input.mp4
# -vf scale_npp=1920:1080 -c:a copy -c:v h264_nvenc -b:v 5M output1.mp4
# -vf scale_npp=1280:720 -c:a copy -c:v h264_nvenc -b:v 8M output2.mp4 -tag:v hvc1

video_format_prefix='Video:'
bitrate_suffix='kb/s'
in_video_path=$1
out_video_path=$2
pending_video_path=$3
video_list=`ls $in_video_path`
# echo '----------------------------------------------'
i=0
echo 
for video in $video_list
do
    i=$[i+1]
    videoStatus=0
    if [[ $i -gt 20 ]];then
    break
    fi
    inputPath="$in_video_path/$video"
    output_raw=`ffprobe -hide_banner -show_format "$inputPath" 2>&1`
    if [[ "${#output_raw}" > 0 ]]
    then
        output_videoInfo=`ffprobe -hide_banner -show_format "$inputPath" 2>&1 | grep $video_format_prefix`
        input_size=`ffprobe -hide_banner -show_format "$inputPath" | grep size= 2>&1`
        input_size=${input_size#*size=}
        input_size=$[input_size/1024/1024]
        output_startWithCodec=`echo ${output_videoInfo#*$video_format_prefix}`
        if [[  $output_startWithCodec == h264* ]] && [[ input_size -gt 512 ]]
        then
        output_before_bitrate=${output_videoInfo%$bitrate_suffix*}
        output_bitrate=`echo ${output_before_bitrate##*,}`
            target_bitrate=$[$output_bitrate*45/100]
            echo processing:${output_bitrate}' to '$target_bitrate
            ffmpeg -hide_banner -y -hwaccel cuda -hwaccel_output_format cuda -i $inputPath -tag:v hvc1 -c:v hevc_nvenc -b:v ${target_bitrate}K $out_video_path/${video%.*}.mp4
            theSize=`ffprobe -hide_banner -show_format "$inputPath" | grep size= 2>&1`
            theSize=${theSize#*size=}
            theSize=$[theSize/1024/1024]
            if [[ $input_size -ge $theSize ]]
            then
                rm $inputPath
            fi
        else
            videoStatus=2
            echo pass:input_size_$input_size---codec_${output_startWithCodec:0:4}
        fi
    else
        videoStatus=3
        echo pass:_raw_empty
    fi
    echo "$inputPath"---"$videoStatus" >> a.txt
    [[ $videoStatus -ne 0 ]] && mv "$inputPath" "$pending_video_path"
done
