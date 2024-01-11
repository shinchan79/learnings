# Templating and Dry Runs
the process is:
1. Load the entire chart, including its dependencies.
2. Parse the values.
3. Execute the templates, generating YAML.
4. Parse the YAML into Kubernetes objects to verify the data.
5. Send it to Kubernetes.

```
helm install mysite bitnami/drupal --set drupalUsername=admin
```
- Helm will locate the chart named bitnami/drupal and load that chart. If the chart is local, it will be read off of disk. If a URL is given, it will be fetched from the remote location (possibly using a plugin to assist in fetching the chart).
- Then it will transform --set drupalUsername=admin into a value that can be injected into the templates. This value will be combined with the default values in the chart’s values.yaml file. 
- Helm does some basic checks against the data. If it has trouble parsing the user input, or if the default values are corrupt, it will exit with an error. Otherwise, it will build a single big values object that the template engine can use for substitutions.
- The generated values object is created by loading all of the values of the chart file, overlaying any values loaded from files (that is, with the -f flag), and then overlaying any values set with the --set flag. In other words, --set values override settings from passed-in values files, which in turn override anything in the chart’s default values.yaml file.
- At this point, Helm will read all of the templates in the Drupal chart, and then execute those templates, passing the merged values into the template engine. Malformed templates will cause errors. But there are a variety of other situations that may cause failure here. For example, if a required value is missing, it is at this phase that an error is returned.
-  during template rendering, Helm may contact the Kubernetes API server. 
- The output of the preceding step is then parsed from YAML into Kubernetes objects. Helm will perform some schema-level validation at this point, making sure that the objects are well-formed. Then they will be serialized into the final YAML format for Kubernetes.

### The --dry-run Flag
Commands like helm install and helm upgrade provide a flag named --dry-run. When you supply this flag, it will cause Helm to step through the first four phases (load the chart, determine the values, render the templates, format to YAML). But when the fourth phase is finished, Helm will dump a trove of information to standard output, including all of the rendered templates. Then it will exit without sending the objects to Kubernetes and without creating any release records.

For example:
```
helm install --dry-run mysite bitnami/drupal --set drupalUsername=admin
```

- after the informational block, all of the rendered templates are dumped to standard output:
```
# Source: drupal/charts/mariadb/templates/test-runner.yaml
apiVersion: v1
kind: Pod
metadata:
  name: "mysite-mariadb-test-afv3u"
  annotations:
    "helm.sh/hook": test-success
spec:
  initContainers:
    - name: "test-framework"
      image: docker.io/dduportal/bats:0.4.0
...
```
- This dry-run feature provides Helm users a way to debug the output of a chart before it is sent on to Kubernetes. With all of the templates rendered, you can inspect exactly what would have been submitted to your cluster. And with the release data, you can verify that the release would have been created as you expected.
- The principal purpose of the --dry-run flag is to give people a chance to inspect and debug output before sending it on to Kubernetes.

--dry-run wasn’t written with this use case in mind, and that caused a few problems:

- --dry-run mixes non-YAML information with the rendered templates. This means the data has to be cleaned up before being sent to tools like kubectl.

- A --dry-run on upgrade can produce different YAML output than a --dry-run on install, and this can be confusing.

- It contacts the Kubernetes API server for validation, which means Helm has to have Kubernetes credentials even if it is just used to --dry-run a release.

- It also inserts information into the template engine that is cluster-specific. Because of this, the output of some rendering processes may be cluster-specific.

To remedy these problems, the Helm maintainers introduced a completely separate command: helm template.

### The helm template Command
- While --dry-run is designed for debugging, helm template is designed to isolate the template rendering process of Helm from the installation or upgrade logic.

The template command performs the first four phases (load the chart, determine the values, render the templates, format to YAML). But it does this with a few additional caveats:
- During helm template, Helm never contacts a remote Kubernetes server.
- The template command always acts like an installation.
- Template functions and directives that would normally require contacting a Kubernetes server will instead only return default data.
- The chart only has access to default Kubernetes kinds.

