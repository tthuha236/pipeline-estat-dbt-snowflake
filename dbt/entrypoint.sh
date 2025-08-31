#!/bin/bash
# clone the latest code
git clone https://github.com/tthuha236/pipeline-estat-dbt-snowflake.git
cp -r pipeline-estat-dbt-snowflake/estat_dbt/* /usr/app/
mkdir -p /root/.dbt
cp pipeline-estat-dbt-snowflake/estat_dbt/config/profiles.yml /root/.dbt/profiles.yml