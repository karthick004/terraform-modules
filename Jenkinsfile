pipeline {
    agent any // Use any available agent

    environment {
        AWS_REGION = 'us-east-1'
        TF_VAR_region = 'us-east-1'
    }

    triggers {
        githubPush() // Trigger on push to GitHub
    }

    options {
        timestamps() // Add timestamps to logs
        ansiColor('xterm') // Ensure AnsiColor plugin is installed on Jenkins
    }

    stages {
        stage('Install Terraform') {
            steps {
                script {
                    // Check if Terraform is installed
                    def terraformInstalled = sh(script: 'terraform -version', returnStatus: true)
                    if (terraformInstalled != 0) {
                        echo 'Terraform is not installed, installing it now.'
                        // Install Terraform manually without sudo
                        sh '''
                            TERRAFORM_VERSION="1.5.0"
                            curl -fsSL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -o terraform.zip
                            unzip terraform.zip
                            mv terraform $HOME/.local/bin/terraform
                            # Make sure terraform is installed
                            echo "Terraform installed to: $HOME/.local/bin/terraform"
                            $HOME/.local/bin/terraform -version
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
                    // Verify if any .tf files are in the repository
                    def tfFilesExist = sh(script: 'ls *.tf', returnStatus: true)
                    if (tfFilesExist != 0) {
                        error 'No Terraform configuration files (.tf) found in the repository!'
                    }
                }
            }
        }

        stage('Terraform Format Check') {
            steps {
                script {
                    // Check if the Terraform configuration exists
                    sh 'terraform fmt -check'
                }
            }
        }

        stage('Terraform Init') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    script {
                        // Ensure you're in the correct directory (if required)
                        sh 'terraform init'
                    }
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    script {
                        sh 'terraform validate'
                    }
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    script {
                        sh 'terraform plan -out=tfplan'
                    }
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    input message: 'Do you want to apply the changes?', ok: 'Apply Now'
                    script {
                        sh 'terraform apply tfplan'
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
