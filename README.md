# Kubernetes ReadOnly SA Admin and Namespace bound CRUD Admin Creator Scripts

## Introduction

This repo contains shell scripts that create resources within the target cluster that will be used to generate 2 `kubeconfig.yml` files that need to be shared with the team at Appsecco.

The shell scripts in this repo will create the following two types of accounts

1. A global cluster ReadOnly service account - [kubernetes-readonly-admin.sh](kubernetes-readonly-admin.sh)
2. A service account bound to a specific namespace with CRUD privileges in that namespace - [kubernetes-sa-pod-creator.sh](kubernetes-sa-pod-creator.sh)

## Pre-requisites

1. A kubernetes administrator or user with the ability to create resources at cluster level, is required to run the shell script as it invokes `kubectl` with the user credentials.
2. Also ensure your kubeconfig cluster context is set correctly, because the script will create resources in the current context. You can verify this using `kubectl cluster-info`.

## Usage

Before running any of the commands below, make sure your kubectl is pointing to the correct cluster. You can verify this using `kubectl cluster-info`. 

Only proceed if the output of `kubectl cluster-info` matches your expectations of the target cluster.

### Kubeconfig SA ReadOnly Account

You can pass the shell script to cURL directly using the raw GitHub URL. The script creates ReadOnly resources in the target cluster.

```bash
curl -sS https://raw.githubusercontent.com/appsecco/kubernetes-ptaas-scripts/main/kubernetes-readonly-admin.sh | bash
```

A file called `kubeconfig-sa-readonly-TIMESTAMP` will be created in a folder called `appsecco-k8s-assessment-kubeconfigs`. For example - `kubeconfig-sa-readonly-29-04-2024-16-54-28.yml`

### Kubeconfig SA Specific Namespace Pod Creator

You can pass the shell script to cURL directly using the raw GitHub URL. The script creates ReadOnly resources in the target cluster.

```bash
curl -sS https://raw.githubusercontent.com/appsecco/kubernetes-ptaas-scripts/main/kubernetes-sa-pod-creator.sh | bash
```

A file called `kubeconfig-sa-pod-creator-TIMESTAMP.yml` will be created in a folder called `appsecco-k8s-assessment-kubeconfigs`. For example - `kubeconfig-sa-pod-creator-29-04-2024-18-49-38.yml`

Share these yml files with Appsecco.
