#!groovy
pipeline {
    agent any
    options { skipDefaultCheckout true }
    stages {
        stage('Checkout'){
            steps {
                checkout scm
            }
        }
        stage('Build') {
            environment {
                DOCKER_IMAGE = 'etejeda/hello-app-golang'
            }
            steps {
                script {
                    def customImage = docker.build("${DOCKER_IMAGE}", " -f hello-app/Dockerfile .")
                    docker.withRegistry("", 'dockerHub') {
                        customImage.push("${BUILD_NUMBER}")
                    }
                }
            }
        }
        stage('Test'){
            steps {
                echo 'Unit Tests'
            }
        }
        stage('Deploy to Production'){
            steps {
                script {
                    echo 'Hey!'
                }
            }
        }
    }
}
