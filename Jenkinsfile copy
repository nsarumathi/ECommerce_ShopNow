```groovy
pipeline {
    agent any

    environment {

        AWS_REGION = 'ap-south-2'
        AWS_ACCOUNT_ID = '944765969321'

        FRONTEND_REPO = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/shopnow-frontend"
        ADMIN_REPO    = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/shopnow-admin"
        BACKEND_REPO  = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/shopnow-backend"

        IMAGE_TAG = 'latest'
    }

    stages {

        stage('Clone Source Code') {
            steps {
                git branch: 'main',
                url: 'https://github.com/nsarumathi/ECommerce_ShopNow.git'
            }
        }

        stage('Docker Build') {
            steps {

                withCredentials([

                    string(credentialsId: 'AWS_ACCESS_KEY', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_KEY', variable: 'AWS_SECRET_ACCESS_KEY')

                ]) {

                    sh '''
                    export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                    export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                    export AWS_REGION=$AWS_REGION

                    docker compose build
                    '''
                }
            }
        }

        stage('AWS ECR Login') {
            steps {
                sh '''
                aws ecr get-login-password --region $AWS_REGION | \
                docker login \
                --username AWS \
                --password-stdin \
                $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
                '''
            }
        }

        stage('Tag Images') {
            steps {
                sh '''
                docker tag shopnow-frontend:latest $FRONTEND_REPO:$IMAGE_TAG
                docker tag shopnow-admin:latest $ADMIN_REPO:$IMAGE_TAG
                docker tag shopnow-backend:latest $BACKEND_REPO:$IMAGE_TAG
                '''
            }
        }

        stage('Push Images to ECR') {
            steps {
                sh '''
                docker push $FRONTEND_REPO:$IMAGE_TAG
                docker push $ADMIN_REPO:$IMAGE_TAG
                docker push $BACKEND_REPO:$IMAGE_TAG
                '''
            }
        }

        stage('Cleanup') {
            steps {
                sh '''
                docker image prune -af
                '''
            }
        }
    }

    post {
        success {
            echo '✅ All Docker Images Successfully Pushed To AWS ECR'
        }

        failure {
            echo '❌ Pipeline Failed'
        }

        always {
            cleanWs()
        }
    }
}
```
