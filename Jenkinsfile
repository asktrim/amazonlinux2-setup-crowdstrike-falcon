pipeline {
    agent any
    stages {
        stage('Download_WizCLI') {
            steps {
                      // Download_WizCLI
                      // Removal or Modification of the following Jenkins file for the integration of WizCLI is a violation of company policy and can result in disciplinary action.  If you have any questions or issues, please reach out to Cloud Security Engineering Cloud Security Engineering(https://onemain.atlassian.net/wiki/spaces/CE/pages/19352388162/Cloud+Security+Engineering).  We appreciate your support in ensuring we operate safely and securely.
                      sh 'echo "Downloading wizcli..."'
                      sh 'curl -o wizcli https://wizcli.app.wiz.io/wizcli'
                      sh 'chmod +x wizcli'
            } 
        }
        stage('Auth_With_Wiz') {
            steps {
            // Auth with Wiz
            sh 'echo "Authenticating to the Wiz API..."'
            withCredentials([usernamePassword(credentialsId: 'wizcli', usernameVariable: 'ID', passwordVariable: 'SECRET')]) {
                sh './wizcli auth --id $ID --secret $SECRET'}
            }
        }
        stage('Wiz IAC scan') {
            steps {
                script { 
                    // Wiz IAC scan
                    // Removal or Modification of the following Jenkins file for the integration of WizCLI is a violation of company policy and can result in disciplinary action.  If you have any questions or issues, please reach out to Cloud Security Engineering Cloud Security Engineering(https://onemain.atlassian.net/wiki/spaces/CE/pages/19352388162/Cloud+Security+Engineering).  We appreciate your support in ensuring we operate safely and securely.
                    env.GIT_REPO_NAME = env.GIT_URL.replaceFirst(/^.*\/([^\/]+?).git$/, '$1')
                    sh "./wizcli iac scan --path . --tag repo=asktrim-$GIT_REPO_NAME --tag branch=$GIT_BRANCH --tag commit=$GIT_COMMIT  -p custom-policy-secrets --policy-hits-only  "
                    sh "./wizcli iac scan --path . --tag repo=asktrim-$GIT_REPO_NAME --tag branch=$GIT_BRANCH --tag commit=$GIT_COMMIT  -p custom-policy-high-critical-severity-misconfigurations --policy-hits-only  "

                }
            } 
        }
    }
}
