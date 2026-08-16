pipeline {
    agent any

    environment {

        // AWS Configuration
        AWS_REGION     = 'ap-south-2'
        AWS_ACCOUNT_ID = '944765969321'

        // Terraform Directory
        TF_DIR = 'terraform'

        // Ansible Directory
        ANSIBLE_DIR = 'ansible'

        // ECR Repositories
        FRONTEND_REPO = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/shopnow-frontend"
        ADMIN_REPO    = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/shopnow-admin"
        BACKEND_REPO  = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/shopnow-backend"

        IMAGE_TAG = 'latest'
        // KUBERNETES
        EKS_CLUSTER_NAME = 'shopnow-eks'
        K8S_DIR = 'k8s'
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
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    dir("${TF_DIR}") {
                        sh '''
                            export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                            export AWS_DEFAULT_REGION=$AWS_REGION
        
                            aws sts get-caller-identity
        
                            terraform init
                        '''
                    }
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
        stage('Get Frontend IP') {
            steps {
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    dir("${TF_DIR}") {
                        script {
                            env.FRONTEND_IP = sh(
                                script: '''
                                    export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                                    export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                                    export AWS_DEFAULT_REGION=$AWS_REGION

                                    terraform output -raw frontend_public_ip
                                ''',
                                returnStdout: true
                            ).trim()

                            echo "Frontend EC2 Public IP: ${env.FRONTEND_IP}"
                        }
                    }
                }
            }
        }
        // ANSIBLE
        stage('Generate Ansible Inventory') {
            steps {
                sh '''
                    mkdir -p ${ANSIBLE_DIR}

                    cat > ${ANSIBLE_DIR}/inventory.ini <<EOF
[frontend]
${FRONTEND_IP} ansible_user=ubuntu
EOF

                    echo "=========================================="
                    echo "Generated Ansible Inventory"
                    echo "=========================================="

                    cat ${ANSIBLE_DIR}/inventory.ini
                '''
            }
        }

        stage('Test Ansible Connection') {
            steps {
                sshagent(credentials: ['shopnow-ec2-key']) {
                    sh '''
                        ansible frontend \
                            -i ${ANSIBLE_DIR}/inventory.ini \
                            -m ping \
                            --ssh-common-args='-o StrictHostKeyChecking=no'
                    '''
                }
            }
        }
        stage('Ansible Configuration') {
            steps {
                sshagent(credentials: ['shopnow-ec2-key']) {
                    sh '''
                        ansible-playbook \
                            -i ${ANSIBLE_DIR}/inventory.ini \
                            ${ANSIBLE_DIR}/setup.yml \
                            --ssh-common-args='-o StrictHostKeyChecking=no'
                    '''
                }
            }
        }
         
        // 10. CONFIGURE KUBECTL
        stage('Configure kubectl for EKS') {
            steps {

                withCredentials([
                    string(
                        credentialsId: 'AWS_ACCESS_KEY',
                        variable: 'AWS_ACCESS_KEY_ID'
                    ),

                    string(
                        credentialsId: 'AWS_SECRET_KEY',
                        variable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {

                    sh '''
                        export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                        export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                        export AWS_DEFAULT_REGION=$AWS_REGION

                        echo "Updating kubeconfig..."

                        aws eks update-kubeconfig \
                            --region $AWS_REGION \
                            --name $EKS_CLUSTER_NAME

                        echo "Checking Kubernetes cluster..."

                        kubectl get nodes
                    '''
                }
            }
        }


        // ==================================================
        // 11. VERIFY EKS
        // ==================================================

        stage('Verify EKS Cluster') {

            steps {

                withCredentials([
                    string(
                        credentialsId: 'AWS_ACCESS_KEY',
                        variable: 'AWS_ACCESS_KEY_ID'
                    ),

                    string(
                        credentialsId: 'AWS_SECRET_KEY',
                        variable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {

                    sh '''
                        export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                        export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                        export AWS_DEFAULT_REGION=$AWS_REGION

                        echo "EKS Cluster Status:"

                        aws eks describe-cluster \
                            --region $AWS_REGION \
                            --name $EKS_CLUSTER_NAME \
                            --query "cluster.status" \
                            --output text

                        echo "Kubernetes Nodes:"

                        kubectl get nodes -o wide
                    '''
                }
            }
        }
        // 12. DEPLOY FRONTEND
        stage('Deploy Frontend to EKS') {

            steps {

                sh '''
                    echo "Deploying ShopNow Frontend..."

                    kubectl apply \
                        -f $K8S_DIR/frontend-deployment.yaml

                    kubectl apply \
                        -f $K8S_DIR/frontend-service.yaml
                '''
            }
        }
        // 13. DEPLOY FRONTEND HPA
        stage('Deploy Frontend HPA') {

            steps {

                sh '''
                    echo "Deploying Frontend HPA..."

                    kubectl apply \
                        -f $K8S_DIR/frontend-hpa.yaml
                '''
            }
        }
        // 14. WAIT FOR FRONTEND ROLLOUT
        stage('Wait for Frontend Deployment') {

            steps {

                sh '''
                    echo "Waiting for frontend deployment..."

                    kubectl rollout status \
                        deployment/shopnow-frontend \
                        --timeout=5m
                '''
            }
        }
        // 15. VERIFY FRONTEND PODS
        stage('Verify Frontend Pods') {

            steps {

                sh '''
                    echo "Frontend Pods:"

                    kubectl get pods \
                        -l app=shopnow-frontend \
                        -o wide
                '''
            }
        }

        // 16. VERIFY FRONTEND SERVICE
        stage('Verify Frontend Service') {

            steps {

                sh '''
                    echo "Frontend Service:"

                    kubectl get service shopnow-frontend-service
                '''
            }
        }
        // 17. VERIFY HPA
        stage('Verify Frontend HPA') {

            steps {

                sh '''
                    echo "Frontend HPA:"

                    kubectl get hpa shopnow-frontend-hpa
                '''
            }
        }
        // 18. DISPLAY FINAL STATUS
        stage('Kubernetes Deployment Status') {

            steps {

                sh '''
                    echo "=========================================="
                    echo "EKS CLUSTER"
                    echo "=========================================="

                    kubectl get nodes

                    echo ""
                    echo "=========================================="
                    echo "FRONTEND DEPLOYMENT"
                    echo "=========================================="

                    kubectl get deployment shopnow-frontend

                    echo ""
                    echo "=========================================="
                    echo "FRONTEND PODS"
                    echo "=========================================="

                    kubectl get pods \
                        -l app=shopnow-frontend

                    echo ""
                    echo "=========================================="
                    echo "FRONTEND SERVICE"
                    echo "=========================================="

                    kubectl get service shopnow-frontend-service

                    echo ""
                    echo "=========================================="
                    echo "FRONTEND HPA"
                    echo "=========================================="

                    kubectl get hpa shopnow-frontend-hpa
                '''
            }
        }
        stage('Cleanup') {
            steps {
                sh '''
                docker image prune -af
                docker builder prune -af
                '''
            }
        }
    }

    post {

        success {

            echo '''
            ==========================================
            SHOPNOW CI/CD PIPELINE SUCCESS
            ==========================================

            Docker Images:
            Successfully built and pushed to ECR

            Infrastructure:
            Terraform provisioning completed
            Ansible Configuration Completed

            EKS:
            Cluster configured successfully

            Frontend:
            Successfully deployed to Kubernetes

            Service:
            Kubernetes LoadBalancer created

            HPA:
            Frontend autoscaling configured

            ==========================================
            '''
        }


        failure {

            echo '''
            ==========================================
            SHOPNOW PIPELINE FAILED
            ==========================================

            Please check the failed Jenkins stage
            and review the console output.

            ==========================================
            '''
        }
    }
}