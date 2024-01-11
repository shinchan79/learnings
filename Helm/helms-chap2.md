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
