# (C) Copyright 2019 Nuxeo (http://nuxeo.com/) and others.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
ARG JENKINS_IMAGE_VERSION=2.263.2-lts
ARG JENKINS_X_IMAGE_VERSION=0.0.81

# ------------------------------------------------------------------------
# Build stage
FROM gcr.io/jenkinsxio/jenkinsx:${JENKINS_X_IMAGE_VERSION} as jenkins-x

# ------------------------------------------------------------------------
# Target stage
FROM jenkins/jenkins:${JENKINS_IMAGE_VERSION}

ARG BUILD_TAG
ARG DESCRIPTION="Jenkins master image for the Platform team"
ARG JENKINS_IMAGE_VERSION
ARG JENKINS_X_IMAGE_VERSION
ARG SCM_REF
ARG SCM_REPOSITORY=git@github.com:nuxeo/jx-platform-jenkins.git
ARG VERSION

LABEL org.nuxeo.build-tag=$BUILD_TAG
LABEL org.nuxeo.description=$DESCRIPTION
LABEL org.nuxeo.scm-ref=$SCM_REF
LABEL org.nuxeo.scm-repository=$SCM_REPOSITORY
LABEL org.nuxeo.version=$VERSION
LABEL org.nuxeo.version.jenkins=$JENKINS_IMAGE_VERSION
LABEL org.nuxeo.version.jenkinsx=$JENKINS_X_IMAGE_VERSION

USER root
RUN apt-get update && apt-get install -y vim
USER jenkins

ENV JAVA_OPTS "$JAVA_OPTS -Dhudson.security.csrf.DefaultCrumbIssuer.EXCLUDE_SESSION_ID=true"
ENV CASC_JENKINS_CONFIG=/usr/share/jenkins/casc_configs
ENV SECRETS=/run/secrets/jenkins

RUN echo 2.0 > /usr/share/jenkins/ref/jenkins.install.UpgradeWizard.state
COPY --from=jenkins-x /usr/share/jenkins/ref/init.groovy.d/init-docker-registry-env.groovy /usr/share/jenkins/ref/init.groovy.d/init-docker-registry-env.groovy

# copy and install plugins embedded in the Jenkins X image
COPY --from=jenkins-x /usr/share/jenkins/ref/plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt

# copy and install custom plugins
COPY plugins.txt /usr/share/jenkins/ref/plugins-custom.txt
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins-custom.txt

COPY config/* ${CASC_JENKINS_CONFIG}/
