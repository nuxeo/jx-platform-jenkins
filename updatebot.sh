#!/bin/bash

VERSION=$1

jx step create pr regex --regex "^(?m)\s+Image: .*\/platform-jenkinsx\s+ImageTag: (.*)$" \
  --version ${VERSION} \
  --files values.yaml \
  --repo https://github.com/nuxeo/jx-platform-env.git
