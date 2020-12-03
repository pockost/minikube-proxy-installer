#!/usr/bin/env bats
#
# minikube-proxy-installer tests, from root folder run: bats tests.

setup() {
    source minikube-proxy-installer.sh
    touch /tmp/empty_file
}

teardown() {
    rm /tmp/empty_file
}

@test 'Show help with help function.' {
    [[ "$(help)" == *'help'* ]]
}