Kubernetes servers support built-in kinds (Pod, Service, ConfigMap, and so on) as well as custom kinds generated by custom resource definitions (CRDs). When running an install or upgrade, Helm fetches those kinds from the Kubernetes server before processing the chart.

helm template does this step differently. When Helm is compiled, it is compiled against a particular version of Kubernetes. The Kubernetes libraries contain the list of built-in kinds for that release. Helm uses that built-in list instead of a list it fetches from the API server. For this reason, Helm does not have access to any CRDs during a helm template run, since CRDs are installed on the cluster and are not included in the Kubernetes libraries.

As a result of these decisions, helm template produces consistent output run after run. More importantly, it can be run in an environment that does not have access to a Kubernetes cluster, like a continuous integration (CI) pipeline.

```
$ helm template mysite bitnami/drupal --values values.yaml --set \
drupalEmail=foo@example.com
 ---
# Source: drupal/charts/mariadb/templates/secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  name: mysite-mariadb
  labels:
    app: "mariadb"
    chart: "mariadb-7.5.1"
    release: "mysite"
    heritage: "Helm"
type: Opaque
# ... LOTS removed from here
  volumes:
    - name: tests
      configMap:
        name: mysite-mariadb-tests
    - name: tools
      emptyDir: {}
  restartPolicy: Never
```
Because Helm does not contact a Kubernetes cluster during a helm template run, it does not do complete validation of the output. It is possible that Helm will not catch some errors in this case. You may choose to use the --validate flag if you want that behavior, but in this case Helm will need a valid kubeconfig file with credentials for a cluster.

helm template is a tool for rendering Helm charts into YAML, and the --dry-run flag is a tool for debugging installation and upgrade commands without loading the data into Kubernetes.

# Learning About a Release
five phases of a Helm installation from the previous section. They were:
1.  Load the chart.
2. Parse the values.
3. Execute the templates.
4. Render the YAML.
5. Send it to Kubernetes.

- The first four phases are primarily concerned with a local representation of the data. That is, Helm is doing all of the processing on the same computer that the helm command is run on.
- During the last phase, though, Helm sends that data to Kubernetes. And then the two communicate back and forth until the release is either accepted or rejected.
- During that fifth phase, Helm must monitor the state of the release. Moreover, since many individuals may be working on the same copy of that particular application installation, Helm needs to monitor the state in such a way that multiple users can see that information.

Helm provides this feature with release records.

## Release Records
- When we install a Helm chart (with helm install), the new installation is created in the namespace you specify, or the default namespace.
- Each time we upgrade that mysite installation, a new Secret will be created to track each release. 
## Listing Releases
Status messages show up in a number of Helm commands. We already saw how pending-install appears in a --dry-run.  The list command is the best tool for quickly checking on the statuses of your releases.
## Find Details of a Release with helm get
- While helm list provides a summary view of installations, the helm get set of commands provide deeper information about a particular release.

- There are five helm get subcommands (hooks, manifests, notes, values, and all). Each subcommand retrieves some portion of the information Helm tracks for a release.

### Using helm get notes
```
helm get notes mysite
```
This output should look familiar, as helm install and helm upgrade both print the release notes at the end of a successful operation. But helm get notes provides a convenient way to grab these notes on demand. That is useful in cases where you’ve forgotten what the URL is to your Drupal site.

### Using helm get values
You can use this to see which values were supplied during the last release. In the previous section, we upgraded a WordPress installation and caused it to fail. We can see what values caused it to fail using helm get values:

```
helm get values wordpress
```
We know that revision 2 was successful, but revision 3 failed. So we can take a look at the earlier values to see what changed:
```
helm get values wordpress --revision 2
```
With this, we can see that one value was removed and one value was added. Features like this are designed to make it easier for Helm users to identify the source of errors.

This command is also useful for learning about the total state of a release’s configuration. We can use helm get values to see all of the values currently set for that release. To do this, we use the --all flag:
```
helm get values wordpress --all
```
When the --all flag is specified, Helm will get the complete computed set of values, sorted alphabetically. This is a great tool for seeing the exact state of configuration for the release.

