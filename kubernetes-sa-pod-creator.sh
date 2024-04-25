#!/bin/bash

# Created by Riyaz Walikar @Appsecco
# Copyright Appsecco Inc. 2024

GREEN='\033[0;32m'
COLOR_OFF='\033[0m'

echo "Appsecco Script to generate an admin kubeconfig for a specific namespace called k8s-security-assessment"
echo "Creates resources and saves the kubeconfig-sa-pod-creator.yml that needs to be shared with Appsecco"
echo
read -p "Press enter to continue ...."
# Setup of Kubernetes resources from here
echo -e "${GREEN}Create a namespace called k8s-security-assessment"
cat <<EOF1 | kubectl apply -f - 
apiVersion: v1
kind: Namespace
metadata:
  name: k8s-security-assessment
EOF1

echo -e "${GREEN}Create a role with admin cap called 'appsecco-pod-creator-role'${COLOR_OFF}"
# Create a role with admin capabilities to a specific namespace.
cat <<EOF2 | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
 name: appsecco-pod-creator-role
 namespace: k8s-security-assessment
rules:
- apiGroups:
  - ""
  resources:
  - '*'
  verbs:
  - '*'
- apiGroups:
  - extensions
  resources:
  - '*'
  verbs:
  - '*'
- apiGroups:
  - apps
  resources:
  - '*'
  verbs:
  - '*'
- apiGroups:
  - "*"
  resources:
  - '*'
  verbs:
  - '*'
EOF2

echo -e "${GREEN}Create a rolebinding called 'appsecco-pod-creator-role-binding' to bind the admin role to a service account${COLOR_OFF}"
# Create a rolebinding to bind the role to a service account
cat <<EOF3 | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
 name: appsecco-pod-creator-role-binding
 namespace: k8s-security-assessment
subjects:
- kind: ServiceAccount
  name: pod-creator-sa
  namespace: k8s-security-assessment
roleRef:
  kind: Role
  name: appsecco-pod-creator-role
  apiGroup: rbac.authorization.k8s.io
EOF3

echo -e "${GREEN}Add a service account called 'pod-creator-sa'${COLOR_OFF}"
# Add a service account
cat <<EOF4 | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: pod-creator-sa
  namespace: k8s-security-assessment
secrets:
- name: pod-creator-sa-secret-token
EOF4

echo -e "${GREEN}Create a secret called 'pod-creator-sa-secret-token', new in Kubernetes > v1.24${COLOR_OFF}"

# Create a secret, new after v1.24
cat <<EOF5 | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: pod-creator-sa-secret-token
  namespace: k8s-security-assessment
  annotations:
    kubernetes.io/service-account.name: pod-creator-sa
type: kubernetes.io/service-account-token
EOF5

# Generate config manifest for the cluster
echo 
echo

export CLUSTER_NAME=$(kubectl config current-context)
export CLUSTER_SERVER=$(kubectl cluster-info | grep --color=never "control plane" | awk '{print $NF}')
export CLUSTER_SA_SECRET_NAME=$(kubectl -n k8s-security-assessment get sa pod-creator-sa -o jsonpath='{ $.secrets[0].name }')
export CLUSTER_SA_TOKEN_NAME=$(kubectl -n k8s-security-assessment get secret | grep --color=never $CLUSTER_SA_SECRET_NAME | awk '{print $1}')
export CLUSTER_SA_TOKEN=$(kubectl -n k8s-security-assessment get secret $CLUSTER_SA_TOKEN_NAME -o "jsonpath={.data.token}" | base64 -d)
export CLUSTER_SA_CRT=$(kubectl -n k8s-security-assessment get secret $CLUSTER_SA_TOKEN_NAME -o "jsonpath={.data['ca\.crt']}")

cat <<EOF5 > kubeconfig-sa-pod-creator.yml
apiVersion: v1
kind: Config
users:
- name: appsecco-ns-pod-creator
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
    user: appsecco-ns-pod-creator
  name: k8s-security-assessment-pod-crud
current-context: k8s-security-assessment-pod-crud
EOF5

echo -e "All done! kubeconfig-sa-pod-creator.yml generated. Share this file with Appsecco."