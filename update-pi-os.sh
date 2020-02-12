#!/bin/bash -x
set -o nounset -o pipefail

##
## script that will perform OS updates and basic maintenance for a Raspberry PI running Raspbian Stretch
##


SCRIPT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd ~
USER_ROOT=$(pwd)
echo "SCRIPT_ROOT =" ${SCRIPT_ROOT}


function globals {
  export LC_ALL=en_US.UTF-8
};
globals;

# Calls a function of the same name for each needed variable.
function global {
  for arg in "$@"
  do [[ ${!arg+isset} ]] || eval "$arg="'"$('"$arg"')"'
  done
}

function -h {
cat <<USAGE
USAGE: update-rpi.sh (presented with defaults)
                                              (--staticIp "")?
                                              (--updateCradlePoint false)?


  perform OS update and basic maintenance.


USAGE
};
function --help { -h ;}

function options {
  while [[ ${1:+isset} ]]
  do
    case "$1" in
      --staticIp)                       staticIp="$2"                               ; shift ;;
      --updateCradlePoint)              updateCradlePoint="$2"                      ; shift ;;
      --*)                              err "No such option: $1"                            ;;
    esac
    shift
  done
}

function validate {
    if [ -z ${staticIp+x} ]; then
        staticIp=$(cat /etc/network/interfaces | grep "address" | xargs | tr --delete "address ")
    fi

    countOfHashes=$(echo ${staticIp} | grep -c -e "^#.*$")
    if [ ${countOfHashes} -eq 1 ]; then
        staticIp=$(cat /etc/network/interfaces.d/eth0 | grep "address" | xargs | tr --delete "address ")
    fi
    if [ "${staticIp}x" == "x" ]; then
      staticIp=$(cat /etc/network/interfaces.d/eth0 | grep "address" | xargs | tr --delete "address ")
    fi
    echo "Found staticIp as : ${staticIp}"

    defaultIPScheme=${staticIp%.*}
    echo "Found defaultIPScheme as : ${defaultIPScheme}"

    if [ -z ${updateCradlePoint+x} ]; then
        updateCradlePoint="false"
    fi

    if [ "${updateCradlePoint}" == "true" ]; then
        echo "Updating Cradle Point ip scheme... using scheme: ${defaultIPScheme}"
        updateCradlePointIpScheme;
        exit 1
    fi

}

function updateCradlePointIpScheme {
    ## find the CP device
    regexMac='MAC Address: (.*) \((.*)\)'
    cpRegex="2A3044.*"
    cpp=""
    cpMac=""
    while IFS='' read -r line
    do

        if [[ "${line}" =~ ${regexMac} ]]; then
          cpMac=${BASH_REMATCH[1]}
          cpMac=$(echo "${cpMac//:}") ## remove : from MAC

          if [[ "${cpMac}" =~ ${cpRegex} ]]; then
            cpp="${cpMac#2A30}" ## remove the first two segments
            cpp=$(echo ${cpp} | tr '[:upper:]' '[:lower:]') ## go to lowercase
            echo "mac -> ${cpMac}  -> altered -> ${cpp}"
            break
          fi

        else
          continue
        fi

    done < <(sudo nmap -sP ${defaultIPScheme}.1/24)

    ## if --basic doesn't work use  --digest
    curl -s --basic --insecure -u admin:${cpp} -XPUT "http://192.168.0.1/api/config/lan/0" -d "data={\"ip_address\":\"${defaultIPScheme}.1\", \"netmask\": \"255.255.255.0\", \"dhcpd\":{\"range_start\":50,\"range_end\":99}}"
}


function process {

    sudo apt-get update
    sudo DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::=--force-confnew upgrade -y
    sudo apt-get install -y xrdp avahi-utils nmap ufw curl

    ## remove unneeded packages
    sudo apt-get purge -y libreoffice-* python-minecraftpi minecraft-pi
    if [ -d ${USER_ROOT}/python_games ]; then
        sudo rm -rf ${USER_ROOT}/python_games
    fi

    sudo apt-get autoremove -y

}

## function that gets called, so executes all defined logic.
function main {

    options "$@"
    validate
    process

    exit 0
}

if [[ ${1:-} ]] && declare -F | cut -d' ' -f3 | fgrep -qx -- "${1:-}"
then "$@"
else main "$@"
fi

