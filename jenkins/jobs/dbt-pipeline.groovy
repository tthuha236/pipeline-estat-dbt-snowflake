pipelineJob('dbt-pipeline'){
    description('Jenkins job to create and push dbt image using the Jenkinsfile in dbt folder')
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
            scriptPath('estat_dbt/Jenkinsfile')
        }
    }
    triggers {
        githubPush()
    }
}