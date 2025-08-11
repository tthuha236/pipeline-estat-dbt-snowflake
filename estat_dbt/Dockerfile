FROM ghcr.io/dbt-labs/dbt-core:1.10.6
WORKDIR /usr/app
RUN pip install dbt-snowflake
COPY . /usr/app
COPY ./config/profiles.yml /root/.dbt/profiles.yml