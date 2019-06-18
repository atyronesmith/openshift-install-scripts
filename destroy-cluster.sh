#!/bin/bash
#  You will need to install yq
#     go get gopkg.in/mikefarah/yq.v2
#

usage() {
    cat <<EOM
    Usage:
    $(basename $0) [-e openshift_executable_path ]  build_directory
    Create a cluster using openshift-install.  The search order for the openshift-install program is:
       1. -l openshift_executable_path
       2. openshift-install in $PATH
       3. $GOPATH/src/github.com/openshift/installer/bin/openshift-install
    build_directory -- Current deployment directory
EOM
    exit 0
}

set_variable()
{
    local varname=$1
    shift
    if [ -z "${!varname}" ]; then
        eval "$varname=\"$@\""
    else
        echo "Error: $varname already set"
        usage
    fi
}

unset OSI_LOCATION CONFIG_FILE

while getopts 'l:' c
do
    case $c in
        l) set_variable OSI_LOCATION $OPTARG ;;
        h|?) usage ;;
    esac
done

# Shift to arguments
shift $((OPTIND-1))

if [ "$#" -ne 1 ]; then
    usage
fi

if [ -v "${OSI_LOCATION}" ]; then
    if [ ! -x "${OSI_LOCATION}" ]; then
        echo "${OSI_LOCATION} does not exist or is not executable..."
        exit 1
    fi
    echo "-l location ${OSI_LOCATION}"
    CMD=${OSI_LOCATION}
else
    CMD=$(command -v openshift-install)
    if [ $? != 0 ]; then
        CMD="${GOPATH}/src/github.com/openshift/installer/bin/openshift-install"
        if [ ! -x ${CMD} ]; then
            echo "Could not find openshift-installer... GOPATH not exported?"
            exit 1
        fi
    fi
fi

ODIR=$1

${CMD} --dir $ODIR destroy cluster 

