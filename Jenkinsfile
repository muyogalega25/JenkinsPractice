def COLOR_MAP = [
  "SUCCESS":  "good",
  "FAILURE":  "danger",
  "UNSTABLE": "warning",
  "ABORTED":  "#808080"
]

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
        sh '''
          set -e
          export AWS_DEFAULT_REGION="$AWS_REGION"
          terraform version
          terraform init -input=false
        '''
      }
    }

    stage('Terraform Plan') {
      steps {
        sh '''
          set -e
          export AWS_DEFAULT_REGION="$AWS_REGION"
          terraform plan -input=false -out=tfplan
        '''
      }
    }

    stage('Terraform Apply') {
      when { expression { params.ACTION == 'apply' } }
      steps {
        sh '''
          set -e
          export AWS_DEFAULT_REGION="$AWS_REGION"
          terraform apply -input=false -auto-approve tfplan
        '''
      }
    }

    stage('Terraform Destroy') {
      when { expression { params.ACTION == 'destroy' } }
      steps {
        sh '''
          set -e
          export AWS_DEFAULT_REGION="$AWS_REGION"
          terraform destroy -input=false -auto-approve
        '''
      }
    }
  }

  post {
    always {
      echo 'sending build result!'
      script {
        def result = currentBuild.currentResult ?: "UNKNOWN"
        def color  = COLOR_MAP.get(result, "#439FE0") // default Slack blue

        slackSend(
          channel: "#wanderprep-infra-team",
          color: color,
          message: "Build done by luvy - ${env.JOB_NAME} #${env.BUILD_NUMBER} (ACTION=${params.ACTION}, RESULT=${result}) (<${env.BUILD_URL}|Open>)"
        )
      }
    }
  }
}
