Link code repo: https://github.com/masterminds/learning-helm/tree/main/chapter6
# Chart Dependencies
- Charts can have dependencies on other charts. This enables the encapsulation of a service in a chart, the reuse of charts, and the use of multiple charts together.
- Dependencies are specified in the Chart.yaml file. The following is the `dependencies` section in the Chart.yaml file for a chart named rocket:
```
dependencies:
  - name: booster (1)
    version: ^1.0.0 (2)
    repository: https://raw.githubusercontent.com/Masterminds/learning-helm/main/
      chapter6/repository/ (3)
```
(1) The name of the dependent chart within the repository.

(2) A version range string for the chart.

(3) The repository to retrieve the chart from.

The repository field is where you specify the chart repository location to pull the dependency from. You can specify this in one of the following two ways:
- A URL to the Helm repository.
- To the name of a repository you have set up using the `helm repo add` command. This name needs to be preceded by an @ and wrapped in quotes (e.g., "@myrepo").

A full URL is typically used to specify the location. This will ensure the same dependency is retrieved in every environment the chart is used in.

If you are going to package up your chart as a chart archive, you need to lock and fetch dependencies before packaging.

To resolve the latest version of the dependency within the specified range and to retrieve it, you can use the following command:
```
$ helm dependency update .
```
- The Chart.lock file is managed by Helm. Changes from users will be overwritten the next time `helm dep up` (the shorthand syntax) is run. 
- Once Helm knows the specific version to use, it downloads the dependent chart and puts it into the charts subdirectory. It is important for the dependent charts to be in the charts directory because this is where Helm will get their contents from to render the templates. Charts can be in the charts directory in either their archive or directory form. 
- If you have a Chart.lock file but no contents in the charts directory, you can rebuild the charts directory by running the command helm dependency build. This will use the lock file to retrieve the dependencies at their already determined versions.
- Once you have dependencies, Helm will render their resources when you run commands like helm install or helm upgrade.
- In the main chart’s values.yaml file, you can create a new section with the name of the dependent chart. In this section you can set the values you want passed in. You only need to set the ones you want changed because the dependent charts included in the values.yaml file will serve as the default values.

In the values.yaml file for the rocket chart there is a section that reads:
```
booster:
  image:
    tag: 9.17.49
```

- Helm knows this section is for the booster chart. In this case it sets the image tag to a specific value. Any of the values in the dependent chart can be set this way. When commands like helm install are run, you can use the flags to set values (e.g., --set) of the dependencies as well as those of the main chart.
- If you have two dependencies on the same chart you can optionally use the `alias` property in the Chart.yaml file. This property goes on each dependency you want to use an alternative name for next to the `name`, `version`, and other properties. With `alias` you can give each dependency a unique name that you can reference elsewhere, such as in the values.yaml file.

## Conditional Flags for Enabling Dependencies
When you want to control if a single feature is enabled or disabled through a dependency, you can use the `condition` property on a dependency:
```
dependencies:
  - name: booster
    version: ^1.0.0
    condition: booster.enabled
    repository: https://raw.githubusercontent.com/Masterminds/learning-helm/main/
      chapter6/repository/
```
The dependency has a condition key with a value that tells Helm where to look in the values to know if it should be enabled or disabled. In the values.yaml file the corresponding section is:
```
booster:
  enabled: false
```
When you have multiple features you want to enable or disable that involve dependencies, you can use the `tags` property. Like `condition`, this property sits alongside the `name` and `version` when describing a dependency. It contains a list of tags for a dependency:
```
dependencies:
  - name: booster
    tags:
      - faster
    version: ^1.0.0
    repository: https://raw.githubusercontent.com/Masterminds/learning-helm/main/
      chapter6/repository/
  - name: rocket
    tags:
      - faster
    version: ^1.0.0
    repository: https://raw.githubusercontent.com/Masterminds/learning-helm/main/
      chapter6/repository/
```
Here you will see two dependencies with a `tags` section. The `tags` are a list of related tags. In the chart’s values.yaml file you use a tags property:
```
tags:
  faster: false
```
`tags` is a property with a special meaning. The values here tell Helm to disable dependencies with the tag faster by default. They can be enabled when the chart’s user passes a true value into the chart as it’s being installed or upgraded.

## Importing Values from Child to Parent Charts
### The exports property

The exports property is a special top-level property in a values.yaml file. When a child chart has declared an export property, its contents can be imported directly into a parent chart.

For example, consider the following from a child chart’s values.yaml file:
```
exports:
  types:
    foghorn: rooster
```
When the parent chart declares the child as a dependency, it can import from the exports like the following:
```
dependencies:
  - name: example-child
    version: ^1.0.0
    repository: https://charts.example.com/
    import-values:
      - types
```
Within the parent’s calculated values the types are now accessible at the top level. In YAML that would be equivalent to:
```
foghorn: rooster
```





