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
    skipDefaultCheckout(true)
  }

  parameters {
    choice(name: 'ACTION', choices: ['plan', 'apply', 'destroy'], description: 'Terraform action')
    string(name: 'CONFIRM_APPLY', defaultValue: '', description: 'Type APPLY to allow terraform apply')
    string(name: 'CONFIRM_DESTROY', defaultValue: '', description: 'Type DESTROY to allow terraform destroy')
  }

  environment {
    AWS_REGION       = 'us-east-2'
    AWS_DEFAULT_REGION = 'us-east-2'
    TF_IN_AUTOMATION = 'true'
  }

  stages {
    stage('Git Checkout') {
      steps {
        checkout scm
      }
    }

    // ---- IAM / AWS auth verification (fast fail) ----
    stage('AWS Identity Check') {
      steps {
        sh '''
          set -euo pipefail

          echo "== AWS CLI version =="
          aws --version

          echo "== AWS credential source (debug) =="
          # Shows whether it is using env vars, shared config, or instance profile
          aws configure list || true

          echo "== Caller identity (MUST succeed) =="
          aws sts get-caller-identity

          echo "== Region check =="
          aws configure get region || true
          echo "AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION"
        '''
      }
    }

    stage('Terraform Init') {
      steps {
        sh '''
          set -euo pipefail
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
          terraform plan -input=false -out=tfplan
          ls -lah tfplan
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
          if (!fileExists('tfplan')) {
            error("Apply blocked: tfplan not found. Run ACTION=plan or ensure plan stage created tfplan.")
          }
        }
      }
    }

    // Re-check IAM immediately before doing changes (catches expiring/removed creds)
    stage('AWS Identity Re-Check (pre-apply/destroy)') {
      when { expression { params.ACTION == 'apply' || params.ACTION == 'destroy' } }
      steps {
        sh '''
          set -euo pipefail
          echo "== Caller identity (pre-change) =="
          aws sts get-caller-identity
        '''
      }
    }

    stage('Terraform Apply') {
      when { expression { params.ACTION == 'apply' } }
      steps {
        sh '''
          set -euo pipefail
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
