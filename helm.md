# Chapter 1: Introducing Helm
- package manager for k8s
## Cloud native ecosystem
### Containers and Microservices
- smaller discrete standalone services are preferable to large monolithic services that do everything
- Services that wish to access the data will contact that service over (typically) a representational state transfer (REST) API. And, using JavaScript Object Notation (JSON) over HTTP, these other services will query and update data.
#### Microservices
-  a microservice is responsible for handling only one small part of the overall application’s processing.
#### Containers
- A virtual machine runs an entire operating system in an isolated environment on a host machine. A container, in contrast, has its own filesystem, but is executed in the same operating system kernel as the host.
#### Container images and registries
Registry info:
- Name
- Tag
- Digest: Sometimes it is important to pull a very specific version of an image. Since tags are mutable, there is no guarantee that at any given time a tag refers to exactly a specific version of the software. So registries support fetching images by digest, which is a SHA-256 or SHA-512 digest of the image’s layer information.
#### Schedules and K8s 
- Kubernetes introduced two concepts that set it apart from the crowd: declarative infrastructure and the reconciliation loop.
#### Declarative infrastructure
- declaratively: We tell the scheduler (Kubernetes) what our desired state is, and Kubernetes takes care of converting that declarative statement into its own internal procedures.
#### The reconciliation loop
- In a reconciliation loop, the scheduler says “here is the user’s desired state. Here is the current state. They are not the same, so I will take steps to reconcile them.”
- The user wants storage for the container. Currently there is no storage attached. So Kubernetes creates a unit of storage and attaches it to the container.
- The container needs a public network address. None exists. So a new address is attached to the container.
- Different subsystems in Kubernetes work to fulfill their individual part of the user’s overall declaration of desired state.
- Eventually, Kubernetes will either succeed in creating the user’s desired environment or will arrive at the conclusion that it cannot realize the user’s desires. Meanwhile, the user takes a passive role in observing the Kubernetes cluster and waiting for it to achieve success or mark the installation as failed.

#### From containers to pods, services, deployments, etc.
- Kubernetes doesn’t necessarily treat the container as the unit of work. Instead, Kubernetes introduces a higher-level abstraction called a pod.
- A pod describes not just a container, but one or more containers (as well as their configuration and requirements) that together perform one unit of work:

```
apiVersion: v1 (1)
kind: Pod
metadata:
    name: example-pod
spec:
    containers: (2)
    - image: "nginx:latest"
      name: example-nginx
```

(1) The first two lines define the Kubernetes kind (v1 Pod).

(2) A pod can have one or more containers.

- Most frequently, a pod only has one container. But sometimes they have containers that do some preconfiguration for the main container, exiting before the main container comes online. These are called `init containers`.
- Other times, there are containers that run alongside the main container and provide auxiliary services. These are called `sidecar containers`.
- `Pod`: describes what configuration the container or containers need (such as network ports or filesystem mount points).
- Configuration information in Kubernetes may be stored in ConfigMaps or, for sensitive information, Secrets.
- `Pod`'s definition may then relate those `ConfigMaps` and `Secrets` to environment variables or files within each container.
- As Kubernetes sees those relationships, it will attempt to attach and configure the configuration data as described in the Pod definition:

```
apiVersion: v1 (1)
kind: ConfigMap
metadata:
    name: configuration-data
data: (2)
    backgroundColor: blue
    title: Learning Helm
```
(1) In this case, we have declared a v1 ConfigMap object.

(2) Inside of data, we declare some arbitrary name/value pairs.

- A Secret is structurally similar to a ConfigMap, except that the values in the data section must be Base64 encoded.
- Pods are linked to configuration objects (like ConfigMap or Secret) using volumes. In this example, we take the previous Pod example and attach the Secret above:

```
apiVersion: v1
kind: Pod
metadata:
    name: example-pod
spec:
    volumes: (1)
    - name: my-configuration
      configMap:
        name: configuration-data (2)
    containers:
    - image: "nginx:latest"
      name: example-nginx
      env: (3)
        - name: BACKGROUND_COLOR (4)
          valueFrom:
            configMapKeyRef:
                name: configuration-data (5)
                key: backgroundColor (6)
```

(1) The volumes section tells Kubernetes which storage sources this pod needs.

