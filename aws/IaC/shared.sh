#!/usr/bin/env bash

ansible_cmd=(
  'ansible-playbook'
)
terraform_cmd=(
  'terraform'
  'apply' '-auto-approve'
)

infra_apply_order=(
  # 'global/account_setup'
  'nessus'
  'manual_scanning'
  'bruteforce'
)

global_path="../global/ansible"

export ansible_cmd terraform_cmd global_path

function get_cwd(){
  basename "${PWD}"
}

function check_cwd(){
  if [[ "$(get_cwd)" == 'IaC' ]] ; then
    return 0
  else
    return 1
  fi
}

function all_infra(){
    for folder in "${infra_apply_order[@]}" ; do
      pushd "${folder}" > /dev/null || exit 1
      eval "${1}"
      popd > /dev/null || exit 1
    done
}

function nmap_check(){
  echo "waiting for ssh to start..."
  while ! nmap -Pn -n -sT -p 22 "${1}" | grep open ; do
    sleep 3
  done
  sleep 3
}

function a_create(){
  logging 'starting' "${FUNCNAME[0]}" "$(get_cwd)"
  nmap_check "$(terraform output -raw public_ip)"
  "${ansible_cmd[@]}" "./prov-playbook.yml"
  logging 'finishing' "${FUNCNAME[0]}" "$(get_cwd)"
}

function a_backup(){
  logging 'starting' "${FUNCNAME[0]}" "$(get_cwd)"
  if [[ -z "${BACKUP:-}" ]] ; then
    if check_cwd; then
      global_path='global/ansible'
      "${ansible_cmd[@]}" -i "${global_path}/inventory" "${global_path}/before_destroy-playbook.yml"
    else
      hosts="$(
        grep -- '^- hosts:' prov-playbook.yml | awk '{print $3}' ||
          # first get the import_playbook to determine the limit, and then do the same as above
          grep -- '^- hosts:' $(grep import_playbook prov-playbook.yml | awk '{print $2}') | awk '{print $3}'
      )"
      "${ansible_cmd[@]}" "${global_path}/before_destroy-playbook.yml" --limit "${hosts}"
    fi
  fi
  logging 'finishing' "${FUNCNAME[0]}" "$(get_cwd)"
}

function t_destroy(){
  logging 'starting' "${FUNCNAME[0]}" "$(get_cwd)"
  terraform init #-lock=false
  "${terraform_cmd[@]}" -destroy
  logging 'finishing' "${FUNCNAME[0]}" "$(get_cwd)"
}

function t_create(){
  logging 'starting' "${FUNCNAME[0]}" "$(get_cwd)"
  terraform init #-lock=false
  "${terraform_cmd[@]}"
  logging 'finishing' "${FUNCNAME[0]}" "$(get_cwd)"
}

function t_curr_ip(){
  printf '"%s"\t"%s"\t"%s"\n' "$(date -Isec)" "$(get_cwd)" "$(terraform output -raw public_ip)"
}

function logging(){
  echo
  python3 -c 'print("#"*25)'
  printf '%s: %s for %s\n' "${1}" "${2}" "${3}"
  python3 -c 'print("#"*25)'
  echo
}

# function template(){
#   logging 'starting' "${FUNCNAME[0]}" "$(get_cwd)"
#   <cmd>
#   logging 'finishing' "${FUNCNAME[0]}" "$(get_cwd)"
# }

function run_func(){

  if check_cwd ; then
    all_infra "${1}"
  else
    eval "${1}"
  fi
}
