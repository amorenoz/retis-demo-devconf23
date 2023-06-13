#!/bin/bash

set -eux

start() {
    # Create two namespaces
    ip netns add priv
    sudo ip link add dev priv type veth peer priv_p
    sudo ip link set priv_p netns priv
    ip netns exec priv ip link set priv_p name eth0

    ip netns add pub
    ip link add dev pub type veth peer pub_p
    ip link set pub_p netns pub
    ip netns exec pub ip link set pub_p name eth0
   

    # Set public subnet
    ip addr add 172.100.100.48/24 dev pub
    ip link set pub up
    ip netns exec pub ip addr add 172.100.100.100/24 dev eth0
    ip netns exec pub ip link set eth0 up
    ip netns exec pub ip route add default via 172.100.100.100 dev eth0

    # Set private subnet
    ip addr add 192.168.100.1/24 dev priv
    ip link set priv up
    ip netns exec priv ip addr add 192.168.100.2/24 dev eth0
    ip netns exec priv ip link set eth0 up
    ip netns exec priv ip route add default via 192.168.100.1 dev eth0

    ## We need this for ping to not use raw sockets.
    ip netns exec priv sysctl net.ipv4.ping_group_range="0 2147483647"

    # Configure nft
    nft -f masq.rules
}

stop() {

    ip link del pub || true
    ip link del priv || true
    ip netns del pub || true
    ip netns del priv || true
    nft flush ruleset
}

case $1 in
    start) start;;
    stop) stop;;
    *) (echo "$0 start | stop"; exit 1);;
esac
