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
$ helm install --namespace first mysite bitnami/drupal

$ kubectl create ns second
$ helm install --namespace second mysite bitnami/drupal
```
- When working with namespaces and Helm, you can use the --namespace or -n flags to specify the namespace you desire.

## Configuration at Installation Time
- There are several ways of telling Helm which values you want to be configured. The best way is to create a YAML file with all of the configuration overrides. 
- Now we have a file (conventionally named values.yaml) that has all of our configuration. Since it is in a file, it is easy to reproduce the same installation. You can also check this file into a version control system to track changes to your values over time. The Helm core maintainers consider it a good practice to keep your configuration values in a YAML file. 
- It is important to keep in mind, though, that if a configuration file has sensitive information (like a password or authentication token), you should take steps to ensure that this information is not leaked.

Both helm install and helm upgrade provide a --values flag that points to a YAML file with value overrides:
```
helm install --namespace first mysite bitnami/drupal --values values.yaml
```
- You can specify the --values flag multiple times. Some people use this feature to have “common” overrides in one file and specific overrides in another.

- There is a second flag that can be used to add individual parameters to an install or upgrade. The --set flag takes one or more values directly. They do not need to be stored in a YAML file:

```
helm install --namespace first mysite bitnami/drupal --set drupalUsername=admin,drupalPassword=password
```
- Configuration parameters can be structured. That is, a configuration file may have multiple sections. 

The Drupal chart, for example, has configuration specific to the MariaDB database. These parameters are all grouped into a mariadb section. Building on our previous example, we could override the MariaDB database name like this:
```
drupalUsername: admin
drupalEmail: admin@example.com
mariadb:
  db:
    name: "my-database"
```
Subsections are a little more complicated when using the --set flag. You will need to use a dotted notation: --set mariadb.db.name=my-database. This can get verbose when setting multiple values.

- In general, Helm core maintainers suggest storing configuration in values.yaml files (note that the filename does not need to be “values”), only using --set when absolutely necessary. 

# Listing Your Installations
```
helm list
helm list --namespace first
helm list --all-namespaces
```
# Upgrading an Installation
- An installation is a particular instance of a chart in your cluster. When you run helm install, it creates the installation. To modify that installation, use helm upgrade.

This is an important distinction to make in the present context because upgrading an installation can consist of two different kinds of changes:
- You can upgrade the version of the chart
- You can upgrade the configuration of the installation
The two are not mutually exclusive; you can do both at the same time. 

- a release: is a particular combination of configuration and chart version for an installation.

When a new version of a chart comes out, you may want to upgrade your existing installation to use the new chart version. For the most part, Helm tries to make this easy:
```
helm repo update (1)
helm upgrade mysite bitnami/drupal (2)
```
(1)     Fetch the latest packages from chart repositories.
(2)     Upgrade the mysite release to use the latest version of bitnami/drupal.

If you would prefer to stay on a particular version of a chart, you can explicitly declare this:
```
helm upgrade mysite bitnami/drupal --version 7.1.1
```
## Configuration Values and Upgrades
```
$ helm install mysite bitnami/drupal --values values.yaml (1)
$ helm upgrade mysite bitnami/drupal (2)
```
(1)     Install using a configuration file.
(2)     Upgrade without a configuration file.

The installation will use all of the configuration data supplied in values.yaml, but the upgrade will not. 

Helm core maintainers suggest that you provide consistent configuration with each installation and upgrade. To apply the same configuration to both releases, supply the values on each operation:
```
helm install mysite bitnami/drupal --values values.yaml (1)
helm upgrade mysite bitnami/drupal --values values.yaml (2)
```
(1) Install using a configuration file.
(2) Upgrade using the same configuration file.

One of the reasons we suggest storing configuration in a values.yaml file is so that this pattern is easy to reproduce. 

```
helm upgrade mysite bitnami/drupal --reuse-values
```
The --reuse-values flag will tell Helm to reload the server-side copy of the last set of values, and then use those to generate the upgrade. This method is okay if you are always just reusing the same values. However, the Helm maintainers strongly suggest not trying to mix --reuse-values with additional --set or --values options. 

# Uninstalling an Installation
```
helm uninstall mysite
```
Note that this command does not need a chart name (bitnami/drupal) or any configuration files. It simply needs the name of the installation. 

Like install, list, and upgrade, you can supply a --namespace flag to specify that you want to delete an installation from a specific namespace:
```
helm uninstall --namespace first mysite
# Deleting a Namespace
kubectl delete ns first
```
Deletion can take time. Larger applications may take several minutes, or even longer, as Kubernetes cleans up all of the resources. During this time, you will not be able to reinstall using the same name.

## How Helm Stores Release Information
When we first install a chart with Helm (such as with helm install mysite bitnami/drupal), we create the Drupal application instance, and we also create a special record that contains release information. By default, Helm stores these records as Kubernetes Secrets (though there are other supported storage backends).

```
# Get Secret
kubectl get secret
```
When we run the command helm uninstall mysite, it will load the latest release record for the mysite installation. From that record, it will assemble a list of objects that it should remove from Kubernetes. Then Helm will delete all of those things before returning and deleting the four release records

-  delete the application, but keep the release records:
```
helm uninstall --keep-history
```