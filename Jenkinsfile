pipeline {
    agent {
        label 'node-ec'
    }

    /*environment {
        AWS_REGION = "your-aws-region"
        ECR_REPO = "your-ecr-repository-name"
        EKS_CLUSTER = "your-eks-cluster-name"
        REGISTRY = "your-registry-url"
    }*/

    stages {
        stage('Checkout Source Code') {
            steps {
                checkout scm
            }
        }

        stage('Build & Push to ECR') {
            steps {
                script {
                    sh "docker build -t ${env.REGISTRY}/${env.ECR_REPO}:latest ."
                    sh "docker tag ${env.REGISTRY}/${env.ECR_REPO}:latest ${env.REGISTRY}/${env.ECR_REPO}:${BUILD_NUMBER}"
                    sh """
                        aws ecr get-login-password --region ${env.AWS_REGION} | \
                        docker login --username AWS --password-stdin ${env.REGISTRY}
                    """
                    sh "docker push ${env.REGISTRY}/${env.ECR_REPO}:latest"
                    sh "docker push ${env.REGISTRY}/${env.ECR_REPO}:${BUILD_NUMBER}"
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                script {
                    sh "aws eks update-kubeconfig --name ${env.EKS_CLUSTER} --region ${env.AWS_REGION}"
                    sh """
                        kubectl get secret regcred || \
                        kubectl create secret docker-registry regcred \
                        --docker-server=${env.REGISTRY} \
                        --docker-username=AWS \
                        --docker-password=\$(aws ecr get-login-password --region ${env.AWS_REGION})
                    """
                    sh "helm upgrade --install webapp-stack helm/appcharts --namespace default --set appimage=${env.REGISTRY}/${env.ECR_REPO},apptag=${BUILD_NUMBER}"
                    sh "kubectl get pods -A"
                    sh "kubectl get ingress"
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline finished.'
        }
    }
}
