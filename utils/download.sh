gdownload(){
  aria2c --max-connection-per-server=8 --min-split-size=2M "$@"
}
