pipeline {
    agent any
    
    environment {
        TF_DIR = 'terraform/cluster'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Terraform Init') {
            steps {
                dir(TF_DIR) {
                    sh 'terraform init'
                }
            }
        }
        
        stage('Terraform Plan') {
            steps {
                dir(TF_DIR) {
                    sh 'terraform plan -out=tfplan'
                }
            }
        }
        
        stage('Approval') {
            steps {
                input message: 'Do you want to apply the Terraform changes?'
            }
        }
        
        stage('Terraform Apply') {
            steps {
                dir(TF_DIR) {
                    sh 'terraform apply -auto-approve tfplan'
                }
            }
        }
    }
    
    post {
        always {
            dir(TF_DIR) {
                // Clean up the plan file
                sh 'rm -f tfplan'
            }
        }
    }
}
