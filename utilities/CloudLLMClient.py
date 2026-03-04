import requests
from robot.api.deco import keyword
from json_loader import load_json


class CloudLLMClient:

    @keyword("Get LLM Response Cloud")
    def get_llm_response(self, prompt, config_path="utilities/CloudLLMConfig.json"):

        llm_cfg = load_json(config_path)

        url = llm_cfg["baseurl"] + llm_cfg["endpoint"]

        headers = {
            "Authorization": f"Bearer {llm_cfg['apikey']}",
            "Content-Type": "application/json"
        }

        payload = {
            "model": llm_cfg["model"],
            "prompt": prompt,
            "stream": llm_cfg.get("stream", False)
        }

        response = requests.post(url, headers=headers, json=payload)

        print("STATUS:", response.status_code)
        print("RESPONSE:", response.text)

        if response.status_code != 200:
            raise RuntimeError(response.text)

        return response.json().get("response", "")