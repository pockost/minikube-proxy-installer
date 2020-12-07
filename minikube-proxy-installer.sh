#!/bin/bash
#
# @file minikube-proxy-installer
# @brief A bash script configuring system to handle proxy when using minikube

# Indicates if upgrade the system or not. Defaults to *false*.
UPGRADE=false

DEFAULT_NO_PROXY=localhost,127.0.0.0/8,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16

# Global vars
# array of network interface
INTERFACES=()
declare -A INTERFACES_DETAILS
OUTPUT_INTERFACE=()

# @description Get bash parameters.
#
# Accepts:
#
#  - *h* (help).
#
# @arg '$@' string Bash arguments.
#
# @exitcode 0 if successful.
# @exitcode 1 on failure.
function get_parameters() {
    # Obtain parameters.
    while getopts 'h;' opt; do
        OPTARG=$(sanitize "$OPTARG")
        case "$opt" in
            h) help && exit 0;;
        esac
    done
    return 0
}

# @description Shows help message.
#
# @noargs
#
# @exitcode 0 if successful.
# @exitcode 1 on failure.
function help() {
    echo 'A bash script configuring system to handle proxy when using minikube'
    echo 'Parameters:'
    echo '-h (help): Show this help message.'
    echo 'Example:'
    echo "./minikube-proxy-installer.sh -h"
    return 0
}

# @description Retreive list of all non loopback, bridged or docker related interfance.
#
# Result will be stored in INTERFACES global var.
#
# @noargs
#
# @exitcode 0 if successful.
# @exitcode 1 on failure.
function retreive_interface_list() {
  echo "Guessing network interfaces..."
  for int in $( ip link show | awk '{ print $2 }'|grep :$|cut -d: -f1|grep -v -E '^(lo|br-|virbr|docker|veth)' )
  do
    INTERFACES+=($int)
  done
  echo "FOUND ${#INTERFACES[@]} network interfaces (${INTERFACES[@]:0:3} ...)"

  return 0
}

# @description Retreive detail about given interface.
#
# Result will be stored in INTERFACES_DETAILS associative array.
#
# @arg $@ string interface name
#
# @exitcode 0 if successful.
# @exitcode 1 on failure.
function retreive_interface_detail() {
  nif=$1

  echo "Retreiving detail about network interfaces $nif"
  INTERFACES_DETAILS[$nif,state]=$( ip addr show $nif |head -n1|awk '{ print $9 }' )
  if [ "${INTERFACES_DETAILS[$nif,state]}" == "DOWN" ]
  then
    echo "Interface $nif is DOWN. Continue..."
    return 0
  fi

  # TODO from now there is only one IP managed
  INTERFACES_DETAILS[$nif,ip]=$( ip addr show $nif|grep "inet "|awk '{print $2}'|cut -d/ -f1|head -n1)

  test_connectivity $nif

  return 0
}



# @description A bash script to retreive curent network configuration
#
# @noargs
#
# @exitcode 0 if successful.
# @exitcode 1 on failure.
function retreive_network_config() {
  retreive_interface_list
  for int in ${INTERFACES[@]}
  do
    retreive_interface_detail $int
  done
}


# @description Test connectivity for given interface
#
# @args $@ string the interface name
#
# @exitcode 0 if successful.
# @exitcode 1 on failure.
function test_connectivity() {
  nif=$1

  # If interface is down return function
  ping -W 1 -c1 -I ${nif} ${INTERFACES_DETAILS[$nif,ip]}  &>/dev/null
  if [ $? -ne 0 ]
  then
    echo "CRITICAL network configuration for ${nif}"
  fi
  ping -W 2 -c1 -I ${nif} 8.8.8.8 &>/dev/null
  if [ $? -ne 0 ]
  then
    echo "INFO unable to ping 8.8.8.8 with ${nif}"
    echo "Trying direct HTTP access"
    wget --timeout=3 -q -O /dev/null google.fr
    if [ $? -ne 0 ]
    then
      echo "No internet connection for ${nif}"
      INTERFACES_DETAILS[$nif,internet]=1
      return 1
    fi
  fi
  echo "Internet is reachable with ${nif}"
  OUTPUT_INTERFACE+=($nif)
  INTERFACES_DETAILS[$nif,internet]=0
  return 0
}

