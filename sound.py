import requests

API_KEY = "sk_4299ad365809940b1b345f1496a8a1a1aef5a0ae82352c85"
VOICE_ID = "21m00Tcm4TlvDq8ikWAM"  # voice default ElevenLabs

url = f"https://api.elevenlabs.io/v1/text-to-speech/{VOICE_ID}"

headers = {
    "Accept": "audio/mpeg",
    "Content-Type": "application/json",
    "xi-api-key": API_KEY
}

data = {
    "text": "Yang penting sekarang sistem kamu sudah jalan mulus pakai Minimax Speech 2.8 Turbo 🚀 ElevenLabs bisa dicoba lagi kapanpun kalau sudah dapat key yang valid!.",
    "model_id": "eleven_multilingual_v2",
    "voice_settings": {
        "stability": 0.5,
        "similarity_boost": 0.75
    }
}

response = requests.post(url, json=data, headers=headers)

if response.status_code == 200:
    with open("output.mp3", "wb") as f:
        f.write(response.content)
    print("Audio berhasil dibuat: output.mp3")
else:
    print("Error:", response.text)