import json
from pathlib import Path
from typing import Dict, Union
from robot.api.deco import keyword

# Cache to avoid re-reading files
_JSON_CACHE: Dict[str, dict] = {}


@keyword("Load JSON File")
def load_json(file_path: Union[str, Path]) -> dict:
    """
    Load a JSON file from the given path.

    Example usage in Robot Framework:
        ${data}=    Load JSON File    config/llm.json
        ${db}=      Load JSON File    /absolute/path/to/db.json

    Args:
        file_path: Path to the JSON file (relative or absolute).

    Returns:
        Dictionary containing JSON data.

    Raises:
        FileNotFoundError: If the file does not exist.
        json.JSONDecodeError: If the file is not valid JSON.
    """
    path = Path(file_path).resolve()
    cache_key = str(path)

    if cache_key in _JSON_CACHE:
        return _JSON_CACHE[cache_key]

    if not path.exists():
        raise FileNotFoundError(f"JSON file not found: {path}")

    with path.open(encoding="utf-8") as f:
        data = json.load(f)

    _JSON_CACHE[cache_key] = data
    return data