# @description Ask user for proxy information, test and save config
#
# @noargs
#
# @exitcode 0 if successful.
# @exitcode 1 on failure.
function configure_proxy() {
  echo "Going to configure proxy"
  echo
  read -p "Give me your proxy URL: " proxy_url
  echo 

  echo "Testing proxy"
  http_proxy=$proxy_url wget -q -O /dev/null google.fr

  if [ $? -ne 0 ]
  then
    echo "Proxy is not working. Retry..."
    configure_proxy
    return $?
  fi

  echo "Proxy is working"
  echo "Injecting global env var in profile"
  echo "export http_proxy=$proxy_url" >> /etc/profile
  echo "export https_proxy=$proxy_url" >> /etc/profile
  echo "export ftp_proxy=$proxy_url" >> /etc/profile
  echo "export no_proxy=$DEFAULT_NO_PROXY" >> /etc/profile
  echo 'export HTTP_PROXY=$http_proxy' >> /etc/profile
  echo 'export HTTPS_PROXY=$https_proxy' >> /etc/profile
  echo 'export FTP_PROXY=$ftp_proxy' >> /etc/profile
  echo 'export NO_PROXY=$no_proxy' >> /etc/profile
  source /etc/profile

  echo
  echo "Configuration done"
  echo "Testing proxy"
  http_proxy=$proxy_url wget -q -O /dev/null google.fr

  if [ $? -ne 0 ]
  then
    echo "bash profile configuration failed"
    return 1
  else
    echo "We now have access to the internet"
  fi


}

function install_deps() {
  apt-get update
  apt-get install -y apt-transport-https curl grepcidr gnupg
  # Install kubectl
  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
  echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list
  apt-get update
  apt-get install -y kubectl
}

function install_docker() {
  which docker &>/dev/null
  if [ $? -eq 0 ]
  then
    read -p "Docker is already installed du you want to re-run install script? (Yn): " reinstall_docker
    reinstall_docker=${reinstall_docker:-y}
    case $reinstall_docker in
      [yYoO]*)
        echo "Ok let's go"
        ;;
      [nN]*)
        return 0
        ;;
      *)
        echo "Please answer y or n for yes or no"
        bad_input=0
        ;;
      esac
  fi
  curl -fsSL https://get.docker.com -o get-docker.sh
  sh get-docker.sh
  /usr/sbin/usermod -aG docker $USER
}

function configure_docker() {
  echo "Configuring docker"

  if [ ! -z "$http_proxy" ]
  then
    echo "Found a proxy. Configuring docker to used this one"
    mkdir -p /etc/systemd/system/docker.service.d/
    echo "[Service]
Environment='HTTP_PROXY=$http_proxy'
Environment='HTTPS_PROXY=$https_proxy'
Environment='NO_PROXY=$DEFAULT_NO_PROXY'" > /etc/systemd/system/docker.service.d/http-proxy.conf
    systemctl daemon-reload
    # TODO prevent to restart if no change
    systemctl restart docker
  fi

}

function install_minikube() {
  echo "Installing minikube"
  which minikube &>/dev/null

  if [ $? -eq 0 ]
  then
    read -p "minikube is already installed du you want to re-run install script? (Yn): " reinstall_minikube
    reinstall_minikube=${reinstall_minikube:-y}
    case $reinstall_minikube in
      [yYoO]*)
        echo "Ok let's go"
        ;;
      [nN]*)
        return 0
        ;;
      *)
        echo "Please answer y or n for yes or no"
        bad_input=0
        ;;
      esac
  fi

  curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
  install minikube-linux-amd64 /usr/local/bin/minikube
}

function start_minikube() {
  echo "starting minikube"

  nb_cpu=$( cat /proc/cpuinfo |grep processor|wc -l )
  if [ $nb_cpu -lt 2 ]
  then
    echo "You need at least 2 CPU in order to run minikube"
    echo "Exiting ..."
    exit 2
  fi



  minikube_options=""
  if [ ! -z "$http_proxy" ]
  then
    echo "Found a proxy. Configuring minikube to use this one"
    minikube_options="--docker-env http_proxy=$http_proxy --docker-env https_proxy=$https_proxy --docker-env no_proxy=$DEFAULT_NO_PROXY"
  fi

  echo "Starting minikube for user $USER (with minikube start $minikube_options)"
  su -c "minikube start $minikube_options" $USER
}

