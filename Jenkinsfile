/*
 * (C) Copyright 2019 Nuxeo (http://nuxeo.com/) and others.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Contributors:
 *     Antoine Taillefer <ataillefer@nuxeo.com>
 */
 properties([
  [$class: 'GithubProjectProperty', projectUrlStr: 'https://github.com/nuxeo/jx-platform-jenkins/'],
  [$class: 'BuildDiscarderProperty', strategy: [$class: 'LogRotator', daysToKeepStr: '60', numToKeepStr: '60', artifactNumToKeepStr: '5']],
  disableConcurrentBuilds(),
])

void setGitHubBuildStatus(String context, String message, String state) {
  step([
    $class: 'GitHubCommitStatusSetter',
    reposSource: [$class: 'ManuallyEnteredRepositorySource', url: 'https://github.com/nuxeo/jx-platform-jenkins'],
    contextSource: [$class: 'ManuallyEnteredCommitContextSource', context: context],
    statusResultSource: [$class: 'ConditionalStatusResultSource', results: [[$class: 'AnyBuildResult', message: message, state: state]]],
  ])
}

void skaffoldBuild(String yaml) {
  sh """
    envsubst < ${yaml} > ${yaml}~gen
    skaffold build -f ${yaml}~gen
  """
}

void skaffoldBuildRepository() {
  echo "Build and push Docker images using version ${VERSION}"
  skaffoldBuild('skaffold.yaml')
  // building image depending on nuxeo/platform-jenkinsx
  // waiting for dependent images support in skaffold
  skaffoldBuild('staging/skaffold.yaml')
}

def version

pipeline {
  agent {
    label 'jenkins-jx-base'
  }
  stages {
    stage('Build and push image') {
      steps {
        setGitHubBuildStatus('build', 'Build and push image', 'PENDING')
        container('jx-base') {
          script {
            String releaseVersion = sh(returnStdout: true, script: 'jx-release-version')
            version = BRANCH_NAME == 'master' ? releaseVersion : releaseVersion + "-${BRANCH_NAME}-${BUILD_NUMBER}"
          }
          withEnv(["VERSION=${version}"]) {
            skaffoldBuildRepository()
          }
        }
      }
      post {
        success {
          setGitHubBuildStatus('build', 'Build and push image', 'SUCCESS')
        }
        failure {
          setGitHubBuildStatus('build', 'Build and push image', 'FAILURE')
        }
      }
    }
    stage('Release') {
      when {
        branch 'master'
      }
      steps {
        setGitHubBuildStatus('release', 'Release', 'PENDING')
        container('jx-base') {
          echo "Release version ${version}"
          sh """
            # ensure we're not on a detached head
            git checkout master

            # create the Git credentials
            jx step git credentials
            git config credential.helper store

            # Git tag
            jx step tag -v ${version}

            # Git release
            jx step changelog -v v${version}

            # update Jenkins image version in the platform env
            ./updatebot.sh ${version}
          """
        }
      }
      post {
        always {
          step([$class: 'JiraIssueUpdater', issueSelector: [$class: 'DefaultIssueSelector'], scm: scm])
        }
        success {
          setGitHubBuildStatus('release', 'Release', 'SUCCESS')
        }
        failure {
          setGitHubBuildStatus('release', 'Release', 'FAILURE')
        }
      }
    }
  }
}
