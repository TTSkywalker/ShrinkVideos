#!/bin/bash
BIT_RATE_PREFIX='bit_rate='
SIZE_PREFIX='size='
ONE_M=1024
ENTER='ENTER'
VIDEO_STATUS_OK='ok'
LOG_PATH='a.txt'
# log path
# default and set params
inputPathPrefix=$1
outputPathPrefix=$2
pendingPathPrefix=$3

function getRawProbe(){
    rawRes=`ffprobe -hide_banner -show_format $1 2>&1`
    echo $rawRes | tr -d '\n\r' | sed s/[[:space:]]/$ENTER/g
}

function getSize(){
    rawProbe=$1
    size=${rawProbe#*$SIZE_PREFIX}
    size=${size%%$ENTER*}
    echo $((size/ONE_M/ONE_M)) # unit: m
}

function getBitRate(){
    rawProbe=$1
    bitRate=${rawProbe#*$BIT_RATE_PREFIX}
    bitRate=${bitRate%%$ENTER*}
    echo $((bitRate/ONE_M)) # unit: k
}
i=0
inputCandidates=`ls $inputPathPrefix`
for inputCandidate in $inputCandidates
do
    i=$[i+1]
    if [[ $i -gt 10 ]];then
    break
    fi
    inputPath=$inputPathPrefix/$inputCandidate
    videoStatus=$VIDEO_STATUS_OK
    echo -n $inputPath >> $LOG_PATH
    if [[ -f $inputPath ]];then
        rawProbe=`getRawProbe $inputPath`
        if [[ $rawProbe == *$BIT_RATE_PREFIX* ]]&&[[ $rawProbe == *$SIZE_PREFIX* ]];then
            inputSize=`getSize $rawProbe`
            inputBitRate=`getBitRate $rawProbe`
            if [[ $inputSize -ge 600 ]];then
                inputFileName=${inputPath##*/}
                inputFileName=${inputFileName%.*}
                outputFileName=${inputFileName}'.mp4'
                outputBitrate=$[$inputBitRate*45/100]
                echo -n ': '$inputBitRate' to '$outputBitrate >> $LOG_PATH
                ffmpeg -hide_banner -y -hwaccel cuda -hwaccel_output_format cuda -i $inputPath -tag:v hvc1 -c:v hevc_nvenc -b:v ${outputBitrate}K $outputPathPrefix/$outputFileName
            else
                videoStatus='inputSize '$inputSize'm, too small'
            fi
        else
            videoStatus='weird probe'
        fi
        [[ $videoStatus == $VIDEO_STATUS_OK ]] && rm $inputPath
    else
        videoStatus='not a file'
    fi
    [[ $videoStatus != $VIDEO_STATUS_OK ]] && mv $inputPath $pendingPathPrefix/$inputCandidate
    echo '--→'$videoStatus >> $LOG_PATH
done