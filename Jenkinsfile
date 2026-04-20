pipeline {
    agent { label "bond" }

    environment {
        IMAGE_NAME = "tejasathalye/next_calculator"
        CONTAINER_NAME = "next_calc_instance"
        CONTAINER_PORT = "80"
        HOST_PORT = "81"

        SSH_CREDENTIALS = "3tierkey"
        PROD_IP = "15.206.88.48"
        DEV_IP = "13.233.119.16"
        MAIN_IP = "13.203.227.174"
    }

    stages {
        stage("Checkout") {
            steps {
                checkout scm
            }
        }

        stage("Build Docker Image") {
            steps {
                sh '''
                echo "Building Docker image"
                sudo docker build -t $IMAGE_NAME:$BRANCH_NAME .
                '''
            }
        }

        stage("Push to Docker Hub") {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker_creds',
                                                 usernameVariable: 'DOCKER_USER',
                                                 passwordVariable: 'DOCKER_PASS')]) {

                    sh '''
                    echo "Pushing Docker Image to Docker Hub"
                    echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                    sudo docker push $IMAGE_NAME:$BRANCH_NAME
                    '''
                }
            }
        }

        stage("Deploy to Environment") {
            steps {
                script {
                    if (env.BRANCH_NAME == "main") {
                        deployToServer(MAIN_IP)
                    } else if (env.BRANCH_NAME == "dev") {
                        deployToServer(DEV_IP)
                    } else if (env.BRANCH_NAME == "prod") {
                        deployToServer(PROD_IP)
                    } else {
                        echo "No deployment for this branch: ${env.BRANCH_NAME}"
                    }
                }
            }
        }
    }

    post {
        success {
            echo "Deployment successful"
        }
        failure {
            echo "Deployment failed"
        }
    }
}

def deployToServer(serverIp) {
    sshagent([SSH_CREDENTIALS]) {
        sh """
        ssh -o StrictHostKeyChecking=no ubuntu@${serverIp} '
            sudo docker stop ${CONTAINER_NAME} || true
            sudo docker rm ${CONTAINER_NAME} || true

            sudo docker pull ${IMAGE_NAME}:${BRANCH_NAME}

            sudo docker run -d -p ${HOST_PORT}:${CONTAINER_PORT} \
                --name ${CONTAINER_NAME} \
                ${IMAGE_NAME}:${BRANCH_NAME}
        '
        """
    }
}
