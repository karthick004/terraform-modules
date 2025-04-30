pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-2'
        TF_VAR_region = 'us-east-2'
        TF_DIR = 'eks_cluster'
        TF_CACHE_DIR = "${WORKSPACE}/.tf_cache"
        KUBECONFIG = "${WORKSPACE}/.kube/config"
    }

    options {
        timestamps()
        ansiColor('xterm')
    }

    triggers {
        githubPush()
    }

    stages {
        stage('Install Terraform') {
            steps {
                script {
                    def terraformInstalled = sh(script: 'terraform -version', returnStatus: true)
                    if (terraformInstalled != 0) {
                        echo 'Installing Terraform...'
                        sh '''
                            TERRAFORM_VERSION="1.5.0"
                            mkdir -p $HOME/.local/bin
                            curl -fsSL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -o terraform.zip
                            unzip terraform.zip
                            mv terraform $HOME/.local/bin/terraform
                            export PATH=$HOME/.local/bin:$PATH
                            terraform -version
                        '''
                    } else {
                        echo 'Terraform is already installed.'
                    }
                }
            }
        }

        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/karthick004/cluster-module.git'
            }
        }

        stage('Restore Cache') {
            steps {
                sh "mkdir -p ${TF_CACHE_DIR}"
                sh "if [ -d ${TF_CACHE_DIR}/.terraform ]; then cp -R ${TF_CACHE_DIR}/.terraform ${TF_DIR}/; fi"
                sh "if [ -f ${TF_CACHE_DIR}/terraform.tfstate ]; then cp ${TF_CACHE_DIR}/terraform.tfstate ${TF_DIR}/; fi"
                sh "if [ -d ${TF_CACHE_DIR}/terraform.tfstate.d ]; then cp -R ${TF_CACHE_DIR}/terraform.tfstate.d ${TF_DIR}/; fi"
            }
        }

        stage('Terraform Init') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    sh "cd ${TF_DIR} && terraform init"
                }
            }
        }

        stage('Terraform Format & Validate') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    sh "cd ${TF_DIR} && terraform fmt -recursive && terraform validate"
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    sh "cd ${TF_DIR} && terraform plan -out=tfplan"
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    input message: 'Apply the infrastructure changes?', ok: 'Apply'
                    sh "cd ${TF_DIR} && terraform apply tfplan"
                }
            }
        }

        stage('Generate kubeconfig') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    sh '''
                        mkdir -p ~/.kube
                        CLUSTER_NAME=$(terraform -chdir=${TF_DIR} output -raw cluster_name)
                        aws eks update-kubeconfig --name $CLUSTER_NAME --region ${AWS_REGION} --kubeconfig ${KUBECONFIG}
                        echo "KUBECONFIG generated at ${KUBECONFIG}"
                    '''
                }
            }
        }

        stage('Save Cache') {
            steps {
                sh "mkdir -p ${TF_CACHE_DIR}"
                sh "cp -R ${TF_DIR}/.terraform ${TF_CACHE_DIR}/ || true"
                sh "cp ${TF_DIR}/terraform.tfstate ${TF_CACHE_DIR}/ || true"
                sh "cp -R ${TF_DIR}/terraform.tfstate.d ${TF_CACHE_DIR}/ || true"
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
    }
}