**Note:** Although helm get values does not have a way of showing you the default values, you can see those with helm inspect values CHARTNAME. This inspects the chart itself (not the release) and prints out the documented default values.yaml file. Thus, we could use helm inspect values bitnami/wordpress to see the default configuration for the WordPress chart.

### Using helm get manifest
The last helm get subcommand that we will cover is helm get manifest. This sub-command retrieves the exact YAML manifest that Helm produced using the Chart templates:
```
$ helm get manifest wordpress
# Source: wordpress/charts/mariadb/templates/secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  name: wordpress-mariadb
  labels:
    app: "mariadb"
    chart: "mariadb-7.5.1"
    release: "wordpress"
    heritage: "Helm"
type: Opaque
...
```
One important detail about this command is that it does not return the current state of all of your resources. It returns the manifest generated from the template. 

In the preceding example, we see a Secret named wordpress-mariadb. If we query that Secret using kubectl, the metadata section looks like this:
```
$ kubectl get secret wordpress-mariadb -o yaml
apiVersion: v1
kind: Secret
metadata:
  annotations:
    meta.helm.sh/release-name: wordpress
    meta.helm.sh/release-namespace: default
  creationTimestamp: "2020-08-12T16:45:00Z"
  labels:
    app: mariadb
    app.kubernetes.io/managed-by: Helm
    chart: mariadb-7.5.1
    heritage: Helm
    release: wordpress
  managedFields:
  - apiVersion: v1
    fieldsType: FieldsV1
...
```
The output of kubectl contains the record as it currently exists in Kubernetes. There are several fields that have been added since the template output. Some (like the annotations) are managed by Helm itself, and others (like managedFields and creationTimestamp) are managed by Kubernetes.

# History and Rollbacks
- helm rollback: tells Helm to fetch the wordpress version 2 release, and resubmit that manifest to Kubernetes. A rollback does not restore to a previous snapshot of the cluster. Helm does not track enough information to do that. What it does is resubmit the previous configuration, and Kubernetes attempts to reset the resources to match.

- But if you hand-edit resources that are managed by Helm, an interesting problem may arise. Rollbacks can on occasion cause some unexpected behavior, especially if the Kubernetes resources have been hand-edited by users. Helm and Kubernetes will attempt to preserve those hand-edits if they do not conflict with the rollback. Essentially, a rollback will generate a 3-way diff between the current state of the resources, the failed Helm release, and the Helm release that you roll back to. In some cases, the generated diff may result in rolling back handmade edits, while in other cases those discrepancies will be merged. In the worst case, some handmade edits may be overwritten while other related edits are merged, leading to an inconsistency in configuration. 

## Keeping History and Rolling Back
Normally, a deletion event will destroy all release records associated with that installation. But when --keep-history is specified, you can see the history of an installation even after it has been deleted:
```
$ helm uninstall wordpress --keep-history
release "wordpress" uninstalled
```
When history is preserved, you can roll back a deleted installation:
```
$ helm rollback wordpress 4
Rollback was a success! Happy Helming!
```
# A Deep Dive into Installs and Upgrades
## The --generate-name and --name-template Flags
Helm provides the --generate-name flag for helm install
```
helm install bitnami/wordpress --generate-name
```
With the --generate-name flag, we no longer need to provide a name as the first argument to helm install. Helm generates a name based on a combination of the chart name and a timestamp. 

However, there is an additional flag that allows you to specify a naming template. The --name-template flag allows you do to something like this:
```
helm install bitnami/wordpress --generate-name \
  --name-template "foo-{{ randAlpha 9 | lower }}"
```
In this example, we used the name template foo-{{ randAlpha 9 | lower }}. This uses the Helm template engine to generate a name for you. The {{ and }} demarcate the beginning and end of a template. Inside of that template, we are calling the randAlpha function, asking for a 9-character random string from the a-z, A-Z range of characters. Then we are “piping” the results through a second function (lower) that lowercases everything.

## The --create-namespace Flag
Helm does let you override this consideration by explicitly stating that you want to create a namespace:
```
helm install drupal bitnami/drupal --namespace mynamespace --create-namespace
```
By adding --create-namespace, we have indicated to Helm that we acknowledge that there may not be a namespace with that name already, and we just want one to be created. Be sure, of course, that if you use this flag on a production instance, you have other mechanisms for enforcing security on this new namespace.

