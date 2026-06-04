# Talos Machine Configuration Template - Worker
version: v1alpha1
debug: false
persist: true

machine:
  type: worker
  
  network:
    hostname: ${hostname}
    interfaces:
      - interface: eth0
        dhcp: false
        addresses:
          - ${ip_address}/24
        routes:
          - network: 0.0.0.0/0
            gateway: ${gateway}
    nameservers:
      - ${nameserver}
  
  install:
    disk: /dev/sda
    image: ghcr.io/siderolabs/installer:v1.7.0
    bootloader: true
    wipe: false
  
  kubelet:
    image: ghcr.io/siderolabs/kubelet:v1.31.0

cluster:
  controlPlane:
    endpoint: ${cluster_endpoint}
  
  clusterName: ${cluster_name}
  
  network:
    dnsDomain: cluster.local
    podSubnets:
      - 10.244.0.0/16
    serviceSubnets:
      - 10.96.0.0/12
