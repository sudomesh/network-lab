#!/bin/bash
stdin=$(cat)
input=$stdin

# clear namespaces
ip -all netns delete || true

# add namespaces
echo "adding nodes"
for node in $(jq '.nodes | keys[]' <<< "$input")
do
  ip netns add "netlab-${node:1:-1}"
done

# iterate over edges array
echo "adding edges"
length=$(jq '.edges | length' <<< "$input")
for ((i=0; i<$length; i++)); do

  # get names of nodes
  A=$(jq '.edges['$i'].nodes[0]' <<< "$input")
  B=$(jq '.edges['$i'].nodes[1]' <<< "$input")
  A=${A:1:-1}
  B=${B:1:-1}

  # create veth to link them
  ip link add "veth-$A-$B" type veth peer name "veth-$B-$A"

  # assign each side of the veth to one of the nodes namespaces
  ip link set "veth-$A-$B" netns "netlab-$A"
  ip link set "veth-$B-$A" netns "netlab-$B"

  # add ip addresses on each side
  ipA=$(jq '.nodes["'$A'"].ip' <<< "$input")
  ipB=$(jq '.nodes["'$B'"].ip' <<< "$input")
  ip netns exec "netlab-$A" ip addr add ${ipA:1:-1} dev "veth-$A-$B"
  ip netns exec "netlab-$B" ip addr add ${ipB:1:-1} dev "veth-$B-$A"

  # bring the interfaces up
  ip netns exec "netlab-$A" ip link set dev "veth-$A-$B" up
  ip netns exec "netlab-$B" ip link set dev "veth-$B-$A" up

  # add some connection quality issues
  AtoB=$(jq '.edges['$i']["->"]' <<< "$input")
  BtoA=$(jq '.edges['$i']["<-"]' <<< "$input")

  ip netns exec "netlab-$A" tc qdisc add dev "veth-$A-$B" root netem ${AtoB:1:-1}
  ip netns exec "netlab-$B" tc qdisc add dev "veth-$B-$A" root netem ${BtoA:1:-1}
done
