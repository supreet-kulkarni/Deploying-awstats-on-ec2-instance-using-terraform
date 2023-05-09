pipeline {
    
    environment {
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
    }
    
    agent any

    stages {

        stage('terraform init') {
            steps {
                sh('terraform init')
            }
        }
        stage('terraform validate') {
            steps {
                sh('terraform validate')
            }
        }
        stage('terraform plan') {
            steps {
                sh('terraform plan')
            }
        }
        stage ("terraform Action") {
            steps {
                echo "Terraform action is --> ${action}"
                sh ('terraform ${action} --auto-approve') 
           }
        }
    }
}
