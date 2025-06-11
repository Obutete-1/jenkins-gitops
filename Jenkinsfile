pipeline {
    agent {
        label 'node-ec'
    }

    options {
        timeout(time: 1, unit: 'HOURS')
        disableConcurrentBuilds()
        ansiColor('xterm')
    }

    environment {
        CHECKOV_IMAGE = 'bridgecrew/checkov:latest'
        CHECKOV_OPTIONS = '--download-external-modules false -o cli -o junitxml --output-file-path console,terraform/results.xml'
        TEST_RESULTS_FILE = 'results.xml'
        TERRAFORM_DIR = 'terraform'
    }

    parameters {
        choice(
            name: 'ACTION',
            choices: ['apply', 'destroy'],
            description: 'Choose the action to perform: apply (default) or destroy.'
        )
    }

    stages {
        stage('Preparation') {
            steps {
                cleanWs()
                checkout scm
            }
        }

        stage('Infrastructure Validation') {
            stages {
                stage('Terraform Setup') {
                    steps {
                        sh 'terraform -version'
                    }
                }

                stage('Terraform Init') {
                    steps {
                        dir(TERRAFORM_DIR) {
                            retry(3) {
                                sh 'terraform init'
                            }
                        }
                    }
                }

                stage('Terraform Validate') {
                    steps {
                        dir(TERRAFORM_DIR) {
                            sh '''
                                terraform fmt -check -recursive
                                terraform validate
                            '''
                        }
                    }
                }
            }
        }

        stage('Security Scan') {
            steps {
                script {
                    docker.image(env.CHECKOV_IMAGE).inside("-v /var/run/docker.sock:/var/run/docker.sock --entrypoint=''") {
                        dir(TERRAFORM_DIR) {
                            try {
                                sh "checkov -d . ${env.CHECKOV_OPTIONS}"
                            } catch (err) {
                                unstable('Checkov found security issues')
                            } finally {
                                junit(
                                    skipPublishingChecks: true,
                                    testResults: "${env.TEST_RESULTS_FILE}",
                                    allowEmptyResults: true
                                )
                                archiveArtifacts(
                                    artifacts: "${env.TEST_RESULTS_FILE}",
                                    allowEmptyArchive: true
                                )
                            }
                        }
                    }
                }
            }
        }

        stage('Plan') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                dir(TERRAFORM_DIR) {
                    sh 'terraform plan -no-color -input=false -out planfile'
                }
            }
        }

        stage('Approval') {
            when {
                expression { params.ACTION in ['apply', 'destroy'] }
            }
            steps {
                input message: "Proceed with ${params.ACTION}?"
            }
        }

        stage('Apply or Destroy') {
            when {
                expression { params.ACTION in ['apply', 'destroy'] }
            }
            steps {
                dir(TERRAFORM_DIR) {
                    script {
                        if (params.ACTION == 'apply') {
                            sh 'terraform apply -auto-approve -input=false -parallelism=1 planfile'
                        } else {
                            sh 'terraform destroy -auto-approve -input=false'
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        failure {
            echo 'Pipeline failed! Sending notifications...'
        }
        success {
            echo 'Pipeline succeeded! Sending notifications...'
        }
    }
}
