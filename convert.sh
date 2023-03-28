#!/bin/bash

set -e

##Check arguments valid
if [[ -z $1 ]] || ! [[ -d $1 ]]
then
    echo "Usage: ./convert.sh /path/to/directory/to/recursively/convert"
    exit 1
fi

##Check dependencies
if ! command -v ffmpeg &>/dev/null
then
    echo "ffmpeg not installed on system!"
    exit 2
fi

if (! ffmpeg -version | grep libvorbis &>/dev/null) || ! (ffmpeg -version | grep libmp3lame &>/dev/null)
then
    echo "ffmpeg not compiled with support for libvorbis and libmp3lame!"
    exit 3
fi

##Locate mp3 files using MIME type
#Should properly handle both 
# a) Charters giving a random png the extension .mp3
# b) Horrifying filepaths that are technically valid including newlines or the like

echo "Locating all mp3 files to convert..."

##Annoying platform-specific behavior... macOS uses -I instead of -i for file

if [[ $(uname) -eq "Darwin" ]]
then
    file_opts="-bI"
else
    file_opts="-bi"
fi

mp3_files=()
while IFS=  read -r -d $'\0'; do
    mp3_files+=("$REPLY")
done < <(find "$1" -type f -exec bash -c "[[ \$(file ${file_opts} \"{}\") == *audio/mpeg* ]]" \; -print0)


convert_and_delete(){
    echo Converting ${1}...

    base=${1%.*}
    ffmpeg -i "$1" "${base}.ogg" </dev/null 1>/dev/null  2>/dev/null
    rm "$1"
}


for file in "${mp3_files[@]}"
do
    convert_and_delete "$file"
done