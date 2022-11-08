getCurrentFileName(){
  local file="$0"
  local fileName=${file##*/}   
  echo $fileName
}

getCurrentDir(){
    local DIR=`pwd`
    echo $DIR
}

getCurrentFullFilePath(){
    local dir=`getCurrentDir`
    local fileName=`getCurrentFileName`
    local fullPath="$dir/$fileName"
    echo $fullPath
}

gmd(){
  mkdir $@
}

grd(){
  rm -fr "$1"
}

# Create bash file
gcbf(){
  echo "#!/bin/bash" > "$1"
}

# Create new bash file and make it executable
cx(){
  gcbf "$1" && x "$1"
}

# Note: This will give relative path from this file
#(WIP, not working yet)
get_relative_path(){
  echo "$(dirname $(realpath $0))"
}

# edit shortcut
e(){ vim $@ }


