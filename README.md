# GitOps with ArgoCD on OpenShift 4

This repository aims to be an evolving demo of GitOps tools and practices on OpenShift Container Platform.

The GitOps tool that is at the centre of this demo is [Argo CD](https://argoproj.github.io/argo-cd/).

## What's in the Demo?

1. **Argo CD**: Installed using the [Argo CD Operator](https://operatorhub.io/operator/argocd-operator).
2. **Secret management**: [Bitnami Sealed Secrets Operator and kubeseal](https://github.com/bitnami-labs/sealed-secrets).
3. **Image regisry**: [Quay.io](https://quay.io) as an external container image repository with vulnerability scanning.
4. **CI/CD**: CI/CD tools installed and managed using GitOps practices, including Jenkins, SonarQube, Nexus, and Selenium Grid.
5. **Pipeline**: Application development pipeline integrated into an application git repository.

## Prerequisites

1. Fork this repository into your own GitHub account.
2. Create a free [Quay.io](https://quay.io) account.
3. `kubeseal` cli toool on the path of the machine that will be running the setup script.


## Run the Setup Script

1. Run `./deploy-argocd.sh` to deploy Argo CD to the cluster.
2. Run `./deploy-sealedsecrets.sh` to deploy Bitnami Sealed Secrets to the cluster.
3. Run `./update-files.sh` to update files with your own git repo/branch and routes.


This will:
1. Update yaml files with your own github repo and branch, as well as update any routes with your cluster apps url.
2. Install ArgoCD into a new `argocd` namesapce and print the default admin password to the console.
3. Install Bitnami Sealed Secrets (using Argo CD that you just installed!) and download the public key to use with `kubeseal`.
4. Create some `SealedSecret` custom resources with your Quay credentials for use with Jenkins and for image pull secrets.
5. Commit and push all this to your github repo and branch.

Once this is done, your cluster will have Argo CD up and running as well as Bitnami Sealed Secrets.  You will also be ready to create more sealed secrets with `kubeseal`.

Woot!

## Add Argo CD Projects and Applications

### Projects

First, install a few `projects`.  These are ArgoCD projects which is a nice way to organize Argo CD applications.
```
oc create -f gitops/projects -n argocd
```

To add CI/CD tools (Jenkins, SonarQube, Nexus):
```
oc create -f gitops/applications/dc1/cicd -n argocd
```

To install an example Java app that uses the CI/CD tools:
```
oc create -f gitops/applications/dc1/apps/petclinic -n argocd
```
