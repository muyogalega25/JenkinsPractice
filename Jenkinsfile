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

    // Safety guard for destroy
    string(name: 'CONFIRM_DESTROY', defaultValue: '', description: 'Type DESTROY to confirm terraform destroy')
  }

  environment {
    AWS_REGION       = 'us-east-2'
    TF_IN_AUTOMATION = 'true'
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

    stage('Approve Apply') {
      when { expression { params.ACTION == 'apply' } }
      steps {
        script {
          input(message: "Approve Terraform APPLY to create/update resources in AWS?", ok: "Approve Apply")
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

    stage('Approve Destroy') {
      when { expression { params.ACTION == 'destroy' } }
      steps {
        script {
          input(message: "Approve Terraform DESTROY? This will delete AWS resources.", ok: "Approve Destroy")
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