There is not an analogous --delete-namespace on helm uninstall. And the reason for this falls out of Helm’s defensiveness regarding global objects. Once a namespace is created, any number of objects may be put in the namespace, not all of them managed by Helm. And when a namespace is deleted, all of the objects inside of that namespace are also deleted. So Helm does not automatically delete namespaces that were created with --create-namespace. To delete a namespace, use kubectl delete namespace (after making sure, of course, that no important objects exist in that namespace).

## Using helm upgrade --install
Helm maintainers added the --install flag to the helm upgrade command. The helm upgrade --install command will install a release if it does not exist already, or will upgrade a release if a release by that name is found. Underneath the hood, it works by querying Kubernetes for a release with the given name. If that release does not exist, it switches out of the upgrade logic and into the install logic.

For example, we can run an install and an upgrade in sequence using exactly the same command:
```
$ helm upgrade --install wordpress bitnami/wordpress
Release "wordpress" does not exist. Installing it now.
NAME: wordpress
LAST DEPLOYED: Mon Aug 17 13:18:14 2020
NAMESPACE: default
STATUS: deployed
...
$ helm upgrade --install wordpress bitnami/wordpress
Release "wordpress" has been upgraded. Happy Helming!
NAME: wordpress
LAST DEPLOYED: Mon Aug 17 13:18:43 2020
NAMESPACE: default
STATUS: deployed
```
This command does introduce some danger, though. Helm has no way of establishing whether the name of the installation you provide to helm upgrade --install belongs to the release you intend to upgrade or just happens to be the named the same thing as the thing you want to install. Careless use of this command could result in overwriting one installation with another. 

## The --wait and --atomic Flags
The --wait flag modifies the behavior of the Helm client in a couple of ways. First, when Helm runs an installation, it remains active for a set window of time (modifiable with the --timeout flag) during which it watches Kubernetes. It polls the Kubernetes API server for information about all pod-running objects that were created by the chart. For example, DaemonSets, Deployments, and StatefulSets all create pods. So Helm with --wait will track such objects, waiting until the pods they create are marked as Running by Kubernetes.

A chart is not considered successfully installed unless (1) the Kubernetes API server accepts the manifest and (2) all of the pods created by the chart reach the Running state before Helm’s timeout expires.

Thus, installs with --wait can fail for a wide variety of reasons, including network latency, a slow scheduler, busy nodes, slow image pulls, and outright failure of a container to start.

With this in mind, though, helm install --wait is a good tool for making sure that the release is brought all the way to running. But when used in automated systems (like CI), it may cause spurious failures. One recommendation for using --wait in CI is to use a long --timeout (five or ten minutes) to ensure that Kubernetes has time to resolve any transient failures.

A second strategy is to use the --atomic flag instead of the --wait flag. This flag causes the same behavior as --wait unless the release fails. Then, instead of marking the release as failed and exiting, it performs an automatic rollback to the last successful release. In automated systems, the --atomic flag is more resistent to outages, since it is less likely to have a failure as its end result. (Keep in mind, though, that there is no assurance that a rollback will be successful.)

Just as --wait can mark a release as a failure for transitive reasons that may be resolved by Kubernetes itself, --atomic may trigger an unnecessary rollback for the same reasons. Thus, it is recommended to use longer --timeout durations for --atomic, especially when used with CI systems.

## Upgrading with --force and --cleanup-on-fail
The --force flag modifies the behavior of Helm when it upgrades a resource that manages pods (like Pod, Deployment, and StatefulSet). Normally, when Kubernetes receives a request to modify such objects, it determines whether it needs to restart the pods that this resource manages. For example, a Deployment may run five replicas of a pod. But if Kubernetes receives an update to the Deployment object, it will only restart those pods if certain fields are modified.

The --cleanup-on-fail flag will attempt to fix this situation. On failure, it will request deletion on every object that was newly created during the upgrade. Using it may make it a little harder to debug (especially if the failure was a result of the newly created object), but it is useful if you do not want to risk having unused objects hanging around after a failure.