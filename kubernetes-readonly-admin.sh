#!/bin/bash

# Created by Riyaz Walikar @Appsecco
# Copyright Appsecco Inc. 2024

GREEN='\033[0;32m'
COLOR_OFF='\033[0m'

echo "Appsecco Script to generate ReadOnly Admin kubeconfig"
echo "Creates readonly resources and saves the kubeconfig-sa-readonly.yml that needs to be shared with Appsecco"
echo
read -p "Press enter to continue ...."
# Setup of Kubernetes readonly resources from here
echo -e "${GREEN}Create a readonly clusterrole called 'appsecco-cluster-reader'${COLOR_OFF}"
# Create a readonly clusterrole
cat <<EOF1 | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
 name: appsecco-cluster-reader
rules:
- apiGroups:
  - ""
  resources:
  - '*'
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - extensions
  resources:
  - '*'
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - apps
  resources:
  - '*'
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - "*"
  resources:
  - '*'
  verbs:
  - get
  - list
  - watch
EOF1

echo -e "${GREEN}Create a clusterrolebinding called 'appsecco-global-cluster-reader' to bind the readonly clusterrole to service account${COLOR_OFF}"
# Create a clusterrolebinding to bind the readonly clusterrole to service account
cat <<EOF2 | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
 name: appsecco-global-cluster-reader
subjects:
- kind: ServiceAccount
  name: appsecco-cluster-admin-readonly
  namespace: default
roleRef:
  kind: ClusterRole
  name: appsecco-cluster-reader
  apiGroup: rbac.authorization.k8s.io
EOF2

echo -e "${GREEN}Add a service account called 'appsecco-cluster-admin-readonly' to the cluster-admin-readonly clusterrole${COLOR_OFF}"
# Add a service account to the cluster-admin-readonly clusterrole
cat <<EOF3 | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: appsecco-cluster-admin-readonly
secrets:
- name: appsecco-cluster-admin-readonly-secret-token
EOF3

echo -e "${GREEN}Create a secret called 'appsecco-cluster-admin-readonly-secret-token', new in Kubernetes > v1.24${COLOR_OFF}"

# Create a secret, new after 1.24
cat <<EOF4 | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: appsecco-cluster-admin-readonly-secret-token
  annotations:
    kubernetes.io/service-account.name: appsecco-cluster-admin-readonly
type: kubernetes.io/service-account-token
EOF4

# Generate config manifest for the cluster
echo 
echo

export foldername="appsecco-k8s-assessment-kubeconfigs"
mkdir $foldername
export suffix="$(date +%d-%m-%Y-%H-%M-%S)"

export CLUSTER_NAME=$(kubectl config current-context)
export CLUSTER_SERVER=$(kubectl cluster-info | grep --color=never "control plane" | awk '{print $NF}')
export CLUSTER_SA_SECRET_NAME=$(kubectl -n default get sa appsecco-cluster-admin-readonly -o jsonpath='{ $.secrets[0].name }')
export CLUSTER_SA_TOKEN_NAME=$(kubectl -n default get secret | grep --color=never $CLUSTER_SA_SECRET_NAME | awk '{print $1}')
export CLUSTER_SA_TOKEN=$(kubectl -n default get secret $CLUSTER_SA_TOKEN_NAME -o "jsonpath={.data.token}" | base64 -d)
export CLUSTER_SA_CRT=$(kubectl -n default get secret $CLUSTER_SA_TOKEN_NAME -o "jsonpath={.data['ca\.crt']}")

cat <<EOF5 > $foldername/kubeconfig-sa-readonly-$suffix.yml
apiVersion: v1
kind: Config
users:
- name: appsecco-readonly-user
  user:
    token: $CLUSTER_SA_TOKEN
clusters:
- cluster:
    certificate-authority-data: $CLUSTER_SA_CRT
    server: $CLUSTER_SERVER
  name: $CLUSTER_NAME
contexts:
- context:
    cluster: $CLUSTER_NAME
    user: Appsecco-readonly-user
  name: k8s-security-assessment
current-context: k8s-security-assessment
EOF5

echo -e "All done! $foldername/kubeconfig-sa-readonly-$suffix.yml generated. Share this file with Appsecco."
