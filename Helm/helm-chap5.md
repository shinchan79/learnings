# The Template Syntax
## Actions
- Logic, control structures, and data evaluations are wrapped by `{{` and `}}`. These are called actions.
- When the curly brackets are used to start and stop actions they can be accompanied by a `-` to remove leading or trailing whitespace. The following example illustrates this:
```
{{ "Hello" -}} , {{- "World" }}
```
- The generated output of this is “Hello,World.” The whitespace has been removed from the side with the - up to the next nonwhitespace character.
- There needs to be an ASCII whitespace between the - and the rest of the action. For example, {{–12}} evaluates to –12 because the - is considered part of the number instead of the bracket.
## Information Helm Passes to Templates
-  Inside the template that object is represented as a `.` (i.e., a period). It is referred to as a dot.
-  The properties on `.Values` are specific to each chart based entirely on the values in the values.yaml file and those passed into a chart. The properties on `.Values` do not have a schema and vary from chart to chart.

In addition to the values, information about the release, can be accessed as properties of `.Release`. This information includes:

-  `.Release.Name`: The name of the release.
-  `.Release.Namespace`: Contains the namespace the chart is being released to.
-  `.Release.IsInstall`: Set to `true` when the release is a workload being installed.
-  `.Release.IsUpgrade`: Set to `true` when the release is an upgrade or rollback.
-  `.Release.Service`: Lists the service performing the release. When Helm installs a chart, this value is set to `"Helm"`. Different applications, those that build on Helm, can set this to their own value.

The information in the Chart.yaml file can also be found on the data object at `.Chart`. This information does follow the schema for the Chart.yaml file. This includes:

- `.Chart.Name`: Contains the name of the chart.
- `.Chart.Version`: The version of the chart.
- `.Chart.AppVersion`: The application version, if set.
- `.Chart.Annotations`: Contains a key/value list of annotations.

The names differ in that they start with a lowercase letter in Chart.yaml but start with an uppercase letter when they are properties on the `.Chart` object.

If you want to pass custom information from the Chart.yaml file to the templates, you need to use annotations. The `.Chart` object only contains the fields from the Chart.yaml file that are in the schema. You can’t add new fields to pass them in, but you can add your custom information to the annotations.

Helm provides some data about the capabilities of the cluster as properties of `.Capabilities`. Helm interrogates the cluster you are deploying an application into to get this information. This includes:

- `.Capabilities.APIVersions`: Contains the API versions and resource types available in your cluster. You will learn how to use this in a little bit.
- `.Capabilities.KubeVersion.Version`: The full Kubernetes version.
- `.Capabilities.KubeVersion.Major`: Contains the major Kubernetes version. Because Kubernetes has not been incrementing the major version, this is set to `1`.
- `.Capabilities.KubeVersion.Minor`: The minor version of Kubernetes being used in the cluster.

The capabilities information provided to templates being processed when `helm template` is run is default information Helm already knows about compliant Kubernetes clusters. Helm works this way because the `template` command is expected to only be used for processing templates and doing so in a manner that does not accidentally leak information from a configured cluster.

Charts can contain custom files. For example, you can have a configuration file you want to pass to an application through a `ConfigMap` or `Secret` as a file in the chart. The nonspecial files in a chart that are not listed in the `.helmignore` file are available on `.Files` within templates. This will not give you access to the template files.

The final piece of data passed into the template is details about the current template being executed. Helm passes in:
- `.Template.Name`: Contains the namespaced filepath to the template. For example, in the anvil chart from Chapter 4 a path would be `anvil/templates/deployment.yaml`.
- `.Template.BasePath`: The namespaced path to the templates directory of the current chart (e.g., anvil/templates).

When the scope changes, properties like `.Capabilities.KubeVersion.Minor` will become inaccessible at that location. When template execution begins, `.` is mapped to `$` and `$` does not change. Even when the scope changes, `$.Capabilities.KubeVersion.Minor` and other passed-in data is still accessible. You will find `$` is typically only used when the scope has changed.

## Pipelines
A pipeline is a sequence of commands, functions, and variables chained together. The value of a variable or the output of a function is used as the input to the next function in a pipeline. The output of the final element of a pipeline is the output of the pipeline.
```
character: {{ .Values.character | default "Sylvester" | quote }}
```
There are three parts to this pipeline, each separated by a `|`. The first is `.Values.character`, which is a calculated value of character. This is either the value of character from the values.yaml file or one passed in when the chart is being rendered by `helm install`, `helm upgrade`, or `helm template`. This value is passed as the last argument to the `default` function. If the value is empty, `default` will use the value of “Sylvester” in its place. The output of default is passed as an input to `quote`, which ensures the value is wrapped in quotation marks. The output of `quote` is returned from the action.

