pipelineJob('airflow-pipeline'){
    description('Jenkins job to pull the latest code to airflow ec2 instance if new commit is pushed to airflow folder')
    definition {
        cpsScm {
            scm {
                git {
                    remote {
                        url('https://github.com/tthuha236/pipeline-estat-dbt-snowflake.git')
                    }
                    branch('main')
                }
            }
            scriptPath('airflow/Jenkinsfile')
        }
    }
    triggers {
        githubPush()
    }
}