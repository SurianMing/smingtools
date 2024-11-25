#!/bin/bash
# More safety, by turning some bugs into errors.
set -o errexit -o pipefail -o noclobber -o nounset

# ignore errexit with `&& true`
getopt --test > /dev/null && true
if [[ $? -ne 4 ]]; then
    echo 'I’m sorry, `getopt --test` failed in this environment.'
    exit 1
fi

# option --output/-o requires 1 argument
LONGOPTS=pods,svc,gateway,httproute,namespace:
OPTIONS=psghn:

# -temporarily store output to be able to check for errors
# -activate quoting/enhanced mode (e.g. by writing out “--options”)
# -pass arguments only via   -- "$@"   to separate them correctly
# -if getopt fails, it complains itself to stdout
PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@") || exit 2
# read getopt’s output this way to handle the quoting right:
eval set -- "$PARSED"

gettypes=""
namespace="--all-namespaces"
# now enjoy the options in order and nicely split until we see --
while true; do
    case "$1" in
        -p|--pods)
            gettypes=$([ "$gettypes" == "" ] && echo "pods" || echo "$gettypes,pods")
            shift
            ;;
        -s)
            gettypes=$([ "$gettypes" == "" ] && echo "svc" || echo "$gettypes,svc")
            #gettypes=[[ $gettypes = "" ]] && svc || echo "$gettypes,svc"
            shift
            ;;
        -g)
            gettypes=$([ "$gettypes" == "" ] && echo "gateway" || echo "$gettypes,gateway")
            #gettypes=[[ $gettypes = "" ]] && gateway || "$gettypes,gateway"
            shift
            ;;
        -h)
            gettypes=$([ "$gettypes" == "" ] && echo "httproute" || "$gettypes,httproute")
            #gettypes=[[ $gettypes = "" ]] && httproute || "$gettypes,$httproute"
            shift 2
            ;;
        -n)
            namespace="-n $2"
            #gettypes=[[ $gettypes = "" ]] && httproute || "$gettypes,$httproute"
            shift 2
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Programming error"
            exit 3
            ;;
    esac
done

command="kubectl get $gettypes $namespace"

eval "$command"
# handle non-option arguments
# if [[ $# -ne 1 ]]; then
#     echo "$0: A single input file is required."
#     exit 4
# fi

# echo "verbose: $v, force: $f, debug: $d, in: $1, out: $outFile"
# }