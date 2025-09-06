#!/bin/bash

# Help Message Function
function _help(){
    echo "Usage: ./clean_up.sh -d <Codename>"
    echo
    echo "Cleans the Binaries of the defined Device."
    echo
    echo "Options:"
    echo "    --device <Codename>, -d <Codename>:         Cleans defined Device Binaries."
    echo "    --help, -h:                                 Shows this Help."
    echo
    echo "MainPage: https://github.com/Project-Silicium/Device-Binaries"
    exit 1
}

# Message Functions (Error)
function _error(){ echo -e "\033[1;31m${@}\033[0m" >&2; exit 1; }

# Check for Parameters
OPTS="$(getopt -o d:h -l device:,help -n 'clean_up.sh' -- "$@")" || exit 1
eval set -- "${OPTS}"

# Parse Parameters
while true
do case "${1}" in
        -d|--device) TARGET_DEVICE="${2}";shift 2;;
        -h|--help) _help 0;shift;;
        --) shift;break;;
        *) _help 1;;
    esac
done

# Check Device Parameter
if [ -z ${TARGET_DEVICE} ]
then _help
fi

# Check if Device Folder Exists
pushd "${TARGET_DEVICE}" &> /dev/null || _error "\nThe Binaries of ${TARGET_DEVICE} don't Exist!\n"

# Check for ".cleaned"
if [ -e ".cleaned" ]
then exit 0
fi

# Remove all ".inc" Files
find . -type f -name "*.inc" -delete

# Clean Up all ".inf" Files
find . -type f -name "*.inf" -print0 | while IFS= read -r -d '' FILE; do
    # Apply Common Clean Up Fixes
    sed -i                                                          \
        -e '1,6d'                                                   \
        -e 's/INF_VERSION    =/INF_VERSION                    =/g'  \
        -e 's/BASE_NAME      =/BASE_NAME                      =/g'  \
        -e 's/FILE_GUID      =/FILE_GUID                      =/g'  \
        -e 's/MODULE_TYPE    =/MODULE_TYPE                    =/g'  \
        -e 's/VERSION_STRING =/VERSION_STRING                 =/g'  \
        -e 's/ENTRY_POINT    =/ENTRY_POINT                    =/g'  \
        -e 's/   RAW|/  RAW|/g'                                     \
        -e 's/   TE|/  TE|/g'                                       \
        -e 's/   DXE_DEPEX|/  DXE_DEPEX|/g'                         \
        -e 's/   PE32|/  PE32|/g'                                   \
        "${FILE}"

    # Check if the File has "Depex"
    if ! grep -q "Depex" "${FILE}"; then
        sed -i                               \
            -e 's/DXE_DRIVER/UEFI_DRIVER/g'  \
            -e :a                            \
            -e '$d;N;2,3ba'                  \
            -e 'P;D'                         \
            "${FILE}"
    else
        sed -i                               \
            -e :a                            \
            -e '$d;N;2,2ba'                  \
            -e 'P;D'                         \
            "${FILE}"
    fi

    # Print Current File
    echo "Cleaned: ${FILE}"
done

# Create a new File
if [ ! -f ".cleaned" ]
then touch .cleaned &> /dev/null
fi

# Go back to the original Location
popd &> /dev/null
