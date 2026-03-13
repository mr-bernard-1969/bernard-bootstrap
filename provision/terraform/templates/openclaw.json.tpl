{
  "meta": { "lastTouchedVersion": "2026.3.2" },
  "agents": {
    "defaults": {
      "model": "litellm/${litellm_model_id}",
      "models": {
        "litellm/${litellm_model_id}": {
          "alias": "sonnet",
          "params": { "cacheRetention": "short" }
        }
      },
      "contextPruning": { "mode": "cache-ttl", "ttl": "1h" },
      "compaction": { "mode": "safeguard" },
      "heartbeat": { "every": "30m" }
    }
  },
  "models": {
    "providers": {
      "litellm": {
        "baseUrl": "${litellm_base_url}",
        "apiKey": "${litellm_api_key}",
        "api": "openai-completions",
        "models": [
          {
            "id": "${litellm_model_id}",
            "name": "Claude Sonnet 4.6",
            "contextWindow": 200000,
            "maxTokens": 8192
          }
        ]
      }
    }
  },
  "commands": { "native": "auto", "nativeSkills": "auto", "restart": true, "ownerDisplay": "raw" },
  "gateway": {
    "mode": "local",
    "bind": "loopback",
    "trustedProxies": ["127.0.0.1"],
    "controlUi": {
      "allowedOrigins": ["https://${instance_name}.${domain}"],
      "allowInsecureAuth": true,
      "dangerouslyDisableDeviceAuth": true
    },
    "auth": {
      "mode": "token",
      "token": "${gateway_token}"
    }
  }
}
