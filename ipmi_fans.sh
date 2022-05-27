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
    local PACKAGE="ipmitool"

    if [[ "$OSTYPE" == "linux-gnu" ]]; then
        if [ -f /etc/redhat-release ]; then
            if ! rpm -qa | grep "${PACKAGE}" > /dev/null; then
                dnf install "${PACKAGE}" -y
            fi
        elif [ -f /etc/debian_version ]; then
            if ! dpkg -l | grep "${PACKAGE}" > /dev/null; then
                apt-get install "${PACKAGE}" -y
            fi
        fi
    elif [[ "$OSTYPE" == "darwin" ]]; then
        if ! bew list | grep "${PACKAGE}" > /dev/null; then
            brew install "${PACKAGE}" -y
        fi
    else
        echo "Unkown OS"
        exit 1
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
}

convert_speed () {
    HEX_SPEED=$(printf '%x\n' ${SPEED})
}

main () {
    install_packages
    get_ip
    convert_speed
    
    ipmitool -I lanplus -H "${IP_ADDRESS}" -U root -P calvin raw 0x30 0x30 0x01 0x00 > /dev/null
    echo "Dell r510 fan control set to manual"

    ipmitool -I lanplus -H "${IP_ADDRESS}" -U root -P calvin raw 0x30 0x30 0x02 0xff 0x"${HEX_SPEED}" > /dev/null
    echo "Fan speed on host ${HOST} set to ${SPEED}%"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi