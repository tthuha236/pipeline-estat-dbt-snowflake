# create virtual env
python -m venv venv
source venv/bin/activate

# check dbt compatible python version before installing
pip install dbt-core
pip install dbt-snowflake 

# create dbt profile
mkdir ~/.dbt

# init dbt project
dbt init dbt