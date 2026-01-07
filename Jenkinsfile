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
      steps { checkout scm }
    }

    stage('Safety Check (protect Jenkins)') {
      steps {
        sh '''
          set -euo pipefail

          # Fail if this repo looks like it manages the Jenkins controller itself.
          # Adjust patterns to match your Jenkins-controller naming if needed.
          if grep -R --line-number -E 'aws_instance\\s+"jenkins"|jenkins-al2023-ec2|jenkins-al2023-role|jenkins-al2023-instance-profile' ./*.tf 2>/dev/null; then
            echo "ERROR: This workspace appears to manage the Jenkins controller resources. Refusing to continue."
            exit 2
          fi
        '''
      }
    }

    stage('AWS Identity Check') {
      steps {
        sh '''
          set -euo pipefail
          echo "== AWS CLI version =="
          aws --version

          echo "== AWS credential source (debug) =="
          aws configure list

          echo "== Caller identity (MUST succeed) =="
          aws sts get-caller-identity --no-cli-pager
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
            error("Apply blocked: tfplan not found. Ensure plan stage created tfplan.")
          }
        }
      }
    }

    stage('AWS Identity Re-Check (pre-apply/destroy)') {
      when { expression { params.ACTION == 'apply' || params.ACTION == 'destroy' } }
      steps {
        sh '''
          set -euo pipefail
          echo "== Re-checking caller identity before sensitive action =="
          aws sts get-caller-identity --no-cli-pager
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
