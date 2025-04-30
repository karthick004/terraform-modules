pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-2'
        TF_VAR_region = 'us-east-2'
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

        stage('Restore Terraform Cache') {
            steps {
                sh "mkdir -p ${TF_CACHE_DIR}"
                sh "if [ -d ${TF_CACHE_DIR}/.terraform ]; then cp -R ${TF_CACHE_DIR}/.terraform eks_cluster/; fi"
                sh "if [ -f ${TF_CACHE_DIR}/terraform.tfstate ]; then cp ${TF_CACHE_DIR}/terraform.tfstate eks_cluster/; fi"
                sh "if [ -d ${TF_CACHE_DIR}/terraform.tfstate.d ]; then cp -R ${TF_CACHE_DIR}/terraform.tfstate.d eks_cluster/; fi"
            }
        }

        stage('Init & Apply EKS Cluster') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    sh '''
                        cd eks_cluster
                        terraform init
                        terraform fmt -recursive
                        terraform validate
                        terraform plan -out=tfplan
                        terraform apply -auto-approve tfplan
                    '''
                }
            }
        }

        stage('Generate kubeconfig') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    sh '''
                        mkdir -p ~/.kube
                        CLUSTER_NAME=$(terraform -chdir=eks_cluster output -raw cluster_name)
                        aws eks update-kubeconfig --name $CLUSTER_NAME --region ${AWS_REGION} --kubeconfig ${KUBECONFIG}
                        echo "✅ kubeconfig created at ${KUBECONFIG}"
                    '''
                }
            }
        }

        stage('Apply Post Cluster Resources') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    sh '''
                        cd post_cluster
                        terraform init
                        terraform fmt -recursive
                        terraform validate
                        terraform apply -auto-approve
                    '''
                }
            }
        }

        stage('Save Terraform Cache') {
            steps {
                sh "mkdir -p ${TF_CACHE_DIR}"
                sh "cp -R eks_cluster/.terraform ${TF_CACHE_DIR}/ || true"
                sh "cp eks_cluster/terraform.tfstate ${TF_CACHE_DIR}/ || true"
                sh "cp -R eks_cluster/terraform.tfstate.d ${TF_CACHE_DIR}/ || true"
            }
        }
    }

    post {
        success {
            echo "✅ Full EKS infrastructure deployment succeeded!"
        }
        failure {
            echo "❌ Deployment failed. Check logs above."
        }
    }
}