(2) The name configuration-data is the name of our ConfigMap we created in the previous example.

(3) The env section injects environment variables into the container.

(4) The environment variable will be named BACKGROUND_COLOR inside of the container.

(5) This is the name of the ConfigMap it will use. This map must be in volumes if we want to use it as a filesystem volume.

(6) This is the name of the key inside the data section of the ConfigMap.

- A Deployment describes an application as a collection of identical pods. The Deployment is composed of some top-level configuration data as well as a template for how to construct a replica pod.
- We can attach a HorizontalPodAutoscaler (another Kubernetes type) and configure that to scale our pod based on resource usage.
- when we upgrade the application, the Deployment can employ various strategies for incrementally upgrading individual pods without taking down our entire application:

```
apiVersion: apps/v1 (1)
kind: Deployment
metadata:
    name: example-deployment
    labels:
        app: my-deployment
spec:
    replicas: 3 (2)
    selector:
        matchLabels:
            app: my-deployment
    template: (3)
        metadata:
            labels:
                app: my-deployment
        spec:
            containers:
            - image: "nginx:latest"
              name: example-nginx
```

(1) This is an apps/v1 Deployment object.

(2) Inside of the spec, we ask for three replicas of the following template.

(3) The template specifies how each replica pod should look.

-  A Service is a persistent network resource (sort of like a static IP) that persists even if the pod or pods attached to it go away.
-  Kubernetes `Pods` can come and go while the network layer can continue to route traffic to the same `Service` endpoint.
-  a Service is an abstract Kubernetes concept, behind the scenes it may be implemented as anything from a routing rule to an external load balancer:

```
apiVersion: v1 (1)
kind: Service
metadata:
  name: example-service
spec:
  selector:
    app: my-deployment (2)
  ports:
    - protocol: TCP (3)
      port: 80
      targetPort: 8080
```
(1) The kind is v1 Service.

(2) This Service will route to pods with the app: my-deployment label.

(3) TCP traffic to port 80 of this Service will be routed to port 8080 on the pods that match the app: my-deployment label.

## Helm's goal
- For example, the WordPress CMS system can be run inside of Kubernetes. But typically it would need at least a `Deployment` (for the WordPress server), a `ConfigMap` for configuration and probably a `Secret` (to keep passwords), a few Service objects, a `StatefulSet` running a database, and a few role-based access control (RBAC) rules. Already, a Kubernetes description of a basic WordPress site would span thousands of lines of YAML. At the very core of Helm is this idea that all of those objects can be packaged to be installed, updated, and deleted together.

When we wrote Helm, we had three main goals:
- Make it easy to go from “zero to Kubernetes”
- Provide a package management system like operating systems have
- Emphasize security and configurability for deploying applications to Kubernetes

### From Zero to K8s

- invert the learning cycle: instead of requiring users to start with basic examples and try to construct their own applications, we wanted to provide users with ready-made production-ready examples. Users could install those examples, see them in action, and then learn how Kubernetes worked.
- Helm isn’t just a learning tool. It is a package manager.

### Package Management
- Kubernetes is like an operating system.
- Instead of executing programs, it executes containers.

Package management metaphor to Helm:
- Helm provides package repositories and search capabilities to find what Kubernetes applications are available.
- Helm has the familiar install, upgrade, and delete commands.
- Helm defines a method for configuring packages prior to installing them.
- Helm has tools for seeing what is already installed and how it is configured.

In Kubernetes, a namespace is an arbitrary grouping mechanism that defines a boundary between the things inside the namespace and the things outside. There are many different ways to organize resources with namespaces, but oftentimes they are used as a fixture to which security is attached. These are just a few ways that Kubernetes differs from traditional operating systems. 

### Security, Reusability, and Configurability

Our third goal with Helm was to focus on three “must haves” for managing applications in a cluster:

- Security
- Reusability
- Configurability

A user should be able to `verify` that a package came from a trustworthy source (and was not tampered with), `reuse` the same package multiple times, and `configure` the package to fit their needs.

Helm can only provide the right tools for package authors and hope that these creators choose to realize these three “must haves.”

#### Security

