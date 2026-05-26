pipeline {
    agent any
    stages {
        stage('Clone Code') {
            steps {
              git branch: 'main', url: 'https://github.com/kamal-v8/Devops-Flask-App.git'
                echo 'Building...'
                // Add your build commands here
            }
        }
        stage('Test') {
            steps {
                echo 'Build Docker Image...'
                sh 'docker build -t flask-app:latest .'
            }
        }
        stage('Deploy with docker-compose') {
            steps {
              sh 'docker-compose down || true'

              sh 'docker-compose up --build -d'
            }
        }
    }
  }
