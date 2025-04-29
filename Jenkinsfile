pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        TF_VAR_region = 'us-east-1'
        TF_DIR = 'eks_cluster' // Path to Terraform configuration
    }

    triggers {
        githubPush() // Trigger on push to GitHub
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
                        echo 'Terraform is not installed, installing it now.'
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
                git branch: 'main', url: 'https://github.com/karthick004/terraform-modules.git'
                script {
                    def tfFilesExist = sh(script: 'cd ${TF_DIR} && ls *.tf', returnStatus: true)
                    if (tfFilesExist != 0) {
                        error "No Terraform configuration files (.tf) found in '${env.TF_DIR}' directory!"
                    }
                }
            }
        }

        stage('Terraform Format Check') {
            steps {
                script {
                    sh "cd ${env.TF_DIR} && terraform fmt -check"
                }
            }
        }

        stage('Terraform Init') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    script {
                        sh "cd ${env.TF_DIR} && terraform init"
                    }
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    script {
                        sh "cd ${env.TF_DIR} && terraform validate"
                    }
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    script {
                        sh "cd ${env.TF_DIR} && terraform plan -out=tfplan"
                    }
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    input message: 'Do you want to apply the changes?', ok: 'Apply Now'
                    script {
                        sh "cd ${env.TF_DIR} && terraform apply tfplan"
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
    }
}
