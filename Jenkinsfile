pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = 'dockerhub-creds'
        IMAGE_NAME = 'shanmugapriya2390/trend-app'
        EKS_CLUSTER = 'trend-eks-cluster'
        AWS_DEFAULT_REGION = 'ap-south-1'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/Shanmugapriya2390/Trend-DevOps-Project.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    docker build \
                      -t ${IMAGE_NAME}:${BUILD_NUMBER} \
                      -t ${IMAGE_NAME}:latest .
                '''
            }
        }

        stage('Push to Docker Hub') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: "${DOCKERHUB_CREDENTIALS}",
                    usernameVariable: 'DOCKERHUB_USER',
                    passwordVariable: 'DOCKERHUB_TOKEN'
                )]) {
                    sh '''
                        set +x
                        echo "$DOCKERHUB_TOKEN" | docker login \
                          -u "$DOCKERHUB_USER" --password-stdin

                        docker push "${IMAGE_NAME}:${BUILD_NUMBER}"
                        docker push "${IMAGE_NAME}:latest"

                        docker logout
                    '''
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                sh '''
                    set -e

                    aws sts get-caller-identity

                    kubectl set image deployment/trend-app \
                      trend-app=${IMAGE_NAME}:${BUILD_NUMBER} \
                      --namespace=default

                    kubectl rollout status deployment/trend-app \
                      --namespace=default \
                      --timeout=180s

                    kubectl get deployment trend-app \
                      --namespace=default
                '''
            }
        }
    }

    post {
        always {
            sh 'docker image prune -f'
        }
    }
}