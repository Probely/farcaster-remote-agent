# Probely Agent for Internal Scans

## Overview

This document will guide you through the installation process of the Probely
Remote Agent on your on-premises network.

The Remote Agent connects Probely to (the parts that you choose of) your internal network.
This broadens Probely's vulnerability scanning capabilities to internal applications.
After being installed on-premises, the Agent creates an encrypted and authenticated tunnel,
in which traffic flows securely between Probely and your network.

The Agent is open-source, and the code is freely available on this repository.

The following diagram shows an example network topology depicting an on-premises network,
the Remote Agent, the Remote Agent Hub (where remote agents connect to) and Probely's cloud.
  
![Image](https://probely.com/assets/images/Farcaster-RemoteAgent.png)

## Security considerations

Installing third-party software components on a network carries an inherent risk.
Being security professionals ourselves, we are very aware of it.
That is why Probely is designed with a security mindset from the ground up - 
the Remote Agent is no exception to this.

We designed the Remote Agent following a set of principles that we believe will meet 
your security expectations.  

**Transparency**

* No black boxes: all code is open source, with a permissive license.
* In addition to the source code, the instructions and tools to build the Agent are provided.
This enables you to ensure that the Agent running on your infrastructure has not been tampered with.
* You have complete control over the appliance and can change it however you see fit.

**Least privilege**

* Probely has no administrative access to the appliance.
* Services are containerized and run with minimal privileges.
* The appliance supports custom firewall rules so that network access can be further restricted.
* The appliance does not listen on any public Internet port, in order to reduce its attack surface.
Instead, it creates an outbound connection to Probely’s network.
* The Agent has been hardened in many ways, from custom hardened Linux kernel settings to proper
cryptographic algorithms choices that meet the state-of-the-art security recommendations.

**Simplicity**

* We are firm believers that simplicity enables security. The Agent follows simple design decisions, and uses industry-standard components whenever possible.
* We keep network requirements to a minimum. This means, for example, that public IP addresses, complex firewall rules, and other typical network requirements are unnecessary or minimized.
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

1. **Using a pre-built VM "appliance"**. The VM contains the required components to run the Agent.
This may be a simpler approach if you have a virtualization solution already running.
(Hyper-V, KVM, VirtualBox, VMWare, among others)

1. **Running the containers yourself**.
This option may be preferable if you have the infrastructure to support running
Docker containers. (e.g., a Kubernetes cluster)

1. **Building the VM and containers from source**.

### Option 1: Virtual appliance

The Remote Agent is packaged as a ZIP archive containing an Open Virtual Format (OVF) file and a Virtual Machine Disk (VMDK).

You should be able to import the Agent on any modern virtualization solution.
However, we are happy to provide you with a custom Agent VM for your specific needs.

To install the Remote Agent, please follow these steps:

* Download the most recent Virtual Appliance from the [Releases](https://github.com/Probely/farcaster-remote-agent/releases) page. The VM archive name is `probely-remote-agent-vm-<version>.zip`

* Import the OVF file into your virtualization solution

* Allocate the required system resources for the Agent VM, as defined in the [System Resources](#system-resources) section

* After the VM starts, use the default Remote Agent credentials to log in (user: `probely`, password: `changeme`)
You can log into the VM on the local console, or via SSH (IP is assigned via DHCP).
The SSH server accepts connections from private IP address ranges only.
This is done to mitigate potential compromises, if an unconfigured appliance is accidentally exposed to the Internet.
The allowed SSH client IP ranges are:

  * `10.0.0.0/8`
  * `172.16.0.0/12`
  * `192.168.0.0/16`

* After logging on the VM for the first time, you must change the default password.
Be sure to choose a strong password. Ideally, you should disable password login via SSH,
and enforce authentication using public keys or certificates.
This is outside the scope of this document, but we can assist you in doing so through the support channels.

* You should have been given a `probely-agent-<id>.run` file, which is an installer script tailored to your specific Agent. If you do not have the installer script, please contact Probely's support team. If you want to know how the installer is built and what it does, please refer to the Installer section.

* To configure the Agent, run the following commands on the Remote Agent Virtual Appliance:
```bash
chmod +x ./probely-agent-<id>.run
sudo ./probely-agent-<id>.run
```

* After running the installer, the Agent should link-up with Probely's cloud.
To make sure that the connection is working properly, run the following command:
```bash
sudo probely-farcaster-status
```

* You can now start internal targets using Probely.

### Option 2: Docker containers

We provide an example `docker-compose.yml` file, that may be used as-is with [Docker Compose](https://docs.docker.com/compose/).

You can use the `docker-compose.yml` file as a reference to deploy the Remote Agent to a container orchestrator, such as [Kubernetes](https://kubernetes.io/). If you need help setting the Agent on a Kubernetes cluster, please contact Probely's support team.

Both [Docker](https://docs.docker.com/v17.09/engine/installation/) and [Docker Compose](https://docs.docker.com/compose/install/) must be installed for these instructions to work. Please follow this procedure on a VM with those requirements met.

You should have been given a `probely-agent-<id>.run` file, which is an installer script tailored to your specific Agent. If you do not have the installer script, please contact Probely's support team. If you want to know how the installer is built and what it does, please refer to the Installer section.

* Run the following commands to extract the Agent keys and configuration files:
```bash
chmod +x ./probely-agent-<id>.run
./probely-agent-<id>.run --noexec --target ./agent-installer
```

* Deploy and run the Agent:
```bash
./setup.sh --local <path-to-deploy-agent>
cd <path-to-deploy-agent>
docker-compose up -d
```

* After starting the containers, the Agent should link-up with Probely's cloud.
To make sure that the connection is working properly, run:
```bash
docker logs farcaster-tunnel.
```

You should see a message similar to `Alocated port [0-9]+ for remote forward to gateway`

### Option 3: Building from source

* Start by checking the code out from the repository:
```bash
git clone git@github.com:Probely/farcaster-remote-agent.git
```

Unless otherwise specified, these instructions must be run on the repository root.

### Containers
* To build the containers, run the following command:

```bash
make docker
```

Afterwards, you should push the container images to a Docker image registry.

Remember to reference your own Docker image registry on any `docker-compose.yml` file or Kubernetes pod descriptor you configure. This ensures that your custom-built Agent container images are used instead of the default ones provided by Probely.

### Installer
You must rebuild the installer to ensure that it uses your own custom-built Docker images, and any other setting you may wish to change.

The installer build script expects a "key bundle" to exist. A key bundle is a set of keys that allow the Agent to connect to Probely’s cloud, and to authenticate Probely’s servers. 

* First, extract the Agent keys. We do this by extracting the keys from the original installer:
```
chmod +x ./probely-agent-<id>.run
./probely-agent-<id>.run --noexec --target ./tmp/agent-installer
```

* Create the key bundle:
```bash
tar -zcpvf ./tmp/<id>.tar.gz -C ./tmp/agent-installer/keys .
```

The installer build script reads the AGENT_DOCKER_IMAGE environment variable. If set, it will use it to find the Agent Docker images - e.g. your custom-built Docker images. If unset, Probely’s default Docker images are used.

The build script will ask you for a password to secure the keys. Please choose a strong password.

* Create the new installer:
```bash
AGENT_DOCKER_IMAGE=<image_url> ./installer/make-installer.sh ./tmp/<id>.tar.gz
```

The installer should be available in `installer/target/probely-agent-<id>.run`.

### Virtual machine
We use [Packer](https://packer.io) to build the Agent VM. Currently, we support the following builder types:

* VirtualBox
* VMWare
* XEN
* KVM

If you need to build the Agent VM image on a virtualization platform different from the ones we currently support, please contact Probely's support.

For example, to build the Agent VM using the VirtualBox builder, follow these steps:

* Install [Packer](https://www.packer.io/intro/getting-started/install.html)
* Run these commands:
```bash
cd vm/packer-templates/alpine3.10
../build.sh virtualbox
```

After Packer finishes building the VM, you should have OVF and VMDK files available on the `output-virtualbox-iso` directory. Note that the output directory name and contents may differ, depending on the underlying VM builder you chose to create the VM appliance.

You can now install the VM using the steps described in the Virtual appliance installation section. If applicable, remember to use your custom installer.
