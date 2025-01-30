pipeline {
    agent any
    
    environment {
        AWS_REGION = 'us-west-2'
        AWS_CONFIG_FILE = '/root/.aws/config'
        AWS_SHARED_CREDENTIALS_FILE = '/root/.aws/credentials'
        KUBECONFIG = '/root/.kube/config'
        // ARGOCD_SERVER = 'argocd.example.com' // Update this with your ArgoCD server address
        // ARGOCD_AUTH_TOKEN = credentials('argocd-auth-token') // Create this in Jenkins
    }
    
    parameters {
        choice(
            name: 'ENV',
            choices: ['dev', 'prod'],
            description: 'Select the environment to deploy'
        )
        choice(
            name: 'ACTION',
            choices: ['apply', 'destroy'],
            description: 'Select action (apply or destroy)'
        )
        booleanParam(
            name: 'AUTO_APPROVE',
            defaultValue: false,
            description: 'Automatically approve all deployment stages'
        )
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        // Add EKS authentication stage
        stage('Configure kubectl') {
            steps {
                script {
                    sh """
                        mkdir -p /root/.kube
                        aws eks update-kubeconfig --name eks-gpu-${params.ENV} --region ${AWS_REGION}
                    """
                }
            }
        }
        
        // Apply stages
        stage('Apply Infrastructure') {
            when {
                expression { params.ACTION == 'apply' }
            }
            stages {
                stage('Foundation Infrastructure') {
                    steps {
                        dir('terraform/foundation') {
                            withEnv(["ENV=${params.ENV}"]) {
                                script {
                                    sh 'terragrunt init --terragrunt-non-interactive'
                                    sh 'terragrunt plan -out=tfplan'
                                    if (!params.AUTO_APPROVE) {
                                        input message: 'Do you want to apply the Foundation changes?'
                                    }
                                    sh 'terragrunt apply -auto-approve tfplan'
                                }
                            }
                        }
                    }
                }
                
                stage('Storage Infrastructure') {
                    steps {
                        dir('terraform/storage') {
                            withEnv(["ENV=${params.ENV}"]) {
                                script {
                                    sh 'terragrunt init --terragrunt-non-interactive'
                                    sh 'terragrunt plan -out=tfplan'
                                    if (!params.AUTO_APPROVE) {
                                        input message: 'Do you want to apply the Storage changes?'
                                    }
                                    sh 'terragrunt apply -auto-approve tfplan'
                                }
                            }
                        }
                    }
                }
                
                stage('Networking Infrastructure') {
                    steps {
                        dir('terraform/networking') {
                            withEnv(["ENV=${params.ENV}"]) {
                                script {
                                    sh 'terragrunt init --terragrunt-non-interactive'
                                    sh 'terragrunt plan -out=tfplan'
                                    if (!params.AUTO_APPROVE) {
                                        input message: 'Do you want to apply the Networking changes?'
                                    }
                                    sh 'terragrunt apply -auto-approve tfplan'
                                }
                            }
                        }
                    }
                }
                
                stage('Compute Infrastructure') {
                    steps {
                        dir('terraform/compute') {
                            withEnv(["ENV=${params.ENV}"]) {
                                script {
                                    sh 'terragrunt init --terragrunt-non-interactive'
                                    sh 'terragrunt plan -out=tfplan'
                                    if (!params.AUTO_APPROVE) {
                                        input message: 'Do you want to apply the Compute changes?'
                                    }
                                    sh 'terragrunt apply -auto-approve tfplan'
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // Destroy stages in reverse order
        stage('Destroy Infrastructure') {
            when {
                expression { params.ACTION == 'destroy' }
            }
            stages {
                stage('Destroy Compute Infrastructure') {
                    steps {
                        dir('terraform/compute') {
                            withEnv(["ENV=${params.ENV}"]) {
                                script {
                                    // Add explicit helm cleanup before terraform destroy
                                    sh """
                                        helm uninstall nginx-ingress -n ingress-nginx || true
                                        kubectl delete namespace ingress-nginx || true
                                    """
                                    sh 'terragrunt init --terragrunt-non-interactive'
                                    sh 'terragrunt plan -destroy -out=tfplan'
                                    if (!params.AUTO_APPROVE) {
                                        input message: 'Do you want to destroy the Compute infrastructure?'
                                    }
                                    sh 'terragrunt apply -auto-approve tfplan'
                                }
                            }
                        }
                    }
                }
                
                stage('Destroy Networking Infrastructure') {
                    steps {
                        dir('terraform/networking') {
                            withEnv(["ENV=${params.ENV}"]) {
                                script {
                                    sh 'terragrunt init --terragrunt-non-interactive'
                                    sh 'terragrunt plan -destroy -out=tfplan'
                                    if (!params.AUTO_APPROVE) {
                                        input message: 'Do you want to destroy the Networking infrastructure?'
                                    }
                                    sh 'terragrunt apply -auto-approve tfplan'
                                }
                            }
                        }
                    }
                }
                
                stage('Destroy Storage Infrastructure') {
                    steps {
                        dir('terraform/storage') {
                            withEnv(["ENV=${params.ENV}"]) {
                                script {
                                    sh 'terragrunt init --terragrunt-non-interactive'
                                    sh 'terragrunt plan -destroy -out=tfplan'
                                    if (!params.AUTO_APPROVE) {
                                        input message: 'Do you want to destroy the Storage infrastructure?'
                                    }
                                    sh 'terragrunt apply -auto-approve tfplan'
                                }
                            }
                        }
                    }
                }
                
                stage('Destroy Foundation Infrastructure') {
                    steps {
                        dir('terraform/foundation') {
                            withEnv(["ENV=${params.ENV}"]) {
                                script {
                                    sh 'terragrunt init --terragrunt-non-interactive'
                                    sh 'terragrunt plan -destroy -out=tfplan'
                                    if (!params.AUTO_APPROVE) {
                                        input message: 'Do you want to destroy the Foundation infrastructure?'
                                    }
                                    sh 'terragrunt apply -auto-approve tfplan'
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    post {
        always {
            sh '''
                rm -f terraform/foundation/tfplan
                rm -f terraform/storage/tfplan
                rm -f terraform/networking/tfplan
                rm -f terraform/compute/tfplan
            '''
        }
        success {
            echo "Pipeline completed successfully!"
        }
        failure {
            echo "Pipeline failed!"
        }
    }
} 