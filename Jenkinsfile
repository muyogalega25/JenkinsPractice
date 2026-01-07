def COLOR_MAP = [
  "SUCCESS":  "good",
  "FAILURE":  "danger",
  "UNSTABLE": "warning",
  "ABORTED":  "#808080"
]

pipeline {
  agent any

  options {
    timestamps()
    disableConcurrentBuilds()
  }

  parameters {
    choice(name: 'ACTION', choices: ['plan', 'apply', 'destroy'], description: 'Terraform action')

    string(name: 'CONFIRM_APPLY', defaultValue: '', description: 'Type APPLY to allow terraform apply')
    string(name: 'CONFIRM_DESTROY', defaultValue: '', description: 'Type DESTROY to allow terraform destroy')
  }

  environment {
    AWS_REGION       = 'us-east-2'
    TF_IN_AUTOMATION = 'true'
  }

  stages {
    stage('Git Checkout') {
      steps { checkout scm }
    }

    stage('Terraform Init') {
      steps {
        sh '''
          set -euo pipefail
          export AWS_DEFAULT_REGION="$AWS_REGION"
          terraform version
          terraform init -input=false
        '''
      }
    }

    stage('Terraform Plan') {
      when { expression { params.ACTION == 'plan' || params.ACTION == 'apply' } }
      steps {
        sh '''
          set -euo pipefail
          export AWS_DEFAULT_REGION="$AWS_REGION"
          terraform plan -input=false -out=tfplan
        '''
      }
    }

    stage('Validate Apply Confirmation') {
      when { expression { params.ACTION == 'apply' } }
      steps {
        script {
          if ((params.CONFIRM_APPLY ?: '').trim() != 'APPLY') {
            error("Apply blocked: set CONFIRM_APPLY=APPLY to run terraform apply.")
          }
        }
      }
    }

    stage('Terraform Apply') {
      when { expression { params.ACTION == 'apply' } }
      steps {
        sh '''
          set -euo pipefail
          export AWS_DEFAULT_REGION="$AWS_REGION"
          terraform apply -input=false -auto-approve tfplan
        '''
      }
    }

    stage('Validate Destroy Confirmation') {
      when { expression { params.ACTION == 'destroy' } }
      steps {
        script {
          if ((params.CONFIRM_DESTROY ?: '').trim() != 'DESTROY') {
            error("Destroy blocked: set CONFIRM_DESTROY=DESTROY to run terraform destroy.")
          }
        }
      }
    }

    stage('Terraform Destroy') {
      when { expression { params.ACTION == 'destroy' } }
      steps {
        sh '''
          set -euo pipefail
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
        def color  = COLOR_MAP.get(result, "#439FE0")

        slackSend(
          channel: "#wanderprep-infra-team",
          color: color,
          message: "Build done by luvy - ${env.JOB_NAME} #${env.BUILD_NUMBER} (ACTION=${params.ACTION}, RESULT=${result}) (<${env.BUILD_URL}|Open>)"
        )
      }
    }
  }
}
