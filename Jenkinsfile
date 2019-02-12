#!/usr/bin/env groovy

def cleanup_workspace() {
  cleanWs()
  dir("${env.WORKSPACE}@tmp") {
    deleteDir()
  }
  dir("${env.WORKSPACE}@script") {
    deleteDir()
  }
  dir("${env.WORKSPACE}@script@tmp") {
    deleteDir()
  }
}

def run_meta_exec_command(command_string) {
  def pwd = pwd();
  def last_slash_index = pwd.lastIndexOf('/');
  if (last_slash_index > 0) {
    pwd = pwd.substring(last_slash_index + 1);
  }
  sh("meta exec --exclude ${pwd} '${command_string}'")
}

pipeline {
  agent any
  tools {
    nodejs "node-lts"
  }
  environment {
    NPM_RC_FILE = 'process-engine-ci-token'
    NODE_JS_VERSION = 'node-lts'
  }

  stages {
    stage('prepare') {
      steps {
        nodejs(configId: env.NPM_RC_FILE, nodeJSInstallationName: env.NODE_JS_VERSION) {
          sh('node --version')
          sh('npm install --global meta')
          run_meta_exec_command('npm install --ignore-scripts')
        }
      }
    }
    stage('lint') {
      steps {
        sh('node --version')
        run_meta_exec_command('npm run lint')
      }
    }
    stage('build') {
      steps {
        sh('node --version')
        run_meta_exec_command('npm run build')
      }
    }
    stage('test') {
      steps {
        sh('node --version')
        run_meta_exec_command('npm run test')
      }
    }
    stage('publish') {
      steps {
        script {
          def branch = env.BRANCH_NAME;
          def branch_is_master = branch == 'master';
          def new_commit = env.GIT_PREVIOUS_COMMIT != env.GIT_COMMIT;

          def found_projects = sh(script: "node _ci_tools/get_meta_projects.js", returnStdout: true).trim();
          def project_list = readJSON text: found_projects;

          for (package_folder in project_list) {
            println "Publishing package ${package_folder}"

            dir(package_folder) {

              def raw_package_version = sh(script: 'node --print --eval "require(\'./package.json\').version"', returnStdout: true)
              def package_version = raw_package_version.trim();
              println "Package version is '${package_version}'"

              if (branch_is_master) {
                if (new_commit) {

                  // let the build fail if the version does not match normal semver
                  def semver_matcher = package_version =~ /\d+\.\d+\.\d+/;
                  def is_version_not_semver = semver_matcher.matches() == false;
                  if (is_version_not_semver) {
                    error('Only non RC Versions are allowed in master')
                  }

                  def raw_package_name = sh(script: 'node --print --eval "require(\'./package.json\').name"', returnStdout: true).trim();
                  def current_published_version = sh(script: "npm show ${raw_package_name} version", returnStdout: true).trim();
                  def version_has_changed = current_published_version != raw_package_version;

                  if (version_has_changed) {
                    nodejs(configId: env.NPM_RC_FILE, nodeJSInstallationName: env.NODE_JS_VERSION) {
                      sh('node --version')
                      sh('npm publish --ignore-scripts')
                    }
                  } else {
                    println 'Skipping publish for this version. Version unchanged.'
                  }
                }

              } else {
                // when not on master, publish a prerelease based on the package version, the
                // current git commit and the build number.
                // the published version gets tagged as the branch name.
                def first_seven_digits_of_git_hash = env.GIT_COMMIT.substring(0, 8);
                def publish_version = "${package_version}-${first_seven_digits_of_git_hash}-b${env.BUILD_NUMBER}";
                def publish_tag = branch.replace("/", "~");

                nodejs(configId: env.NPM_RC_FILE, nodeJSInstallationName: env.NODE_JS_VERSION) {
                  sh('node --version')
                  sh("npm version ${publish_version} --no-git-tag-version --force")
                  sh("npm publish --tag ${publish_tag} --ignore-scripts")
                }
              }
            }
          }
        }
      }
    }
    stage('cleanup') {
      steps {
        script {
          // this stage just exists, so the cleanup-work that happens in the post-script
          // will show up in its own stage in Blue Ocean
          sh(script: ':', returnStdout: true);
        }
      }
    }
  }
  post {
    always {
      script {
        cleanup_workspace();
      }
    }
  }
}
