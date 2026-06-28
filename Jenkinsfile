pipeline {
    agent any

    environment {

        // AWS Configuration
        AWS_REGION     = 'ap-south-2'
        AWS_ACCOUNT_ID = '944765969321'

        // Terraform Directory
        TF_DIR = 'ECommerce_ShopNow/terraform'

        // ECR Repositories
        FRONTEND_REPO = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/shopnow-frontend"
        ADMIN_REPO    = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/shopnow-admin"
        BACKEND_REPO  = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/shopnow-backend"

        IMAGE_TAG = 'latest'
    }

    stages {
        // Docker Build

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
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh '''
                        export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                        export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                        export AWS_DEFAULT_REGION=$AWS_REGION
        
                        aws sts get-caller-identity
        
                        aws ecr get-login-password --region $AWS_REGION | \
                        docker login \
                        --username AWS \
                        --password-stdin \
                        $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
                    '''
                }
            }
       }

        stage('Tag Docker Images') {
            steps {
                sh '''
                docker tag shopnow-frontend:latest $FRONTEND_REPO:$IMAGE_TAG
                docker tag shopnow-admin:latest $ADMIN_REPO:$IMAGE_TAG
                docker tag shopnow-backend:latest $BACKEND_REPO:$IMAGE_TAG
                '''
            }
        }

        stage('Push Images to AWS ECR') {
            steps {
                sh '''
                docker push $FRONTEND_REPO:$IMAGE_TAG
                docker push $ADMIN_REPO:$IMAGE_TAG
                docker push $BACKEND_REPO:$IMAGE_TAG
                '''
            }
        }
        // Terraform Provisioning
        
        stage('Terraform Init') {
            steps {
                dir("${TF_DIR}") {
                    sh 'terraform init'
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                dir("${TF_DIR}") {
                    sh 'terraform validate'
                }
            }
        }

        stage('Terraform Format Check') {
            steps {
                dir("${TF_DIR}") {
                    sh 'terraform fmt -check'
                }
            }
        }

        stage('Terraform Plan') {
            steps {

                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {

                    dir("${TF_DIR}") {

                        sh '''
                        export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                        export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                        export AWS_DEFAULT_REGION=$AWS_REGION

                        terraform plan -out=tfplan
                        '''

                    }

                }

            }
        }

        stage('Terraform Apply') {
            steps {

                input message: 'Approve Terraform Apply?', ok: 'Deploy Infrastructure'

                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {

                    dir("${TF_DIR}") {

                        sh '''
                        export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                        export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                        export AWS_DEFAULT_REGION=$AWS_REGION

                        terraform apply -auto-approve tfplan
                        '''

                    }

                }

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
            echo '=========================================='
            echo 'Docker Images Successfully Pushed to AWS ECR'
            echo 'Terraform Infrastructure Provisioned'
            echo 'Pipeline Completed Successfully'
            echo '=========================================='
        }

        failure {
            echo '=========================================='
            echo 'Pipeline Failed'
            echo '=========================================='
        }

        always {
            cleanWs()
        }
    }
}

