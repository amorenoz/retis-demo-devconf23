#!/bin/bash

set -eux

start() {
    # Create two namespaces
    ip netns add pod
    sudo ip link add dev pod type veth peer pod_p 
    sudo ip link set pod_p netns pod
    ip netns exec pod ip link set pod_p name eth0

    ip netns add dns
    sudo ip link add dev dns type veth peer dns_p
    sudo ip link set dns_p netns dns
    ip netns exec dns ip link set dns_p name eth0

    ip netns exec dns ip addr add 192.168.200.1/24 dev eth0
    ip netns exec dns ip link set eth0 up
    ip netns exec dns ip link set lo up

    ip netns exec pod ip addr add 192.168.200.50/24 dev eth0
    ip netns exec pod ip link set eth0 up
    ip netns exec pod ip link set lo up

    /usr/share/openvswitch/scripts/ovs-ctl --system-id=random restart
    ovs-vsctl add-br test
    ovs-vsctl add-port test pod
    ovs-vsctl add-port test dns

    ip link set pod up
    ip link set dns up
}

stop() {
    /usr/share/openvswitch/scripts/ovs-ctl --system-id=random restart
    ovs-vsctl del-br test || true
    /usr/share/openvswitch/scripts/ovs-ctl --system-id=random stop
    ip link del pod || true
    ip link del dns || true
    ip netns del pod || true
    ip netns del dns || true
}

case $1 in
    start) start;;
    stop) stop;;
    *) (echo "$0 start | stop"; exit 1);;
esac
