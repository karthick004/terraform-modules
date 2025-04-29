pipeline {
    agent any // Use any available agent

    environment {
        AWS_REGION = 'us-east-1'
        TF_VAR_region = 'us-east-1'
    }

    triggers {
        githubPush()
    }

    options {
        timestamps()
        ansiColor('xterm') // Ensure AnsiColor plugin is installed on Jenkins
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/karthick004/terraform-modules.git'
            }
        }

        stage('Terraform Format Check') {
            steps {
                sh 'terraform fmt -check'
            }
        }

        stage('Terraform Init') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    sh 'terraform init'
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    sh 'terraform validate'
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    sh 'terraform plan -out=tfplan'
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    input message: 'Do you want to apply the changes?', ok: 'Apply Now'
                    sh 'terraform apply tfplan'
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
