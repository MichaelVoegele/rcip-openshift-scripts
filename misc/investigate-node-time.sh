#!/usr/bin/env bash
# based on DNS convention using a defaultdomain you can override with switch

defaultdomain=$(oc project|sed 's/.*on server.*https:\/\///;s/:.*//')
default_builder_hosts="node1 node2"
buildname=simple-test
quiet=no

while getopts ":qd:" opt; do
  case $opt in
    d)
        domain=${OPTARG}
      ;;
    q)
      quiet=;
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done

shift $((OPTIND-1))

force_on=$@ # define a node name here if we need to

function red() { echo -e "\e[31m$@\e[0m"  ;}
function green() { echo -e "\e[32m$@\e[0m"  ;}
function whiteb() { echo -e "\e[1;37m$@\e[0m"  ;}
function cyan() { echo -e "\e[36m$@\e[0m"  ;}

SED=sed
type -p gsed >/dev/null 2>/dev/null && SED=gsed

function run() {
    local on_host=$1

    oc delete builds --all >/dev/null
    B=$(oc start-build ${buildname})
    BP=$(oc get pod|grep build|awk '{print $1}')
    Host=$(oc describe pod $BP|grep Node:|${SED} -r 's/Node:[ \t]*//;s,/.*,,')

    if [[ -n ${on_host} && ${on_host}.${domain:-$defaultdomain} != ${Host} ]];then
        oc cancel-build ${B} >/dev/null
        return 1
    fi
}
function looprun() {
    local tohost=$1
    while true;do
        run
        if [[ $? != 0 ]];then
            run ${tohost}
        else
            break
        fi
    done

    if [[ -n ${quiet} ]];then
        whiteb "Started around: $(date)"
        cyan "Running on ${Host}"

        echo -n "Waiting that the build ${BP} started: "
    fi


    while :;do
        running=$(oc get pod ${BP}|grep Running)
        [[ -n ${running} ]] && break
        sleep 2
        [[ -n ${quiet} ]] &&  echo -n "."
    done
    [[ -n ${quiet} ]] && echo ". success"

    [[ -n ${quiet} ]] && echo "Wait that the build ${BP} has succeded":
    while true;do
        OUTPUT=$(oc build-logs ${B} |tail -n1)
        if echo ${OUTPUT} | grep -q "Successfully pushed";then
            green "${Host}:Success: ${OUTPUT}"
            break
        elif echo ${OUTPUT} | grep -q "Build error";then
            red "${Host}: Failure ${OUTPUT}"
            break
        fi
        echo "Waiting: ${OUTPUT}"
        sleep 5
    done

    [[ -n ${quiet} ]] && whiteb "End at: $(date)"
}

[[ -z ${force_on} ]] && force_on=${default_builder_hosts}
for h in ${force_on};do
    looprun ${h}
done
