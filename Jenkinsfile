pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-2'
        TF_VAR_region = 'us-east-2'
        TF_DIR = 'eks_cluster'
        TF_CACHE_DIR = "${WORKSPACE}/.tf_cache"
        KUBECONFIG = "${WORKSPACE}/kubeconfig"
    }

    triggers {
        githubPush()
    }

    options {
        timestamps()
        ansiColor('xterm')
    }

    stages {

        stage('Install Terraform') {
            steps {
                script {
                    def terraformInstalled = sh(script: 'terraform -version', returnStatus: true)
                    if (terraformInstalled != 0) {
                        echo 'Terraform is not installed. Installing now...'
                        sh '''
                            TERRAFORM_VERSION="1.5.0"
                            mkdir -p $HOME/.local/bin
                            curl -fsSL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -o terraform.zip
                            unzip terraform.zip
                            mv terraform $HOME/.local/bin/terraform
                            echo 'export PATH=$HOME/.local/bin:$PATH' >> $HOME/.bashrc
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

        stage('Restore Terraform Cache') {
            steps {
                script {
                    sh "mkdir -p ${TF_CACHE_DIR}"
                    sh "if [ -d ${TF_CACHE_DIR}/.terraform ]; then cp -R ${TF_CACHE_DIR}/.terraform ${TF_DIR}/; fi"
                    sh "if [ -f ${TF_CACHE_DIR}/terraform.tfstate ]; then cp ${TF_CACHE_DIR}/terraform.tfstate ${TF_DIR}/; fi"
                    sh "if [ -d ${TF_CACHE_DIR}/terraform.tfstate.d ]; then cp -R ${TF_CACHE_DIR}/terraform.tfstate.d ${TF_DIR}/; fi"
                }
            }
        }

        stage('Terraform Format') {
            steps {
                sh "cd ${TF_DIR} && terraform fmt -recursive"
            }
        }

        stage('Terraform Init') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    sh "cd ${TF_DIR} && terraform init"
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    sh "cd ${TF_DIR} && terraform validate"
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
                    input message: 'Do you want to apply the changes?', ok: 'Apply Now'
                    sh "cd ${TF_DIR} && terraform apply tfplan"
                }
            }
        }

        stage('Update Kubeconfig') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    sh '''
                        echo "Updating kubeconfig after EKS cluster creation..."
                        aws eks update-kubeconfig --region $AWS_REGION --name prod-eks --kubeconfig $KUBECONFIG
                    '''
                }
            }
        }

        stage('Terraform Kubernetes Deployments') {
            when {
                expression { fileExists("${TF_DIR}/kubernetes.tf") }
            }
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    sh '''
                        cd ${TF_DIR}
                        terraform apply -auto-approve
                    '''
                }
            }
        }

        stage('Save Terraform Cache') {
            steps {
                script {
                    sh "mkdir -p ${TF_CACHE_DIR}"
                    sh "cp -R ${TF_DIR}/.terraform ${TF_CACHE_DIR}/ || true"
                    sh "cp ${TF_DIR}/terraform.tfstate ${TF_CACHE_DIR}/ || true"
                    sh "cp -R ${TF_DIR}/terraform.tfstate.d ${TF_CACHE_DIR}/ || true"
                }
            }
        }
    }

    post {
        success {
            echo "✅ Terraform deployment completed successfully!"
        }
        failure {
            echo "❌ Terraform deployment failed!"
        }
    }
}
