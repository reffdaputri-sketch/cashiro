import wave
import math
import struct
import os

def generate_tone(filename, freqs_durations, sample_rate=44100):
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)
        
        for freq, duration in freqs_durations:
            num_samples = int(sample_rate * duration)
            for i in range(num_samples):
                value = math.sin(2.0 * math.pi * freq * (i / sample_rate))
                # Envelope: quick attack, slow decay
                envelope = math.exp(-i / (sample_rate * 0.15))
                value = value * envelope * 0.5
                
                packed_value = struct.pack('<h', int(value * 32767.0))
                wav_file.writeframes(packed_value)

# notification (new order): C5, E5
generate_tone('f:/KIOSLY/mobile/assets/sounds/notification.wav', [(523.25, 0.3), (659.25, 0.6)])
generate_tone('f:/KIOSLY/windows_app/assets/sounds/notification.wav', [(523.25, 0.3), (659.25, 0.6)])

# ready (order ready): C5, E5, G5
generate_tone('f:/KIOSLY/mobile/assets/sounds/ready.wav', [(523.25, 0.15), (659.25, 0.15), (783.99, 0.6)])
generate_tone('f:/KIOSLY/windows_app/assets/sounds/ready.wav', [(523.25, 0.15), (659.25, 0.15), (783.99, 0.6)])
