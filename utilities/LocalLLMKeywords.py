import requests
from robot.api.deco import keyword

@keyword("Get LLM Response")
def get_llm_response(prompt: str) -> str:
    """
    Calls the local LLM API and returns only the 'response' field.
    Example in Robot Framework:
    | ${resp}= | Get LLM Response | Why is the sky blue? |
    """
    url = "http://localhost:11434/api/generate"
    payload = {
        "model": "qwen3:4b",
        "prompt": prompt,
        "stream": False
    }
    headers = {
        "Content-Type": "application/json"
    }

    try:
        r = requests.post(url, json=payload, headers=headers, timeout=180)
        r.raise_for_status()
        data = r.json()
        return data.get("response", "")
    except requests.exceptions.RequestException as e:
        raise RuntimeError(f"Failed to call LLM API: {e}")