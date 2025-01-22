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
                        sh pwd
                        sh 'terragrunt init --terragrunt-non-interactive'
                        sh 'terragrunt plan -out=tfplan'
                        input message: 'Do you want to apply the Foundation changes?'
                        sh 'terragrunt apply -auto-approve tfplan'
                    }
                }
            }
        }
        
        stage('Storage Infrastructure') {
            steps {
                dir('terraform/storage') {
                    withEnv(["ENV=${params.ENV}"]) {
                        sh 'terragrunt init --terragrunt-non-interactive'
                        sh 'terragrunt plan -out=tfplan'
                        input message: 'Do you want to apply the Storage changes?'
                        sh 'terragrunt apply -auto-approve tfplan'
                    }
                }
            }
        }
        
        stage('Compute Infrastructure') {
            steps {
                dir('terraform/compute') {
                    withEnv(["ENV=${params.ENV}"]) {
                        sh 'terragrunt init --terragrunt-non-interactive'
                        sh 'terragrunt plan -out=tfplan'
                        input message: 'Do you want to apply the Compute changes?'
                        sh 'terragrunt apply -auto-approve tfplan'
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
                rm -f terraform/compute/tfplan
            '''
        }
    }
}
