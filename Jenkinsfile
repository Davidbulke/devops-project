pipeline {
    agent any
    tools {
        maven "MAVEN3.9.9"
        jdk "JDK17"
    }

    environment {
        SNAP_REPO = 'vprofile-snapshot'
        RELEASE_REPO = 'vprofile-release'
        CENTRAL_REPO = 'vpro-maven-central'
        NEXUSIP = '172.31.22.203'
        NEXUSPORT = '8081'
        NEXUS_GRP_REPO = 'vpro-maven-group'
        NEXUS_LOGIN ='NexusLogin'
        SONARSERVE = 'sonarserver'
        SONARSCANNER = 'sonarscanner'
    }

    stages {
        stage('Build'){
            steps {
                withCredentials([usernamePassword(credentialsId: 'NexusLogin', usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {
                    sh 'mvn -s settings.xml -DskipTests install'
                }
            }

            post {
                success {
                    echo "Now Archiving."
                    archiveArtifacts artifacts: '**/*.war'
                }
            }
        }

        stage('Test') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'NexusLogin', usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {
                    sh 'mvn -s settings.xml test'
                }
            }
        }

        stage('Checkstyle Analysis') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'NexusLogin', usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {
                    sh 'mvn -s settings.xml checkstyle:check'
                }
            }
        }

        stage('Sonar Analysis') {
                    environment {
                        scannerHome = tool "${SONARSCANNER}"
                    }
                    steps {
                    withSonarQubeEnv("${SONARSERVER}") {
                        sh '''${scannerHome}/bin/sonar-scanner -Dsonar.projectKey=vprofile \
                        -Dsonar.projectName=vprofile \
                        -Dsonar.projectVersion=1.0 \
                        -Dsonar.sources=src/ \
                        -Dsonar.java.binaries=target/test-classes/com/visualpathit/account/controllerTest/ \
                        -Dsonar.junit.reportsPath=target/surefire-reports/ \
                        -Dsonar.jacoco.reportsPath=target/jacoco.exec \
                        -Dsonar.java.checkstyle.reportPaths=target/checkstyle-result.xml'''
                }
            }
        }

    } // End of stages
} // End of pipeline