Pipelines are a powerful tool you can use to transform data you want in the template. They can be used for a variety of purposes, from creating powerful transformations to protecting against simple bugs.

## Template Functions
-  Functions provide a means to transform the data you have into the format you need rendered or to generate data where none exists.
-  Most of the functions are provided by Helm and are designed to be useful when building charts. The functions range from the simple, like the `indent` and `nindent` functions used to indent output, to the complex ones that are able to reach into the cluster and get information on current resources and resource types.
- Many of the functions found in Helm templates are provided by a library named Sprig: https://masterminds.github.io/sprig/
-  The `toYaml` function turns the data into YAML.
-  `nindent`: This function adds a newline at the start of the text it receives and then indents each line.
-  The `indent` function does not add a newline at the beginning.
-  In addition to `toYaml`, Helm has functions to convert data to JSON with `toJson` and to TOML with `toToml`. `toYaml` is often used when creating Kubernetes manifests, while `toJson` and `toToml` are more often used when creating configuration files to be passed to applications through `Secrets` and `ConfigMaps`.
-  The order of arguments passed into a function is intentional. When pipelines are used, the output of one function is passed as the last argument to the next function in the pipeline.
-  There are more than a hundred functions available to use within templates. These include functions for handling math, dictionaries and lists, reflection, hash generation, date functions, and much more.

## Methods
- Helm also includes functions that detect the capabilities of a Kubernetes cluster and methods to work with files.
- The `.Capabilities` object has the method `.Capabilities.APIVersions.Has`, which takes in a single argument for the Kubernetes API or type you want to check the existence of. It returns either true or false to let you know if that resource is available in your cluster. You can check for a group and version such as `batch/v1` or a resource type such as `apps/v1/Deployment`.

The other place you will find methods is on `.Files`. It includes the following methods to help you work with files:

- `.Files.Get name`: Provides a means of getting the contents of the file as a string. `name`, in this case, is the name including filepath from the root of the chart.
- `.Files.GetBytes`: Similar to `.Files.Get` but instead of returning a string, the file is returned as an array of bytes. In Go terms, this is a byte slice (i.e., []byte).
- `.Files.Glob`: Accepts a glob pattern and returns another `files` object containing only the files whose names match the pattern.
- `.Files.AsConfig`: Takes a files group and returns it as flattened YAML suitable to include in the `data` section of a Kubernetes `ConfigMap` manifest. This is useful when paired with `.Files.Glob`.
- `.Files.AsSecrets`: Similar to `.Files.AsConfig`. Instead of returning flattened YAML it returns the data in a format that can be included in the data section of a Kubernetes Secret manifest. It’s Base64 encoded. This is useful when paired with `.Files.Glob`. For example, `{{ .Files.Glob("mysecrets/**").AsSecrets }}`.
- `.Files.Lines`: Has an argument for a filename and returns the contents of the file as an array split by newlines (i.e., `\n`).

To illustrate the use of these, the following template is from an example chart. It reads all the files in the config subdirectory of a chart and embeds each one in a `Secret`:
```
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "example.fullname" . }}
type: Opaque
data:
{{ (.Files.Glob "config/*").AsSecrets | indent 2 }}
```
As the following example output from Helm shows, each file can be found at its own key in the file:
```
apiVersion: v1
kind: Secret
metadata:
  name: myapp
type: Opaque
data:
  jetpack.ini: ZW5hYmxlZCA9IHRydWU=
  rocket.yaml: ZW5hYmxlZDogdHJ1ZQ==
```
## Querying Kubernetes Resources In Charts
The `lookup` template function is able to return either an individual object or a list of objects. This function returns an empty response when commands that do not interact with the cluster are executed.

The following example looks up a `Deployment` named runner in the anvil namespace and makes the metadata annotations available:
```
{{ (lookup "apps/v1" "Deployment" "anvil" "runner").metadata.annotations }}
```
There are four arguments passed into the `lookup` function:
- `API version`: This is the version of any object, whether included in Kubernetes or installed as part of an add-on. Examples of this look like `"v1"` and `"apps/v1"`.
- `Kind of object`: This can be any resource type.
- `Namespace to look for the object in`: This can be left blank to look in all namespaces you have access to or for global resources such as Namespace.
- `Name of the resource you are looking for`: This can be left blank to return a list of resources instead of a specific one.

