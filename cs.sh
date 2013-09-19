#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export TYPES='^(hw|proj)$'
source "${DIR}/.csconfig"
DIR_EXISTS=1
NO_GIT=2
BAD_ARGS=3
BAD_BRANCH=4
INVALID_ASSMT=5
NO_DIR=6
NO_CONFIG=100

handle_error()
{
    [[ -z "$1" ]] && return 0
    case $1 in
        $DIR_EXISTS) echo "$2: directory already exists" >&2;
                     return 0;;
        $NO_GIT) echo "$2: could not initialize git from"\
                      "~cs61c/${TYPE}/${NUMDIG}" >&2;
                 return 0;;
        $BAD_ARGS) echo "$2: bad argument ${INPUT}" >&2;
                   return 0;;
        $BAD_BRANCH) echo "$2: no such branch ${BRANCH}" >&2;
                     return 0;;
        $INVALID_ASSMT) echo "$2: no such assignment ${ASSIGNMENT}" >&2;
                        return 0;;
        $NO_DIR) echo "$2: cannot create directory ${ASSIGNMENT}/${TYPE}" >&2;
                 return 0;;
        $NO_CONFIG) echo "$2: Incomplete config. Create a file called"\
                         ".csconfig in the same directory as cs.sh and in it,"\
                         "define the environment variables"\
                         '$PATH61C and $SERVER' >&2;
                    return 0;;
        0) ;;
        *) echo "$2: error: $1" >&2; return $1;;
    esac
}

