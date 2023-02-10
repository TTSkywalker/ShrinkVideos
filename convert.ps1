# ffmpeg -hwaccel cuvid -c:v h264_cuvid -i input.mp4 -c:v hevc_nvenc output.mp4
$inPath = ''
# $outPath = ''
$names = Get-ChildItem $inPath
foreach($name in $names){
    Write-Host 'start! '$name
    # ffmpeg -y -vsync 0 -hwaccel cuda -hwaccel_output_format cuda -i $inPath\$name -c:v hevc_nvenc -crf 30 $outPath\$name
    # ffmpeg -y -vsync 0 -hwaccel cuda -hwaccel_output_format cuda -i $inPath\$name -b:v 0.5M -c:v av1_nvenc $outPath\output1.mp4
}