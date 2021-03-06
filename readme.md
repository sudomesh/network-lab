# Network lab

This script creates a set of network namespaces, linked by virtual eth connections. It is entirely driven by a JSON network graph configuration format. Additionally, it uses the [tc netem](http://man7.org/linux/man-pages/man8/tc-netem.8.html) traffic shaper to simulate various kinds of faulty connections, packet loss, and latency on the links. This tool was created to experiment with and test routing protocols, but it could have many other uses.

![JSON to network diagram](/network-lab.png)

## Dependencies

Your system must have network namespace support. For example, Ubuntu 16.04 will work. Also, [jq](https://stedolan.github.io/jq/) must be installed.

## Configuration

Network lab has a JSON configuration format:

```json
{
  "nodes": {
    "1": {
      "ip": "1.0.0.1"
    },
    "2": {
      "ip": "1.0.0.2"
    },
    "3": {
      "ip": "1.0.0.3"
    }
  },
  "edges": [
    {
      "nodes": ["1", "2"],
      "->": "delay 10ms 20ms distribution normal",
      "<-": "delay 500ms 20ms distribution normal"
    },
    {
      "nodes": ["2", "3"],
      "->": "delay 10ms 20ms distribution normal",
      "<-": "delay 500ms 20ms distribution normal"
    }
  ]
}
```

The `nodes` object has all the nodes, indexed by name.

* The `ip` property will be set as the node's IP addres

The `edges` object contains an array of edges.

* The `nodes` array contains the node names of the 2 sides of the edge.
* The `->` and `<-` properties contain arguments to be given to the [tc netem](http://man7.org/linux/man-pages/man8/tc-netem.8.html) command to degrade the connection from the left node to the right node and vice vera.

## Usage

```bash
sudo su
source ./network-lab.sh  << EOF
{
  "nodes": {
    "1": { "ip": "1.0.0.1" },
    "2": { "ip": "1.0.0.2" },
    "3": { "ip": "1.0.0.3" }  

},
  "edges": [
     {
      "nodes": ["1", "2"],
      "->": "loss random 0%",
      "<-": "loss random 0%"
     },
     {
      "nodes": ["2", "3"],
      "->": "loss random 0%",
      "<-": "loss random 0%"
     }
  ]
}
EOF

ip netns exec netlab-3 ip address
```