When a list of resources is returned, you will need to loop over the results to access the data on each of the individual objects. Where a lookup for an object returns a `dict`, a lookup for a list of objects returns a `list`. 

When a list is returned, the objects are on the `items` property:
```
{{ (lookup "v1" "ConfigMap" "anvil" "").items }}
```
This example returns all the `ConfigMaps` in the anvil namespace, assuming you have access to the namespace.

You should be careful when using this function. For example, it will return different results when used as part of a dry run as opposed to when an upgrade is run. A dry run does not interact with a cluster, so this function will return no results. When an upgrade is run it will return results.

## if/else/with
Go templates have `if` and `else` statements along with something similar but mildly different called `with`. `if` and `else` work the same way they do in most programming languages.

To illustrate an if statement, we can look at a pattern from the chart generated using the `helm create` command. In that chart the values.yaml file contains a section on `ingress` with an enabled property. It looks like:
```
ingress:
  enabled: false
```
In the ingress.yaml file that creates the `Ingress` resource for Kubernetes, the first and last lines are for the `if` statement that implements this:
```
{{- if .Values.ingress.enabled -}}
...
{{- end }}
```
In this case, the `if` statement evaluates whether the output of the pipeline following the `if` statement is true or false. If it’s true, the content inside is evaluated. In order to know where the end of the block is, you need an end statement. This is important because indentation or more typical brackets could be part of the material you want rendered.

`if` statements can have an `else` statement that is executed if the `if` statement evaluates to false. The following example prints a YAML comment to output when `Ingress` is not enabled:

```
{{- if .Values.ingress.enabled -}}
...
{{- else -}}
# Ingress not enabled
{{- end }}
```
Sometimes you will want to have multiple elements evaluated in an `if` statement by combining them with an `and` or an `or` statement. 

```
{{- if and .Values.characters .Values.products -}}
...
{{- end }}
```
In this case `and` is implemented as a function with two arguments. That means and comes before either of the two items being used. The same idea applies to the use of `or`, which is also implemented as a function.

When one of the elements to be used with `and` or `or` is a function or pipeline, you can use parentheses.
```
{{- if or (eq .Values.character "Wile E. Coyote") .Values.products -}}
...
{{- end }}
```
The output of the equality check, implemented using the `eq` function, is passed as the first argument to `or`. The parentheses enable you to group elements together to build more complex logic.

`with` is similar to `if` with the caveat that the scope within a with block changes. 
```
  {{- with .Values.ingress.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
```
If the value passed into `with` is empty, the block is skipped. If the value is not empty, the block is executed and the value of `.` inside the block is `.Values.ingress.annotations`. In this situation, the scope within the block has changed to the value checked by `with`.

Just like with `if` statements, `with` can have an accompanying `else` block that you can use when the value is empty.

## Variables
Once a variable is created for one type, such as a string, you cannot set the value to another type, such as an integer.

```
{{ $var := .Values.character }}
```
in this case a new variable is created and the value of `.Values.character` is assigned to it. This variable can be used elsewhere; for example:
```
character: {{ $var | default "Sylvester" | quote }}
```
When you assign a new value to the existing variable, you use `=`. For example:
```
{{ $var := .Values.character }}
{{ $var = "Tweety" }}
```
Variable handling is reflective of the syntax and style used in the Go programming language. It follows the same semantics through the use of `:=`, `=`, and typing.

## Loops

The loop syntax in templates is a little different than that in many programming languages. Instead of `for` loops, there are `range` loops that can be used to iterate over dicts (also known as maps) and lists.

```
# An example list in YAML
characters:
  - Sylvester
  - Tweety
  - Road Runner
  - Wile E. Coyote

# An example map in YAML
products:
  anvil: They ring like a bell
  grease: 50% slippery
  boomerang: Guaranteed to return
```
Within Helm templates you can create your own dictionaries and lists using the `dict` and `list` functions.

There are two ways you can use the `range` function. The following example iterates over the characters while changing the scope, which is the value of `.`:
```
characters:
{{- range .Values.characters }}
  - {{ . | quote }}
{{- end }}
```
In this case range iterates over each item in the list and sets the value of `.` to the value of each item in the list as Helm iterates over the item. In this example, the value is passed to quote in the pipeline. The scope for `.` is changed in the block up to `end`, which acts as the closing bracket or statement for the loop.

