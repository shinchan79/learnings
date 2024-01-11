# Install Helm
```
$ curl -fsSL -o get_helm.sh \
https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
$ chmod 700 get_helm.sh
$ ./get_helm.sh
```
# Working with Kubernetes Clusters
Most common workflow for starting out with Helm:
1.Add a chart repository.
2. Find a chart to install.
3. Install a Helm chart.
4. See the list of what is installed.
5. Upgrade your installation.
6. Delete the installation.

# Adding a Chart repository
- A Helm chart is an individual package that can be installed into your Kubernetes cluster. 
- A Helm chart repository is simply a set of files, reachable over the network, that conforms to the Helm specification for indexing packages.
[the Artifact Hub ](https://artifacthub.io/)https://artifacthub.io/

To get started, we will install the popular Drupal content management system. This makes a good example chart because it exercises many of Kubernetes’ types, including Deployments, Services, Ingress, and ConfigMaps.

```
helm repo add bitnami https://charts.bitnami.com/bitnami
```
# Searching a Chart Repository
```
helm search repo drupal
```
```
helm search repo content
```
By default, Helm tries to install the latest stable release of a chart, but you can override this behavior and install a specific verison of a chart. Thus it is often useful to see not just the summary info for a chart, but exactly which versions exist for a chart:
```
helm search repo drupal --versions
```
A chart version is the version of the Helm chart. The app version is the version of the application packaged in the chart. Helm uses the chart version to make versioning decisions, such as which package is newest.

# Installing a Package
- At very minimum, installing a chart in Helm requires just two pieces of information: the name of the installation and the chart you want to install.
- One chart may have many installations. When we run the helm install command, we need to give it an installation name as well as the chart name.
```
$ kubectl create ns first
$ kubectl create ns second
$ helm install --namespace first mysite bitnami/drupal
$ helm install --namespace second mysite bitnami/drupal
```
