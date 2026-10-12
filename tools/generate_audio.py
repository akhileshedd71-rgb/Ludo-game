#!/usr/bin/env python3
"""Generate original, tiny game cues. Only the Python standard library is needed."""
import math
import random
import struct
import wave
from pathlib import Path

DEST = Path(__file__).resolve().parents[1] / 'assets' / 'audio'
RATE = 22050

def write(name, notes, duration=0.12):
    samples = []
    for frequency in notes:
        for i in range(int(RATE * duration)):
            t = i / RATE
            envelope = min(t / 0.008, 1) * max(0, 1 - t / duration) ** 1.6
            value = math.sin(2 * math.pi * frequency * t)
            value += 0.2 * math.sin(2 * math.pi * frequency * 2 * t)
            samples.append(int(10000 * value * envelope))
    with wave.open(str(DEST / (name + '.wav')), 'wb') as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(struct.pack('<' + 'h' * len(samples), *samples))

if __name__ == '__main__':
    DEST.mkdir(parents=True, exist_ok=True)
    write('tap', [660], 0.065)
    write('move', [420, 560], 0.06)
    write('roll', [240, 380, 260, 430, 290, 490, 330, 580], 0.058)
    write('capture', [660, 440, 880], 0.10)
    write('home', [523, 659, 784], 0.12)
    write('start', [392, 523, 659, 784], 0.12)
    write('win', [523, 659, 784, 1047, 784, 1047], 0.16)
    print('Generated 7 original mono PCM game cues.')
