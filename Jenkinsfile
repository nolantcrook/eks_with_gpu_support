pipeline {
    agent any
    
    environment {
        AWS_REGION = 'us-west-2'
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
    }
    
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Foundation Infrastructure') {
            steps {
                dir('terraform/foundation') {
                    withEnv(["ENV=${params.ENV}"]) {
                        script {
                            if (params.ACTION == 'apply') {
                                sh 'terragrunt init --terragrunt-non-interactive'
                                sh 'terragrunt plan -out=tfplan'
                                input message: 'Do you want to apply the Foundation changes?'
                                sh 'terragrunt apply -auto-approve tfplan'
                            } else {
                                sh 'terragrunt init --terragrunt-non-interactive'
                                sh 'terragrunt plan -destroy -out=tfplan'
                                input message: 'Do you want to destroy the Foundation infrastructure?'
                                sh 'terragrunt apply -auto-approve tfplan'
                            }
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
                            if (params.ACTION == 'apply') {
                                sh 'terragrunt init --terragrunt-non-interactive'
                                sh 'terragrunt plan -out=tfplan'
                                input message: 'Do you want to apply the Storage changes?'
                                sh 'terragrunt apply -auto-approve tfplan'
                            } else {
                                sh 'terragrunt init --terragrunt-non-interactive'
                                sh 'terragrunt plan -destroy -out=tfplan'
                                input message: 'Do you want to destroy the Storage infrastructure?'
                                sh 'terragrunt apply -auto-approve tfplan'
                            }
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
                            if (params.ACTION == 'apply') {
                                sh 'terragrunt init --terragrunt-non-interactive'
                                sh 'terragrunt plan -out=tfplan'
                                input message: 'Do you want to apply the Networking changes?'
                                sh 'terragrunt apply -auto-approve tfplan'
                            } else {
                                sh 'terragrunt init --terragrunt-non-interactive'
                                sh 'terragrunt plan -destroy -out=tfplan'
                                input message: 'Do you want to destroy the Networking infrastructure?'
                                sh 'terragrunt apply -auto-approve tfplan'
                            }
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
                            if (params.ACTION == 'apply') {
                                sh 'terragrunt init --terragrunt-non-interactive'
                                sh 'terragrunt plan -out=tfplan'
                                input message: 'Do you want to apply the Compute changes?'
                                sh 'terragrunt apply -auto-approve tfplan'
                            } else {
                                sh 'terragrunt init --terragrunt-non-interactive'
                                sh 'terragrunt plan -destroy -out=tfplan'
                                input message: 'Do you want to destroy the Compute infrastructure?'
                                sh 'terragrunt apply -auto-approve tfplan'
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
    }
}