The output of above snippet:
```
characters:
  - "Sylvester"
  - "Tweety"
  - "Road Runner"
  - "Wile E. Coyote"
```
The other way to use `range` is by having it create new variables for the key and value. This will work on both lists and dicts:
```
products:
{{- range $key, $value := .Values.products }}
  - {{ $key }}: {{ $value | quote }}
{{- end }}
```
The `$key` variable contains the key in a map or dict and a number in a list. `$value` contains the value. If this is a complex type, such as another dict, that will be available as the `$value`. The new variables are in scope up to the end of the `range` block, which is signified by the corresponding `end` action. The output of this example is:
```
products:
  - anvil: "They ring like a bell"
  - boomerang: "Guaranteed to return"
  - grease: "50% slippery"
```

# Named Templates
- You can create your own templates, which Helm won’t automatically render, and use them within templates of Kubernetes manifests.

The following template selection contains the selector labels used to generate specifications and selector sections in the generated template. The name, anvil, is from the chart generated:
```
{{/*
Selector labels (1)
*/}}
{{- define "anvil.selectorLabels" -}} (2)
app.kubernetes.io/name: {{ include "anvil.name" . }} (3)
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}} (4)
```

(1) A comment prior to defining the function. Comments in actions open with /* and are closed by */.

(2) You define a template with a `define` statement followed by the name for the template.

(3) The content of a template is just like the content of any other template.

(4) The definition for a template is closed through an end statement that matches to the `define` statement.

This template includes several useful things you should consider using in your own templates:

1. A comment describing the template. This is ignored when the template is rendered but is useful in the same way code comments are.
2. The name is namespaced, using `.` as the separator, to include the chart name.  Using a namespace on a template name enables the use of library charts and avoids collisions on dependent charts.
3. The `define` and `end` calls use actions that remove whitespace before and after them so that their use does not add extra lines to the final output YAML.

This template is called in the `spec` section of resources, such as the Deployment in the anvil chart:
```
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      {{- include "anvil.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "anvil.selectorLabels" . | nindent 8 }}
```
The `matchLabels` section here is immutable, so it cannot be changed and it looks for the `labels` in the `template` section.

- The `template` function is a basic function for including another template. It cannot be used in pipelines.
- `include` function that works in a similar manner but can be used in pipelines.

The `include` function takes two arguments:
- The first is the name of the template to call. This needs to be the full name including any namespace.
- The second is the data object to pass. This can be one you create yourself, using the dict function, or it can be all or part of the global object used within the template. In this case the whole global object is passed in.


user-defined templates that call other user-defined templates:
```
{{/*
Common labels
*/}}
{{- define "anvil.labels" -}}
helm.sh/chart: {{ include "anvil.chart" . }}
{{ include "anvil.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}
```
Because these labels are mutable, there are useful labels included here that will change for various reasons. So as not to repeat the labels used for selectors, which are useful here as well, those labels are included by calling the function that generates them.

Another situation you may find yourself in where a named template would be useful is when you want to encapsulate complex logic. 

To illustrate this idea, consider a chart where you want to be able to pass in a container version as a tag, a digest, or fall back on the application version as a default. The part of the `Pod` specification that accepts the container image, including the version, is a single line. To provide all three of those options you need many lines of logic:

```
{{- define "anvil.getImage" -}}
{{- if .Values.image.digest -}}
{{ .Values.image.repository }}@{{ .Values.image.digest }}
{{- else -}}
{{ .Values.image.repository }}:
{{- .Values.image.tag | default .Chart.AppVersion }}
{{- end -}}
{{- end -}}
```
This new `getImage` template is able to handle a digest, tag, and default to the application version if neither of the other two are present:
- First, a digest is checked for and used. A digest is immutable, and it is the most precise method to specify the revision of an image to use.
- If no digest is passed in, a tag is checked. Tags are pointers to digests and can be changed. If no tag is found, the `AppVersion` is used as a tag.

In the template for the `Deployment`, the image would be referenced using the new function:
```
image: "{{ include "anvil.getImage" . }}"
```
Templates can act like functions in a software program. They are a useful way for you to break off complex logic and have shared functionality.

# Structuring Your Templates for Maintainability
To aid in creating maintainable templates that are easy to navigate, the Helm maintainers recommend several patterns. These patterns are useful for a few reasons:
1/ You may go long periods without making structural changes to the templates in a chart and then come back to it. Being able to quickly rediscover the layout will make the processes faster.

2/ Other people will look at the templates in charts. This may be team members who create the chart or those that consume it. Consumers can, and sometimes do, open up a chart to inspect it prior to installing it or as part of a process to fork it.

3/ When you debug a chart, which is covered in the next section, it is easier to do so with some structure in the templates.

