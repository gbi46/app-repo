pipeline {
    agent any

    options {
        timestamps()
    }

    environment {
        // 🔐 AWS / ECR
        AWS_ACCOUNT_ID = '550127688581'
        AWS_REGION     = 'eu-central-1'
        ECR_REPOSITORY = 'django-app'

        // 🌿 env-repo (репо з charts/django-app)
        ENV_REPO_URL    = 'git@github.com:gbi46/env-repo.git'
        ENV_REPO_BRANCH = 'main'

        // 🏷 тег образу = git-коміт
        IMAGE_TAG = "${env.GIT_COMMIT}"
    }

    stages {
        stage('Checkout app repo') {
            steps {
                echo "Checking out application repository..."
                checkout scm
            }
        }

        stage('Login to ECR') {
            steps {
                sh '''
                  echo "Login to Amazon ECR..."
                  aws ecr get-login-password --region $AWS_REGION \
                    | docker login \
                        --username AWS \
                        --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
                '''
            }
        }

        stage('Build & Push Image with Kaniko') {
            steps {
                sh '''
                  echo "Building Docker image..."
                  docker build -t $ECR_REPOSITORY:$IMAGE_TAG .

                  echo "Tagging image for ECR..."
                  docker tag $ECR_REPOSITORY:$IMAGE_TAG $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:$IMAGE_TAG
                  docker tag $ECR_REPOSITORY:$IMAGE_TAG $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:latest

                  echo "Pushing image to ECR..."
                  docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:$IMAGE_TAG
                  docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:latest
                '''
            }
        }

        stage('Update Helm values in env-repo') {
            steps {
                // env-repo має бути доступний по SSH; ID кредів — у Jenkins → Credentials
                sshagent(credentials: ['env-repo-ssh-key']) {  // TODO: заміни ID, якщо в тебе інший
                    sh '''
                      echo "Cloning env-repo..."
                      rm -rf env-repo
                      git clone -b $ENV_REPO_BRANCH $ENV_REPO_URL env-repo
                      cd env-repo

                      echo "Updating charts/django-app/values.yaml with new image tag: $IMAGE_TAG"

                      # Дуже просте оновлення поля tag: ... (припускаємо, що воно є в секції image)
                      sed -i "s/^\\s*tag:\\s*.*/  tag: $IMAGE_TAG/" charts/django-app/values.yaml

                      echo "Git status after change:"
                      git status

                      git add charts/django-app/values.yaml || echo "Nothing to add"
                      git commit -m "Update django-app image tag to $IMAGE_TAG from Jenkins" || echo "Nothing to commit"
                      git push origin $ENV_REPO_BRANCH || echo "Nothing to push"
                    '''
                }
            }
        }
    }
}
