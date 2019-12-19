# Probely Agent for Internal Scans

## Overview

This document will guide you through the installation process of the Probely
Remote Agent on your on-premises network.

The Remote Agent connects Probely to (the parts that you choose of) your internal network.
This broadens Probely's vulnerability scanning capabilities to internal applications.
After being installed on-premises, the Agent creates an encrypted and authenticated tunnel,
in which traffic flows securely between Probely and your network.

The Agent is open-source, and the code is freely available. You can audit it if you choose to do so.

The following diagram shows an example network topology depicting an on-premises network,
the Remote Agent, the Remote Agent Hub (where remote agents connect to) and Probely's cloud.
  
![Image](url)

## Security considerations

Installing third-party software components on a network comes with an inherent risk.
Being security professionals ourselves, we are very aware of this risk.
That is why Probely is designed with a security mindset from the ground up - 
the Remote Agent is no exception to this.

We designed the Remote Agent following a set of principles that we believe will meet 
your security expectations.  

**Transparency**

* No black boxes: all code is open source, with a permissive license
* In addition to the source code, the instructions and tools to build the Agent are provided.
This enables you to ensure that the Agent running on your infrastructure has not been tampered with in any way
* You have complete control over the appliance and can change it however you see fit.

**Least privilege**

* Probely has no administrative access to the appliance
* Services are containerized and run with minimal privileges
* The appliance supports custom firewall rules so that network access can be further restricted
* The appliance does not listen on any public Internet port, in order to reduce its attack surface.
Instead, it creates an outbound connection to Probely’s network
* The Agent has been hardened in many ways, from custom hardened Linux kernel settings to proper
cryptographic algorithms choices that meet the state-of-the-art security recommendations.

**Simplicity**

* We are firm believers that simplicity enables security. The Agent follows simple design decisions, and uses industry-standard components whenever possible
* We keep network requirements to a minimum. This means, for example, that public IP addresses, complex firewall rules, and other typical network requirements are unnecessary
* The Agent requires minimal hardware resources and is designed to scale easily.  

## System Resources
The agent is comprised of a set of Docker containers, which require relatively little system resources.
The following table contains the recommended minimum system resources.  

| CPU     | RAM     | Storage     |
| ------- | ------- | ----------- |
| 1       | 1 GB    | 5 GB        |  

## Network Requirements

### Internal Network Service

The Agent requires a set of basic network services to run, which are detailed in the table below.  

| Name | Description                                                                                                                                           |
| ---- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| DHCP | An internal IP address automatically attributed by a DHCP server running your network                                                                 |
| DNS  | A set of IP addresses that the agent can use to resolve internal DNS records. The DNS resolver server addresses should be provided by the DHCP server |  

### Firewall rules

In the following table, we describe the required firewall rules.

We expect a NAT gateway on the network to allow the Agent to reach external services.
To specify a port range, we use the `:` character. For example, `1024:2048` means: *all ports from 1024 to 2048, inclusive*.

| Name           | Source     | Destination                 | Protocol     | Source Port     | Destination Port |
| -------------- | ---------- | --------------------------- | ------------ | --------------- | -------------------- |
| API            | `agent-ip`   | `api.probely.com`             | `TCP`          | `1024:`           | `443`                  |
| Farcaster      | `agent-ip`   | `hub.farcaster.probely.com`   | `TCP`          | `1024:`           | `443`                  |
| NTP            | `agent-ip`   | `any`                         | `UDP`          | `any`             | `123`                  |
| DNS            | `agent-ip`   | `<internal-dns-resolvers>` | `TCP`, `UDP`     | `any`             | `53`                   |
| DHCP           | `agent-ip`   | `any`                         | `UDP`          | `67:68`           | `67:68`                |
| Scan           | `agent-ip`   | `<scan-target>`<sup>1</sup>           | `TCP`          | `1024:`           | `<target-port>`<sup>2</sup>    |
| Docker Hub     | `agent-ip`   | `hub.docker.com`              | `TCP`          | `1024:`           | `443`                  |
| Update servers | `agent-ip`   | `<alpine-update-servers>`  | `TCP`          | `1024:`           | `80`, `443`              |  

Notes:
1. `<scan-target>` is the internal IP of the server of your web application.
2. `<target-port>` is the service port of the server of your web application. Typical values are 80 and 443.

## Installation Instructions

In this section, we describe three different procedures to deploy the Agent on your on-premises network:

1. **Virtual Machine "appliance"**. The VM contains the required components to run the Agent.
This may be a simpler approach if you have a virtualization solution already running.
(Hyper-V, KVM, VirtualBox, VMWare, among others)

1. **Running the containers yourself**.
This option may be preferable if you have the infrastructure to support running
Docker containers. (e.g., a Kubernetes cluster)

1. **Building the VM and containers from source**.

### Option 1: Virtual Machine

The Remote Agent is packaged as an archive containing an Open Virtual Format (OVF) file and a Virtual Machine Disk (VMDK).
You should be able to import the Agent on any modern virtualization solution.
However, we are happy to provide you with a custom Agent VM for your specific needs.

To install the Remote Agent, please follow these steps:

1.  Download the most recent Virtual Appliance from here

1.  Import the OVF file into your virtualization solution

1.  Allocate the required system resources for the Agent VM, as defined in the[System Resources](https://) section

1.  After the VM boots, use the default Remote Agent credentials to log in.
You can log into the VM on the local console, or via SSH (IP is assigned via DHCP).
The SSH server accepts connections from private IP address ranges only.
This is done to mitigate potential compromises if an unconfigured appliance is accidentally exposed to the Internet.
The allowed SSH client IP ranges are: `10.0.0.0/8`, `172.16.0.0/12`, and `192.168.0.0/16`.

1.  After logging on the VM for the first time, you will be requested to change the default password.
Be sure to choose a strong password. Ideally, you should disable password login via SSH,
and enforce authentication using public keys or certificates. This is outside the scope of this document,
but we can assist you in doing so through the support channels.

1.  You should have been given a `probely-agent-<version>.sh` script, which is tailored to your installation.
If you do not have this script, please contact Probely’s support team.
To install the script, run the following command on the Remote Agent Virtual Appliance: `sudo ./probely-agent-<version>.run`

1. After running the install script, the Agent should link-up with Probely's cloud.
To make sure that the connection is working properly, run the following command: `probely-farcaster-status`

1. You can now start internal targets using Probely.

### Option 2: Docker containers

A working Docker installation and `docker-compose` must be available for these instructions to work.
Typically, you would do this on a VM.  

1. You should have been given a `probely-agent-<version>.run` script, which is tailored to your installation.
If you do not have this script, please contact Probely’s support team.

1. Run the following commands:
```bash
./probely-agent-<version>.run --noexec --target ./agent-installer
cd agent-installer
./setup.sh --local <path-to-deploy-agent>
cd <path-to-deploy-agent>
docker-compose up
```
3. After starting the containers, the Agent should link-up with Probely's cloud.
To make sure that the connection is working properly, run the following script (source is available on this repo): `probely-farcaster-status`

### Option 3: Building from source

We use Packer to build the Agent VM. Currently, we support the following builder types:

* VirtualBox
* VMWare
* XEN
* KVM  

For example, to build the Agent VM using VirtualBox, follow these steps:
```bash
cd vm/packer-templates/alpine3.10
../build.sh virtualbox  
```

After Packer finishes build the VM, you should have OVF and VMDK files available on the `output-virtualbox-iso` directory.

Note that the output directory will be different, depending on the underlying VM hypervisor used to create the VM appliance.  

You can now install the VM using the steps described in the [Virtual appliance](https://) installation section.  
