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