function check_minikube_no_proxy() {
  echo "Check if no_proxy env var contain minikube ip"
  grepcidr "$no_proxy" <(su -c "minikube ip" $USER) &>/dev/null

  if [ $? -ne 0 ]
  then
    echo "Adding minikube ip to no_proxy env var"
    echo 'export no_proxy=${no_proxy},'$(su -c "minikube ip" $USER) >> /etc/profile
    echo 'export NO_PROXY=$no_proxy' >> /etc/profile
    source /etc/profile
  fi
}

function check_k8s_work(){
  su -c "kubectl version" $USER &>/dev/null
  if [ $? -eq 0 ]
  then
    echo "Connection to K8S is ok"
  else
    echo "FAIL FAIL FAIL"
    echo "Unable to connect to k8s"
    echo 
    echo "----------------------------------"
    echo "------------DETAILS---------------"
    echo "----------------------------------"
    echo
    echo "# su -c "kubectl version" $USER"
    su -c "kubectl version" $USER
    echo
  fi

  su -c "kubectl run test --image=nginx:latest" $USER &>/dev/null
  if [ $? -eq 0 ]
  then
    echo "Create a pod into K8S is ok"
  else
    echo "FAIL FAIL FAIL"
    echo "Unable to create a pod"
    echo 
    echo "----------------------------------"
    echo "------------DETAILS---------------"
    echo "----------------------------------"
    echo
    echo "# su -c "kubectl run test-debug --image=nginx:latest" $USER"
    su -c "kubectl run test-debug --image=nginx:latest" $USER
    echo
  fi

  echo "Wait for pod to be ready (timeout 2s)"
  su -c "kubectl wait pod/test --for=condition=ready --timeout=2m" $USER
  if [ $? -eq 0 ]
  then
    echo "Pulling and starting pod is OK"
  else
    echo "FAIL FAIL FAIL"
    echo "Unable to start a pod"
    echo 
    echo "----------------------------------"
    echo "------------DETAILS---------------"
    echo "----------------------------------"
    echo
    echo "kubectl description pod test"
    su -c "kubectl describe pod test" $USER
    echo "kubectl logs test"
    su -c "kubectl describe pod test" $USER
    echo
  fi

  echo "All is OK!"
  echo "removing test"
  su -c "kubectl delete pod test" $USER

}


function configure_completion() {
  echo "Configuring user bashrc in order to enable completion"

  shell_name=$( echo $SHELL | awk -F'/' '{ print $NF }' )
  echo "source <(minikube completion $shell_name )" >> /home/$USER/.${shell_name}rc
  echo "source <(kubectl completion $shell_name )" >> /home/$USER/.${shell_name}rc
}

# @description A bash script configuring system to handle proxy when using minikube
#
# @arg $@ string Bash arguments.
#
# @exitcode 0 if successful.
# @exitcode 1 on failure.
function main() {

    get_parameters "$@"


    retreive_network_config

    if [ ${#OUTPUT_INTERFACE[@]} -eq 0 ]
    then
      echo "Unable to detect a working interface"
      echo
      end=1
      while [[ $end -ne 0 ]]; do
        read -p "Do you want to configure a proxy? (Yn): " configure_proxy
        configure_proxy=${configure_proxy:-y}
        case $configure_proxy in
          [yYoO]*)
            configure_proxy
            end=$?
            ;;
          [nN]*)
            end=0
            echo "Sorry I can do nothing..."
            echo "Bye"
            return 2
            ;;
          *)
            echo "Please answer y or n for yes or no"
            bad_input=0
            ;;
        esac
      done
    fi

    install_deps

    install_docker
    configure_docker

    install_minikube
    start_minikube
    check_minikube_no_proxy
    
    check_k8s_work

    configure_completion

    return 0
}

# @description Sanitize input.
#
# The applied operations are:
#
# - Trim.
#
# @arg $1 string Text to sanitize.
#
# @exitcode 0 if successful.
# @exitcode 1 on failure.
#
# @stdout Sanitized input.
function sanitize() {
    [[ -z $1 ]] && echo '' && return 0
    local sanitized="$1"
    # Trim.
    sanitized="${sanitized## }"
    sanitized="${sanitized%% }"
    echo "$sanitized"
    return 0
}

function run_as_root() {
  if [ "$( id -u )" != "0" ]; then
    #echo "This script need to be root"
    #which sudo &>/dev/null
    #if [ $? -eq 0 ]
    #then
    #  sudo $0
    #else
    su -c "$0" root
    #fi

    echo "Please logout and reconnect to update $USER proxy env var"
    exit
  fi
}

# Avoid running the main function if we are sourcing this file.
return 0 2>/dev/null
run_as_root
main "$@"
