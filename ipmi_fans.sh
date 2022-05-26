#!/bin/bash

POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -h | --host)
            HOST="$2"
            shift 2
            ;;
        -s | --speed)
            SPEED="$2"
            shift 2
            ;;
        -h | --help)
            "This script sets fan speeds on Dell PowerEdge iDrac over IPMI"
            exit 2
            ;;
        -* | --*)
            echo "Unknown option $1"
            exit 1
            ;;
        *)
            POSITIONAL_ARGS+=("$1")
            shift
            ;;
    esac
done

set -- "${POSITIONAL_ARGS[@]}"

install_packages () {
    if ! rpm -qa | grep ipmitool > /dev/null; then
        echo "ipmitool package not installed, installing..."
        dnf install ipmitool -y
    fi
}

get_ip () {
    case $HOST in
        r510) 
            IP_ADDRESS="192.168.165.48"
            ;;
        r710)
            IP_ADDRESS="192.168.165.49"
            ;;
        *)
            echo -n "unknown host"
            exit 1
            ;;
    esac

    return ${IP_ADDRESS}
}

main () {
    install_packages
    get_ip
    
    ipmitool -I lanplus -H "${IP_ADDRESS}" -U root -P calvin raw 0x30 0x30 0x01 0x00 > /dev/null
    echo "Dell r510 fan control set to manual"

    ipmitool -I lanplus -H "${IP_ADDRESS}" -U root -P calvin raw 0x30 0x30 0x02 0xff 0x"${SPEED}" > /dev/null
    echo "Fan speed on host ${HOST} set to ${SPEED}%"

    if [[ -n $1 ]]; then
        echo "Last line of file specified as non-opt/last argument:"
        tail -1 "$1"
    fi
}


main