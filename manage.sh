#/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $DIR/../../../manageUtils.sh

mirroredProject memguard

BASE=$HGROOT/programs/system/memguard

case "$1" in
mirror)
  syncHg  
;;

esac

