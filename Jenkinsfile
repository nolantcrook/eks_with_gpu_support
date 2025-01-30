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
        
        // Configure kubectl only for apply operations
        stage('Configure kubectl') {
            when {
                expression { params.ACTION == 'destroy' }
            }
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
        
        // Destroy stages
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
                                    // Try to clean up Kubernetes resources if cluster exists
                                    try {
                                        sh """
                                            mkdir -p /root/.kube
                                            if aws eks describe-cluster --name eks-gpu-${params.ENV} --region ${AWS_REGION} >/dev/null 2>&1; then
                                                echo "Cluster exists, attempting cleanup..."
                                                aws eks update-kubeconfig --name eks-gpu-${params.ENV} --region ${AWS_REGION} || true
                                                helm uninstall nginx-ingress -n ingress-nginx || true
                                                kubectl delete namespace ingress-nginx || true
                                            else
                                                echo "Cluster does not exist, skipping cleanup..."
                                            fi
                                        """
                                    } catch (Exception e) {
                                        echo "Failed to cleanup Kubernetes resources, continuing with destroy: ${e.message}"
                                    }
                                    
                                    // Proceed with terraform destroy
                                    sh """
                                        terragrunt init --terragrunt-non-interactive
                                        terragrunt state list | grep -q helm_release.nginx_ingress && terragrunt state rm helm_release.nginx_ingress || true
                                        terragrunt plan -destroy -out=tfplan
                                    """
                                    
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