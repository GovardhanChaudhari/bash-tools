#!/bin/bash
get_relative_path(){
  echo "$(dirname $(realpath $0))"
}

# This is working when this script is run,
# but might not work when called this function 
# from command line, as bash may not able to find
# the path of this file of 'get_relative_path' function
get_relative_path