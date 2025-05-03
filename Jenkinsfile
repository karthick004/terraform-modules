pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        TF_VAR_aws_region = "${AWS_REGION}"
        TF_CACHE_DIR = "${WORKSPACE}/.tf_cache"
        LOCAL_BIN = "${WORKSPACE}/.local/bin"
        PATH = "${LOCAL_BIN}:${env.PATH}"
        CACHE_BUCKET = 'my-tf-plugin-cache-bucket'
    }

    parameters {
        string(name: 'TF_STATE_KEY', defaultValue: 'environments/dev/eks/terraform.tfstate', description: 'Terraform state file key')
    }

    stages {
        stage('Prepare Workspace') {
            steps {
                cleanWs()
                sh 'mkdir -p ${TF_CACHE_DIR} ${LOCAL_BIN}'
            }
        }

        stage('Install Terraform') {
            steps {
                script {
                    def tfInstalled = sh(script: "if [ -x '${LOCAL_BIN}/terraform' ]; then exit 0; else exit 1; fi", returnStatus: true)
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

        stage('Checkout Code') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'github-creds', usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD')]) {
                    sh """
                        rm -rf terraformmodules || true
                        git clone -b submain1 --depth 1 https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/CloudMasa-Tech/terraformmodules.git
                        cd terraformmodules && git rev-parse HEAD > ../git-commit.txt
                    """
                }
            }
        }

        stage('Download Terraform Cache from S3') {
            steps {
                withCredentials([aws(credentialsId: 'aws-creds', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    dir('terraformmodules') {
                        sh """
                            CACHE_PATH="cache/${params.TF_STATE_KEY}"
                            aws s3 cp s3://${CACHE_BUCKET}/\${CACHE_PATH}/.terraform .terraform --recursive || true
                        """
                    }
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
                        sh """
                            terraform init \
                                -input=false \
                                -backend-config="bucket=my-tf-state-bucket" \
                                -backend-config="key=${params.TF_STATE_KEY}" \
                                -backend-config="region=${AWS_REGION}" \
                                -backend-config="dynamodb_table=my-tf-lock-table" \
                                -upgrade
                        """
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
                        sh """
                            terraform plan \
                                -input=false \
                                -var="aws_region=${AWS_REGION}" \
                                -out=tfplan \
                                -detailed-exitcode || true
                        """
                        sh 'terraform show -no-color tfplan > tfplan.txt'
                        archiveArtifacts artifacts: 'tfplan.txt'
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
                    input(message: 'Apply Terraform changes?', ok: 'Apply', submitter: 'admin,terraform')
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

        stage('Terraform Output') {
            steps {
                dir('terraformmodules') {
                    script {
                        sh 'terraform output -json > outputs.json'
                        archiveArtifacts artifacts: 'outputs.json'
                        def outputs = readJSON file: 'outputs.json'
                        echo "Cluster Endpoint: ${outputs.cluster_endpoint.value}"
                    }
                }
            }
        }

        stage('Upload Terraform Cache to S3') {
            steps {
                withCredentials([aws(credentialsId: 'aws-creds', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    dir('terraformmodules') {
                        sh """
                            CACHE_PATH="cache/${params.TF_STATE_KEY}"
                            aws s3 cp .terraform s3://${CACHE_BUCKET}/\${CACHE_PATH}/.terraform --recursive || true
                        """
                    }
                }
            }
        }
    }

    post {
        always {
            script {
                echo "🔁 Finalizing..."
                archiveArtifacts artifacts: 'terraformmodules/**/*.tf,git-commit.txt', allowEmptyArchive: true
                sh 'rm -f terraformmodules/tfplan terraformmodules/tfplan.txt || true'
            }
        }
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
