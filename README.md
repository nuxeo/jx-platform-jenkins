# Jenkins Docker Image for the Jenkins X Instances of the Platform Team

This repository allows to build:

- The `nuxeo/platform-jenkinsx` image to be used in the `platform` Jenkins X team.
- The `nuxeo/platform-staging-jenkinsx` image to be used in the `platform-staging` Jenkins X team.

See how the image is pulled in the [Jenkins X environment description](https://github.com/nuxeo/jx-platform-env/blob/master/values.yaml).

The [staging](staging/Dockerfile) image is built from the [base](Dockerfile) one and simply overrides some plugin configuration.

## Plugins

The Jenkins plugins installed in the image are listed in [plugins.txt](plugins.txt).

## Configuration

The configuration of Jenkins and its plugins relies on the [Jenkins Configuration as Code Plugin](https://github.com/jenkinsci/configuration-as-code-plugin/).

It's described in the [config](config) directory and overridden in [staging/config](staging/config) for the staging image.

Basically, the staging image has an empy configuration for:

- The GitHub plugin, to avoid jobs setting a GitHub status.
- The JIRA plugin, to avoid jobs setting a JIRA comment.

## Link with the Jenkins X Environment

When opening a pull request (A) in the current repository, a new version of the Jenkins image is built with the following pattern:

```shell
x.y.z-PR-a-b
```

Then, you can and open a draft pull request (B) in the [jx-platform-env](https://github.com/nuxeo/jx-platform-env/) repository to use this new version in [values.yaml](https://github.com/nuxeo/jx-platform-env/blob/master/values.yaml):

```yaml
jenkins:
  Master:
    ...
    ImageTag: x.y.z-PR-a-b
```

This will trigger an upgrade of the `platform-staging` team with the new version of the Jenkins image, to be able to validate it.

When the `platform-staging` team is validated, the (B) pull request can be safely closed and the (A) pull request can be merged. This builds a release version of the Jenkins image and opens a pull request (C) in the [jx-platform-env](https://github.com/nuxeo/jx-platform-env/) repository to use this release version.

The (C) pull request can then be merged to trigger an update of the `platform` team with the release version of the Jenkins image.
