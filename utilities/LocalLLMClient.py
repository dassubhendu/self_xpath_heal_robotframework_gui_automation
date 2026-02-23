import requests
from robot.api.deco import keyword
from json_loader import load_json


class LocalLLMClient:
    """
    Robot Framework library for Local LLM keywords
    """

    def __init__(self):
        pass

    @keyword("Get LLM Response")
    def get_llm_response(self,
                         prompt: str,
                         config_path: str = "utilities/LocalLLMConfig.json") -> str:
        """
        Calls the LLM API using the given config file
        and returns only the 'response' field.

        Robot Example:
            ${resp}=    Get LLM Response    Hello
        """

        llm_cfg = load_json(config_path)

        url = llm_cfg["baseurl"] + llm_cfg["endpoint"]

        payload = {
            "model": llm_cfg["model"],
            "prompt": prompt,
            "stream": llm_cfg.get("stream", False),
            "temperature": llm_cfg.get("temperature", 0.1),
            "max_tokens": llm_cfg.get("max_tokens", 1000)
        }

        headers = {
            "Content-Type": "application/json"
        }

        try:
            r = requests.post(
                url,
                json=payload,
                headers=headers,
                timeout=llm_cfg.get("timeout", 600)
            )
            r.raise_for_status()
            return r.json().get("response", "")
        except requests.exceptions.RequestException as e:
            raise RuntimeError(f"Failed to call LLM API: {e}")



## ========================================================================

# import requests
# from robot.api.deco import keyword

# @keyword("Get LLM Response")
# def get_llm_response(prompt: str) -> str:
#     """
#     Calls the local LLM API and returns only the 'response' field.
#     Example in Robot Framework:
#     | ${resp}= | Get LLM Response | Why is the sky blue? |
#     """
#     url = "http://localhost:11434/api/generate"
#     payload = {
#         "model": "qwen3:4b",
#         "prompt": prompt,
#         "stream": False
#     }
#     headers = {
#         "Content-Type": "application/json"
#     }

#     try:
#         r = requests.post(url, json=payload, headers=headers, timeout=180)
#         r.raise_for_status()
#         data = r.json()
#         return data.get("response", "")
#     except requests.exceptions.RequestException as e:
#         raise RuntimeError(f"Failed to call LLM API: {e}")