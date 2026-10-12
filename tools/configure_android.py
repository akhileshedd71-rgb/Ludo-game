#!/usr/bin/env python3
"""Set only the Android paths in the local Godot editor configuration."""
import os
import re
from pathlib import Path

config = Path(os.environ['XDG_CONFIG_HOME']) / 'godot/editor_settings-4.6.tres'
text = config.read_text()
for key, value in {
    'export/android/java_sdk_path': os.environ['JAVA_HOME'],
    'export/android/android_sdk_path': os.environ['ANDROID_HOME'],
}.items():
    if '"' in value or '\n' in value:
        raise ValueError('Unsupported SDK path')
    line = f'{key} = "{value}"'
    if re.search(r'^' + re.escape(key) + r' = .*$', text, re.M):
        text = re.sub(r'^' + re.escape(key) + r' = .*$', lambda _: line, text, flags=re.M)
    else:
        text += '\n' + line + '\n'
config.write_text(text)
print('Configured Godot Android SDK and Java paths.')
