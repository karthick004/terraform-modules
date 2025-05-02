pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        TF_VAR_region = 'us-east-1'  // Passes region to Terraform
        TF_CACHE_DIR = "${WORKSPACE}/.tf_cache"
        LOCAL_BIN = "${WORKSPACE}/.local/bin"
        PATH = "${LOCAL_BIN}:${env.PATH}"
    }

    triggers {
        pollSCM('H/5 * * * *')  // Poll SCM every 5 minutes (adjust as needed)
    }

    stages {
        stage('Clean Workspace') {
            steps {
                cleanWs()  // Safer alternative to deleteDir()
            }
        }

        stage('Install Terraform') {
            steps {
                script {
                    def tfVersion = sh(
                        script: "${LOCAL_BIN}/terraform -version || echo 'not_installed'",
                        returnStdout: true
                    ).trim()
                    
                    if (tfVersion.contains('not_installed') {
                        echo 'Installing Terraform...'
                        sh """
                            mkdir -p ${LOCAL_BIN}
                            curl -fsSL https://releases.hashicorp.com/terraform/1.5.0/terraform_1.5.0_linux_amd64.zip -o terraform.zip
                            unzip -o terraform.zip -d ${LOCAL_BIN}
                            rm terraform.zip
                            chmod +x ${LOCAL_BIN}/terraform
                        """
                    }
                    sh "${LOCAL_BIN}/terraform -version"
                }
            }
        }

        stage('Checkout Code') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'github-creds',
                        usernameVariable: 'GIT_USERNAME',
                        passwordVariable: 'GIT_PASSWORD'
                    )
                ]) {
                    sh '''
                        rm -rf terraformmodules
                        git clone -b submain1 \
                            https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/CloudMasa-Tech/terraformmodules.git
                    '''
                }
            }
        }

        stage('Restore Cache') {
            steps {
                sh """
                    mkdir -p ${TF_CACHE_DIR}
                    [ -d "${TF_CACHE_DIR}/.terraform" ] && cp -R "${TF_CACHE_DIR}/.terraform" terraformmodules/
                    [ -f "${TF_CACHE_DIR}/terraform.tfstate" ] && cp "${TF_CACHE_DIR}/terraform.tfstate" terraformmodules/
                    [ -d "${TF_CACHE_DIR}/terraform.tfstate.d" ] && cp -R "${TF_CACHE_DIR}/terraform.tfstate.d" terraformmodules/
                """
            }
        }

        stage('Terraform Format') {
            steps {
                sh "cd terraformmodules && terraform fmt -check -recursive -diff"
            }
        }

        stage('Terraform Init') {
            steps {
                withCredentials([
                    aws(
                        credentialsId: 'aws-creds',
                        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    sh """
                        cd terraformmodules
                        terraform init -input=false
                    """
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                sh "cd terraformmodules && terraform validate -json | jq '.'"  // JSON output for better parsing
            }
        }

        stage('Terraform Plan') {
            steps {
                withCredentials([
                    aws(
                        credentialsId: 'aws-creds',
                        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    sh """
                        cd terraformmodules
                        terraform plan \
                            -input=false \
                            -out=tfplan \
                            -var 'region=${AWS_REGION}'
                    """
                    archiveArtifacts artifacts: 'terraformmodules/tfplan', allowEmptyArchive: true
                }
            }
        }

        stage('Manual Approval') {
            steps {
                timeout(time: 30, unit: 'MINUTES') {
                    input(
                        message: 'Apply Terraform changes?',
                        ok: 'Apply',
                        submitter: 'admin,release-team'
                    )
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                withCredentials([
                    aws(
                        credentialsId: 'aws-creds',
                        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    sh """
                        cd terraformmodules
                        terraform apply \
                            -input=false \
                            -auto-approve \
                            tfplan
                    """
                }
            }
        }

        stage('Save Cache') {
            steps {
                sh """
                    mkdir -p ${TF_CACHE_DIR}
                    cp -R terraformmodules/.terraform ${TF_CACHE_DIR}/ || true
                    cp terraformmodules/terraform.tfstate ${TF_CACHE_DIR}/ || true
                    cp -R terraformmodules/terraform.tfstate.d ${TF_CACHE_DIR}/ || true
                """
            }
        }
    }

    post {
        always {
            cleanWs()  // Clean workspace regardless of success/failure
            script {
                currentBuild.description = "Terraform ${currentBuild.result ?: 'SUCCESS'}"
            }
        }
        success {
            slackSend(color: 'good', message: "✅ Terraform deployment succeeded: ${env.JOB_NAME} #${env.BUILD_NUMBER}")
        }
        failure {
            slackSend(color: 'danger', message: "❌ Terraform deployment failed: ${env.JOB_NAME} #${env.BUILD_NUMBER}")
            archiveArtifacts artifacts: 'terraformmodules/**/*.log', allowEmptyArchive: true
        }
    }
}
