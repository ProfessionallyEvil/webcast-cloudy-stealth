#!/usr/bin/env bash

# https://elrey.casa/bash/scripting/harden
set -${-//[sc]/}eu${DEBUG+xv}o pipefail

function main(){
  SCRIPTPATH="$( cd "$(dirname "$(readlink -f "$0")")" >/dev/null 2>&1 ; pwd -P )"
  source "${SCRIPTPATH}/shared.sh"

  functions=(
    'a_backup'
    't_destroy'
  )

  for functionz in "${functions[@]}" ; do
    if [[ "${functionz}" == "a_backup" ]] && [[ -n "${SKIP_BACKUP:-}" ]] ; then
      :
    else
      run_func "${functionz}"
    fi
  done
}

# https://elrey.casa/bash/scripting/main
if [[ "${0}" = "${BASH_SOURCE[0]:-bash}" ]] ; then
  main "${@}"
fi
