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

md(){
  mkdir $@
}

rd(){
  rm -fr "$1"
}