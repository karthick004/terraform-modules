pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        TF_VAR_region = 'us-east-1'
        TF_DIR = 'eks_cluster' // <<== define your Terraform module directory
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
                git branch: 'main', url: 'https://github.com/karthick004/cluster-module.git'
                script {
                    // Verify .tf files exist in the eks_cluster directory
                    sh "cd ${env.TF_DIR} && ls *.tf"
                }
            }
        }

        stage('Terraform Format') {
            steps {
                script {
                    echo "Running terraform fmt to auto-format code..."
                    sh "cd ${env.TF_DIR} && terraform fmt -recursive"
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
