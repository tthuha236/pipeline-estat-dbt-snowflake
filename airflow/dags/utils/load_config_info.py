import yaml
from pathlib import Path
from copy import deepcopy

def deep_merge(dict1, dict2):
    """Recursively merge dict2 into dict1"""
    result = deepcopy(dict1)
    if not dict2: return result
    for k, v in dict2.items():
        if k in result and isinstance(result[k], dict) and isinstance(v, dict):
            result[k] = deep_merge(result[k], v)
        else:
            result[k] = v
    return result

def load_config(dag_id):
    base_path = Path(__file__).parents[2]/"config"/"base_config.yaml"
    dag_path = Path(__file__).parents[2]/"config"/f"{dag_id}_config.yaml"
    with open(base_path, "r") as f:
        base_config = yaml.safe_load(f)
    with open(dag_path, "r") as f:
        dag_config = yaml.safe_load(f)
    config = deep_merge(base_config, dag_config)
    return config