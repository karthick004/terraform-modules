pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        TF_VAR_aws_region = "${AWS_REGION}"
        LOCAL_BIN = "${WORKSPACE}/.local/bin"
        PATH = "${LOCAL_BIN}:${env.PATH}"
    }

    stages {
        stage('Prepare Workspace') {
            steps {
                cleanWs()
                sh 'mkdir -p ${LOCAL_BIN}'
            }
        }

        stage('Install Terraform') {
            steps {
                script {
                    def tfInstalled = sh(script: "[ -x '${LOCAL_BIN}/terraform' ]", returnStatus: true)
                    if (tfInstalled != 0) {
                        echo 'Installing Terraform 1.5.0...'
                        sh """
                            curl -fsSL https://releases.hashicorp.com/terraform/1.5.0/terraform_1.5.0_linux_amd64.zip -o terraform.zip
                            unzip -o terraform.zip -d ${LOCAL_BIN}
                            rm -f terraform.zip
                            chmod +x ${LOCAL_BIN}/terraform
                        """
                    }
                    sh "${LOCAL_BIN}/terraform -version"
                }
            }
        }

        stage('Install kubectl') {
            steps {
                script {
                    echo 'Installing kubectl...'
                    sh """
                        curl -LO https://dl.k8s.io/release/v1.26.1/bin/linux/amd64/kubectl
                        chmod +x ./kubectl
                        mv ./kubectl /usr/local/bin/kubectl
                        kubectl version --client
                    """
                }
            }
        }

        stage('Checkout Code') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'github-creds', usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD')]) {
                    sh '''
                        rm -rf terraformmodules || true
                        git clone -b submain2 --depth 1 https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/CloudMasa-Tech/terraformmodules.git
                        cd terraformmodules && git rev-parse HEAD > ../git-commit.txt
                    '''
                }
            }
        }

        stage('Terraform Format') {
            steps {
                dir('terraformmodules') {
                    sh 'terraform fmt -recursive'
                }
            }
        }

        stage('Terraform Init') {
            steps {
                withCredentials([aws(credentialsId: 'aws-creds', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    dir('terraformmodules') {
                        sh 'terraform init -input=false -upgrade'
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
                withCredentials([aws(credentialsId: 'aws-creds', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    dir('terraformmodules') {
                        script {
                            def status = sh(
                                script: """
                                    terraform plan \
                                        -input=false \
                                        -out=tfplan
                                """,
                                returnStatus: true
                            )
                            if (status != 0) {
                                error("Terraform plan failed!")
                            }
                            sh 'terraform show -no-color tfplan > tfplan.txt'
                            archiveArtifacts artifacts: 'tfplan.txt'
                        }
                    }
                }
            }
        }

        stage('Manual Approval') {
            when {
                expression { !env.JOB_NAME.contains('automated') }
            }
            steps {
                timeout(time: 30, unit: 'MINUTES') {
                    input message: 'Apply Terraform changes?', ok: 'Apply', submitter: 'admin,terraform'
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                withCredentials([aws(credentialsId: 'aws-creds', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    dir('terraformmodules') {
                        sh 'terraform apply -input=false -auto-approve tfplan'
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ Terraform deployment successful!"
        }
        failure {
            echo "❌ Terraform deployment failed!"
        }
        cleanup {
            echo "🧹 Pipeline completed - cleaning up"
        }
    }
}
