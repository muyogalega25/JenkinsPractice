pipeline {
  agent any

  parameters {
    choice(name: 'ACTION', choices: ['plan', 'apply', 'destroy'], description: 'Terraform action')
  }

  environment {
    AWS_REGION = 'us-east-2'
  }

  stages {
    stage('Git Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Terraform Init') {
      steps {
        withCredentials([
          string(credentialsId: 'jenkins-aws-secret-key-id', variable: 'AWS_ACCESS_KEY_ID'),
          string(credentialsId: 'jenkins-aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
        ]) {
          sh '''
            export AWS_DEFAULT_REGION="$AWS_REGION"
            terraform version
            terraform init -input=false
          '''
        }
      }
    }

    stage('Terraform Plan') {
      steps {
        withCredentials([
          string(credentialsId: 'jenkins-aws-secret-key-id', variable: 'AWS_ACCESS_KEY_ID'),
          string(credentialsId: 'jenkins-aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
        ]) {
          sh '''
            export AWS_DEFAULT_REGION="$AWS_REGION"
            terraform plan -input=false -out=tfplan
          '''
        }
      }
    }

    stage('Manual Approval') {
      when {
        anyOf {
          expression { params.ACTION == 'apply' }
          expression { params.ACTION == 'destroy' }
        }
      }
      steps {
        input message: "Approve terraform ${params.ACTION}?", ok: "Yes, run it"
      }
    }

    stage('Terraform Apply') {
      when { expression { params.ACTION == 'apply' } }
      steps {
        withCredentials([
          string(credentialsId: 'jenkins-aws-secret-key-id', variable: 'AWS_ACCESS_KEY_ID'),
          string(credentialsId: 'jenkins-aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
        ]) {
          sh '''
            export AWS_DEFAULT_REGION="$AWS_REGION"
            terraform apply -input=false -auto-approve tfplan
          '''
        }
      }
    }

    stage('Terraform Destroy') {
      when { expression { params.ACTION == 'destroy' } }
      steps {
        withCredentials([
          string(credentialsId: 'jenkins-aws-secret-key-id', variable: 'AWS_ACCESS_KEY_ID'),
          string(credentialsId: 'jenkins-aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
        ]) {
          sh '''
            export AWS_DEFAULT_REGION="$AWS_REGION"
            terraform destroy -input=false -auto-approve
          '''
        }
      }
    }
  }

  post {
    success {
      withCredentials([string(credentialsId: 'slack-webhook-url', variable: 'SLACK_WEBHOOK')]) {
        sh '''
          curl -s -X POST -H 'Content-type: application/json' \
          --data "{\"text\":\"✅ Jenkins job *${JOB_NAME}* #${BUILD_NUMBER} succeeded. ACTION=${ACTION}\"}" \
          "$SLACK_WEBHOOK" >/dev/null
        '''
      }
    }
    failure {
      withCredentials([string(credentialsId: 'slack-webhook-url', variable: 'SLACK_WEBHOOK')]) {
        sh '''
          curl -s -X POST -H 'Content-type: application/json' \
          --data "{\"text\":\"❌ Jenkins job *${JOB_NAME}* #${BUILD_NUMBER} FAILED. Check console output.\"}" \
          "$SLACK_WEBHOOK" >/dev/null
        '''
      }
    }
  }
}