- The first pattern is that each Kubernetes manifest should be in its own template file and that file should have a descriptive name. For example, name your template deployment.yaml if there is a single deployment. If you have the case of multiple manifests of the same type, such as the case when you have a database deployed using primaries and replicas, you use names such as statefulset-primary.yaml and statefulset-replica.yaml.
- A second guideline is to put the named templates, which you include in your own templates, into a file named _helpers.tpl. Because these are essentially helper templates for your other templates, the name is descriptive. As mentioned earlier, the _ at the start of the name causes it to bubble up to the top of directory listings so you can easily find it among your templates.
- When you use the helm create command to start a new chart, the contents of the templates it starts with, by default, will already follow these patterns.

# Debugging Templates
## Dry Run
The commands to install, upgrade, roll back, and uninstall Helm charts all have a flag to initiate a dry run and simulate the process but not fully execute on that process. This is accomplished using the `--dry-run` flag on these commands.

Helm would render the templates, check the templates to make sure what would be sent to Kubernetes was well formed, and would then send it to output. 

If have error, eg: 
```
Error: parse error at (anvil/templates/deployment.yaml:4): unexpected "}" in operand
```
The information here outlines a hint where to look for the issue. It includes:
- The file where the error is occurring. anvil/templates/deployment.yaml, in this case.
- The line number in the file where the error occurred. Here it is line 4.
- An error message with a hint about the problem. The error message will often not display what the issue is, but rather where the parser is having an issue. In this case a single } is unexpected.

Helm will check for more than errors in the template syntax. It will also check the syntax of the output. To illustrate this, in the same deployment.yaml file remove the apiVersion: at the start of it. The beginning of the file will now look like:
```
apps/v1
kind: Deployment
```
Performing a dry-run install will produce the following output:
```
Error: YAML parse error on anvil/templates/deployment.yaml: error converting
YAML to JSON: yaml: line 2: mapping values are not allowed in this context
```

Helm is also able to validate the schemas of Kubernetes resources. This is accomplished because Kubernetes provides schema definitions for its manifests. To illustrate this, change the  `apiVersion` in the deployment.yaml to be `foo`:
```
foo: apps/v1
kind: Deployment
```
Performing a dry-run install will produce the following output:
```
Error: unable to build kubernetes objects from release manifest: error
validating "": error validating data: apiVersion not set
```
The deployment is no longer valid, and Helm was able to provide specific feedback on what is missing. In this case, the `apiVersion` property is not set.

The `helm template` command provides a similar experience but without the full debugging feature set. The `template` command does turn the template commands into YAML. At this point it will provide an error if the generated YAML cannot be parsed. What it won’t do is validate the YAML against the Kubernetes schema. The `template` command won’t warn you if `apiVersion` is turned to foo. This is due to Helm not communicating with a Kubernetes cluster to get the schema for validation when the `template` command is used.

## Getting Installed Manifests
There are times where you install an application into a cluster and something else changes the manifests afterwards. This leads to differences between what you declared and what you have running. One example of this is when a service mesh automatically adds a sidecar container to the `Pods` created by your Helm charts.

You can get the original manifests deployed by Helm using the `helm get manifest` command. This command will retrieve the manifests for a release as they were when Helm installed the release. It is able to retrieve this information for any revision of a release still available in the history, as found using the `helm history` command.

**Note: Service mesh:**
A service mesh is a layer of infrastructure used to manage service-to-service communications. In Kubernetes, a service mesh uses a sidecar proxy container added to `Pods` to handle the communication. Many service mesh platforms offer the ability to automatically inject the sidecar proxies by altering the configuration of manifests.

## Linting Charts
- Some of the problems you will encounter don’t show up as violations of the API specification and aren’t problems in the templates. 
- For example, Kubernetes resources are required to have names that can be used as part of a domain name. This restricts the characters that you can use in names and their length. The OpenAPI schema provided by Kubernetes does not provide enough information to detect names that will fail when sent to Kubernetes.
- The lint command is able to detect problems like this and tell you where they are.

To illustrate this you can modify the anvil chart to add `Wile` to the end of the Deployment name in deployment.yaml:
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "anvil.fullname" . }}-Wile
```
Running `helm lint` anvil will produce an error informing you of the issue:
```
$ helm lint anvil
==> Linting anvil
[ERROR] templates/deployment.yaml: object name does not conform to Kubernetes
naming requirements: "test-release-anvil-Wile"

Error: 1 chart(s) linted, 1 chart(s) failed
```