init()
{
    if [[ -z "${PATH61C}" || -z "${SERVER}" || -z "${TYPES}" ]]
    then
        return $NO_CONFIG
    fi
    INPUT=${1}
    [[ "${FLAG}" == "-1" ]] || FLAG=0
    [[ -z "${INPUT}" ]] && { INPUT=${PWD##*/}; FLAG=1; }
    ASSIGNMENT=$(basename ${INPUT})
    BRANCH="br-${ASSIGNMENT}"
    TYPE=$(basename ${INPUT} | sed 's/[0-9]*\/*$//')
    NUMA=$(basename ${INPUT} | sed 's/[a-zA-Z]*//g')
    if [ "${NUMA}" -le "9" ]
    then
        NUMDIG="0${NUMA}"
    else
        NUMDIG=${NUMA}
    fi
    if [[ -n "${2}" ]]
    then
        SUBMISSION="${ASSIGNMENT}-${2}"
    else
        SUBMISSION="${ASSIGNMENT}"
    fi
    [[ ${TYPE} =~ ${TYPES} ]] || return $BAD_ARGS
    if [[ $FLAG == 0 ]]
    then
        cd "${PATH61C}/${TYPE}/${ASSIGNMENT}" 2> /dev/null || 
            return $INVALID_ASSMT; 
    fi
    re='^[0-9]+$'
    if ! [[ ${NUMA} =~ ${re} ]]
    then
       return $INVALID_ASSMT
    fi
    if [[ ! -e "${PATH61C}/${TYPE}" ]]
    then
        mkdir "${PATH61C}/${TYPE}"
    elif [[ ! -d "${PATH61C}/${TYPE}" ]]
    then
        return $NO_DIR
    fi
}

done_using_server()
{
    init "$@"
    RET=$?
    [[ "$RET" != "0" ]] && { 
        handle_error $RET 'done_using_server';
        return $RET;
    }
    echo "Switching to branch ${BRANCH} on ${SERVER}..."
    ssh ${SERVER} "cd ${TYPE}/${ASSIGNMENT}; git co master || exit ${BAD_BRANCH}"
    RET=$?
    [[ "$RET" != "0" ]] && handle_error $RET 'done_using_server'
    return $RET;
} 


get61c()
{
    FLAG=-1
    [[ -z "${1}" ]] && { echo "get: missing argument" >&2; return $BAD_ARGS; }
    init "$@"
    RET=$?
    [[ "$RET" != "0" ]] && { 
        handle_error $RET 'get';
        return $RET;
    }
    echo "Getting new assignment ${ASSIGNMENT}..."
    ssh ${SERVER} "mkdir ~/${TYPE}/${ASSIGNMENT} || exit $DIR_EXISTS;"\
                  "cd ~/${TYPE}/${ASSIGNMENT}; git init || exit $NO_GIT;"\
                  "git pull ~cs61c/${TYPE}/${NUMDIG} || { cd;"\
                  "rm -rf ~/${TYPE}/${ASSIGNMENT}; exit $NO_GIT; } ;"\
                  "git br ${BRANCH};"
    RET=$?
    [[ "$RET" != "0" ]] && { 
        handle_error $RET 'get';
        return $RET;
    }
    mkdir "${PATH61C}/${TYPE}/${ASSIGNMENT}" || {
        echo "get: local directory for ${ASSIGNMENT} already exists" >&2;
        return $DIR_EXISTS;
    }
    cd "${PATH61C}/${TYPE}/${ASSIGNMENT}"
    git init
    git remote add ${ASSIGNMENT} ${SERVER}:~/${TYPE}/${ASSIGNMENT}
    git fetch ${ASSIGNMENT}
    git pull ${ASSIGNMENT} ${BRANCH}
    git branch ${BRANCH} ${ASSIGNMENT}/${BRANCH}
    git co ${BRANCH}
	return 0
}

lookup61c()
{
    ssh ${SERVER} "glookup $@"
}

pull61c()
{
    init "$@"
    RET=$?
    [[ "$RET" != "0" ]] && { 
        handle_error $RET 'pull';
        return $RET;
    }
    echo "Pulling changes for ${ASSIGNMENT}..."
    git co ${BRANCH} &> /dev/null || {
        echo "pull: could not check out ${BRANCH}" >&2; return $BAD_BRANCH;
    }
    if [[ "$(git symbolic-ref --short -q HEAD)" -ne "${BRANCH}" ]]
    then
        echo "pull: branch ${BRANCH} does not exist" >&2
        return $BAD_BRANCH
    fi
    git pull ${ASSIGNMENT} ${BRANCH}
}

push61c()
{
    init "$@"
    RET=$?
    [[ "$RET" != "0" ]] && { 
        handle_error $RET 'push';
        return $RET;
    }
    echo "Pushing changes for ${ASSIGNMENT}..."
    git co ${BRANCH} &> /dev/null || {
        echo "push: could not check out ${BRANCH}" >&2; return $BAD_BRANCH;
    }
    if [[ "$(git symbolic-ref --short -q HEAD)" -ne "${BRANCH}" ]]
    then
        echo "pull: branch ${BRANCH} does not exist" >&2
        return $BAD_BRANCH
    fi
    git push ${ASSIGNMENT} ${BRANCH}
}

submit61c()
{
    init "$@"
    RET=$?
    [[ "$RET" != "0" ]] && { 
        handle_error $RET 'submit';
        return $RET;
    }
    echo "Pushing changes for ${ASSIGNMENT}..."
    git push ${ASSIGNMENT} br-${ASSIGNMENT}
    echo "Submitting ${ASSIGNMENT}..."
    ssh ${SERVER} "cd ${TYPE}/${ASSIGNMENT} || exit ${INVALID_ASSMT};"\
                  "git co ${BRANCH} || exit ${BAD_BRANCH};"\
                  "submit ${SUBMISSION}; git co master; glookup -t;"
    RET=$?
    [[ "$RET" != "0" ]] && handle_error $RET 'submit';
    return $RET;
}

update_server()
{
    init "$@"
    RET=$?
    [[ "$RET" != "0" ]] && { 
        handle_error $RET 'update_server';
        return $RET;
    }
    git remote rm ${ASSIGNMENT}
    git remote add ${ASSIGNMENT} ${SERVER}:~/${TYPE}/${ASSIGNMENT}
    echo "${ASSIGNMENT} remote changed to ${SERVER}:~/${TYPE}/${ASSIGNMENT}"
}

use_server()
{
    init "$@"
    RET=$?
    [[ "$RET" != "0" ]] && { 
        handle_error $RET 'use_server';
        return $RET;
    }
    echo "Switching to branch ${BRANCH} on ${SERVER}..."
    ssh ${SERVER} "cd ${TYPE}/${ASSIGNMENT} || exit ${INVALID_ASSMT};"\
                  "git co ${BRANCH} || exit ${BAD_BRANCH}"
    RET=$?
    [[ "$RET" != "0" ]] && handle_error $RET 'use_server';
    return $RET;
} 