- The package comes from a trusted source.
- The network connection over which the package is pulled is secured.
- The package has not been tampered with.
- The package can be easily inspected so the user can see what it does.
- The user can see what configuration the package has, and see how different inputs impact the output of a package.

Helm provides a provenance feature to establish verification about a package’s origin, author, and integrity. Helm supports Secure Sockets Layer/Transport Layer Security (SSL/TLS) for securely sending data across the network. And Helm provides dry-run, template, and linting commands to examine packages and their possible permutations.

#### Reusability
- Helm charts are the key to reusability.
- A chart provides a pattern for producing the same Kubernetes manifests. But charts also allow users to provide additional configuration.
- Helm provides patterns for storing configuration so that the combination of a chart plus its configuration can even be done repeatedly.
- Helm encourages Kubernetes users to package their YAML into charts so that these descriptions can be reused.
- Helm was constructed so that all Kubernetes distributions could share the same package manager, and (with very, very few exceptions) the same packages as well. When there are differences between two different Kubernetes distributions, charts can accommodate this using templates coupled with configuration.

#### Configurability
- Helm provides tools to configure packages at installation time, and to reconfigure installations during upgrades.
- Helm is a package manager. Another class of software handles configuration management. This class of software, typified by Puppet, Ansible, and Chef, focuses on how a given piece of software (often packaged) is specifically configured for its host environment. Its responsibility is to manage configuration changes over time.
- Helm was not designed to be a configuration management tool
- Package management is typically confined to implementing three verbs: install, upgrade, and delete. Configuration management is a higher-order concept that focuses on managing an application or applications over time. This is sometimes called “day-two ops.”
- While Helm did not set out to be a configuration management tool, it is sometimes used as one. Organizations rely upon Helm not just to install, upgrade, and delete, but also to track changes over time, to track configuration, and to determine whether an application as a whole is running. Helm can be stretched this way, but if you want a strong configuration management solution, you may want to leverage other tools in the Helm ecosystem like Helmfile, Flux, and Reckoner

## Helm Architecture
### Kubernetes Resources

- All Kubernetes resource definitions share a common subset of elements.
- The following manifest uses a Deployment to illustrate the main structural elements of a resource definition:
```
apiVersion: apps/v1 (1)
kind: Deployment (2)
metadata: (3)
    name: example-deployment (4)
    labels: (5)
        some-name: some-value
    annotations: (6)
        some-name: some-value
# resource-specific YAML
```
(1) The API family and version for this resource.

(2) The kind of resource. Combined with apiVersion, we get the “resource type”.

(3) The metadata section contains top-level data about the resource.

(4) A name is required for almost every resource type.

(5) Labels are used to give Kubernetes query-able “handles” to your resources.

(6) Annotations provide a way for authors to attach their own keys and values to a resource.

a resource type in Kubernetes is composed of three pieces of information:
- API group (or family): Several base resource types like Pod and ConfigMap omit this name.
- PI version: Expressed as a v, followed by a major version and an optional stability marker. For example, v1 is a stable “version 1,” while v1alpha indicates an unstable “version 1 alpha 1.”
- Resource kind: The (capitalized) name of the specific resource within the API group.

### Charts
- In Helm’s vocabulary, a package is called a chart.
- A chart plots the way a Kubernetes application should be installed.
- A chart contains a file called `Chart.yaml` that describes the chart. It has information about the chart version, the name and description of the chart, and who authored the chart.
- A chart contains `templates` as well. These are Kubernetes manifests (like we saw earlier in this chapter) that are potentially annotated with templating directives.
- A chart may also contain a `values.yaml` file that provides default configuration. This file contains parameters that you can override during installation and upgrade.
  
When you see a Helm chart, though, it may be presented in either unpacked or packed form.
- An unpacked Helm chart is just a directory. Inside, it will have a Chart.yaml, a values.yaml, a templates/ directory, and perhaps other things as well.
- A packed Helm chart contains the same information as an unpacked one, but it is tarred and gzipped into a single file.

An unpacked chart is represented by a directory with the name of the chart. For example, the chart named `mychart` will be unpacked into a directory named `mychart/`. In contrast, a packed chart has the name and version of the chart, as well as the `tgz` suffix: `mychart-1.2.3.tgz`.

Charts are stored in chart repositories. Helm knows how to download and install charts from repositories.
