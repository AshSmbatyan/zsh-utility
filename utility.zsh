#! /bin/zsh

_PUBLIC_IP=$(curl -s --connect-timeout 5 -m 5 ifconfig.me)


function is_incomplete {
    if [ -f "${1}/valid_vpns.txt" ]; then
        for vpn in $(find $1 -iname "*.ovpn" ! -iname "*public*" -type f \
            | sed 's/.*\(vpn.*\.ovpn\).*/\1/'); do
            if ! grep -q $vpn  ${1}/valid_vpns.txt; then
                return 0
            fi
        done
    else
        echo "`basename ${0}`: cannot access `realpath ${1}/valid_vpns.txt`: No such file or directory"
    fi
    return 1
}

function missing_config_files {
    grep -vf <(find $1 -iname "*.ovpn" ! -iname "*public*" -type f \
    | sed 's/.*\(vpn.*\.ovpn\).*/\1/') ${1}/valid_vpns.txt
}

function iconfirm {
    while true; do 
        read answer
        case $answer in
            [Yy]* )
                return 0
                break
                ;;
            [Nn]* )
                return 1
                break 
                ;;
            * )
                echo "Please answer yes or no"
                ;;
        esac
    done
}

function smart_openvpn {
    vpn=$1
    timeout=$2

    if [[ $(curl -s --connect-timeout 10 -m 12 ifconfig.me) = $_PUBLIC_IP ]]; then
        openvpn $vpn > /dev/null &
        vpnPID=$!
        sleep $timeout
        r=$(curl -s --connect-timeout 10 -m 12 ifconfig.me)
        if [[ $r = $_PUBLIC_IP ]] \
           || [[ -z $r  ]] \
           || [[ ! $r =~ ^([0-9]{1,3}\.){3}[0-9]+$ ]]
        then
            pkill openvpn
            sleep 1
            return 1
        else 
            return 0
        fi
    else
        return 1
    fi
}

function openvpn_valid {
    r=$(curl -s --connect-timeout 10 -m 12 ifconfig.me)
    if [[ $r = $_PUBLIC_IP ]] \
       || [[ -z $r  ]] \
       || [[ ! $r =~ ^([0-9]{1,3}\.){3}[0-9]+$ ]]
    then
        return 1
    fi
    return 0
}

function ceil {
    echo "a=$1; b=$2; if ( a%b ) a/b+1 else a/b" | bc
}

function packet_loss {
    sudo ping -i $1 -c $2 1.1.1.1 -q | grep packet | awk  '{print $6}' | awk -F% '{print $1}'
}
