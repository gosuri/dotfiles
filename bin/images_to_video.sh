#!/bin/zsh
# Converting Still Images to Video
# ================================
# depends on ImageMagick and  ffmpeg
#
mkdir temp
cp *.jpg temp/.
mogrify -resize 800x800  temp/*.jpg
convert temp/*.jpg -delay 10 -morph 10 temp/%05d.jpg
ffmpeg -r 25 -qscale 2  -i temp/%05d.jpg output.mp4
# rm -R temp
