# Cloudsmith Buildkite Plugin

Interact with [Cloudsmith](https://cloudsmith.io) package
repositories.

Currently only provides the ability to promote (move) packages from
one repository to another.

Expects a `CLOUDSMITH_API_KEY` to be present in the environment.

## Promote Packages

Move one or more packages from one repository to another.

This takes place in a `command` hook, and is thus expected to run in its own Buildkite job.

As detailed in [the Cloudsmith
documentation](https://help.cloudsmith.io/docs/move-a-package),
promotion requires a unique identifier for the package you want to
move. This ends up looking something like `iwrWp7mk8kAP`. Rather than
requiring users to provide that to the plugin, you can specify your
package in terms of name and version. These are then fed into a
`cloudsmith list packages` query to resolve the unique identifier
required for the promotion.

```yaml
steps:
  - label: ":cloudsmith: Promote Packages for Release"
    plugins:
      - grapl-security/cloudsmith#v0.1.0:
          promote:
            org: my-company
            from: testing
            to: releases
            packages:
              frontend: v1.2.3
              backend: v2.3.4
```

As an alternative to specifying packages explicitly, you can pass in a
file containing the packages. This can be useful for more dynamic
workflows.

```yaml
steps:
  - label: ":cloudsmith: Promote Packages for Release"
    plugins:
      - grapl-security/cloudsmith#v0.1.0:
          promote:
            org: my-company
            from: testing
            to: releases
            packages_file: validated_packages.json
```

Here, `validated_packages.json` has the following contents:

```json
{
    "frontend": "v1.2.3",
    "backend": "v2.3.4"
}
```

The structure of this file is the same as that of the `packages` key,
just expressed as JSON.

This configuration has the same effect as the one above that used
`packages` instead of `packages_file`, but provides more flexibility
for how the packages are specified.

You must specify either `packages` or `packages_file`; you cannot have
both, but you must have one.

By default, the plugin will move packages from one repository to the
other, removing them from the source repository in the process. If you
need to retain the packages in the source repository, you can specify
an `action` of `copy`:

```yaml
steps:
  - label: ":cloudsmith: Promote Packages for Release"
    plugins:
      - grapl-security/cloudsmith#v0.1.0:
          promote:
            org: my-company
            from: testing
            to: releases
            action: copy
            packages:
              frontend: v1.2.3
              backend: v2.3.4
```

## Docker Image

For flexibility, this plugin uses a containerized Cloudsmith CLI,
meaning that you can use this plugin directly, without having to
install the CLI on your Buildkite agents.

Since there is not currently an official Cloudsmith CLI container
image, we [build one ourselves](./Dockerfile) and make it available
for this plugin. The image can be overridden, however, if you wish to
use a different one; see the `Configuration` section below.

## Configuration

### image (optional, string)

The container image with the Cloudsmith CLI binary that the plugin
uses. Any container used should have the `cloudsmith` binary as its
entrypoint.

Defaults to `docker.cloudsmith.io/grapl/releases/cloudsmith-cli`.

### tag (optional, string)

The container image tag the plugin uses.

Defaults to `latest`.

### promote (required, object)

The configuration object for the promotion operation.

#### action (optional, string)
Defines the semantics of the promotion operation with respect to the
source repository; "move" removes the package(s) from the source
repository, while "copy" leaves a copy behind. In both cases, the
package(s) will be present in the destination repository.

Must be either "move" or "copy"; defaults to "move".

#### org (required, string)

The Cloudsmith organization to interact with.

#### from (required, string)

The repository you are promoting packages out of.

#### to (required, string)

The repository you are promoting packages into.

#### packages (optional, object)

A flat object mapping package names to package versions. These are the
packages that will be promoted.

Cannot be used if `packages_file` is used.

#### packages_file (optional, string)

The path to a file containing a JSON object with the same mapping
described in `packages` above.

Cannot be used if `packages` is used.

## Building

Requires `make`, `docker`, and `docker-compose`.

Running `make` will run all formatting, linting, and testing.

### Testing Considerations

Part of exercising this plugin involves pushing a test container to
one repository (`testing-stage1`) and promoting it to another
(`testing-stage2`). These two repositories exist in our Cloudsmith
account solely for this purpose, and this repository is the only thing
that will be putting anything into them.
