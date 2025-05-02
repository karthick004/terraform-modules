pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        TF_VAR_aws_region = "${AWS_REGION}"
        TF_CACHE_DIR = "${WORKSPACE}/.tf_cache"
        LOCAL_BIN = "${WORKSPACE}/.local/bin"
        PATH = "${LOCAL_BIN}:${env.PATH}"
    }

    stages {
        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }

        stage('Install Terraform') {
            steps {
                script {
                    def tfExists = sh(script: "command -v ${LOCAL_BIN}/terraform", returnStatus: true)
                    if (tfExists != 0) {
                        echo 'Installing Terraform 1.5.0...'
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
                    sh """
                        rm -rf terraformmodules
                        git clone -b submain2 https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/CloudMasa-Tech/terraformmodules.git
                    """
                }
            }
        }

        stage('Restore Cache') {
            steps {
                sh """
                    mkdir -p ${TF_CACHE_DIR}
                    if [ -d "${TF_CACHE_DIR}/.terraform" ]; then
                        cp -R ${TF_CACHE_DIR}/.terraform terraformmodules/
                    fi
                    if [ -f "${TF_CACHE_DIR}/terraform.tfstate" ]; then
                        cp ${TF_CACHE_DIR}/terraform.tfstate terraformmodules/
                    fi
                """
            }
        }

        stage('Terraform Format') {
            steps {
                dir('terraformmodules') {
                    sh 'terraform fmt -check -recursive -diff'
                }
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
                    dir('terraformmodules') {
                        sh 'terraform init -input=false'
                    }
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                dir('terraformmodules') {
                    sh 'terraform validate'
                }
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
                    dir('terraformmodules') {
                        sh """
                            terraform plan \
                                -input=false \
                                -var="aws_region=${AWS_REGION}" \
                                -out=tfplan
                        """
                    }
                }
            }
        }

        stage('Manual Approval') {
            steps {
                timeout(time: 30, unit: 'MINUTES') {
                    input message: 'Apply Terraform changes?', ok: 'Apply'
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
                    dir('terraformmodules') {
                        sh """
                            terraform apply \
                                -input=false \
                                -auto-approve \
                                tfplan
                        """
                    }
                }
            }
        }

        stage('Save Cache') {
            steps {
                sh """
                    mkdir -p ${TF_CACHE_DIR}
                    cp -R terraformmodules/.terraform ${TF_CACHE_DIR}/ || true
                    cp terraformmodules/terraform.tfstate ${TF_CACHE_DIR}/ || true
                """
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        success {
            echo "✅ Terraform deployment successful!"
        }
        failure {
            echo "❌ Terraform deployment failed!"
        }
    }
}
