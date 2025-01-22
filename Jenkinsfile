```groovy
pipeline {
    agent any
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build') {
            steps {
                sh 'echo "Building..."'
                // Add your build steps here
            }
        }
        
        stage('Test') {
            steps {
                sh 'echo "Testing..."'
                // Add your test steps here
            }
        }
    }
}
```