"""Turn characters.json into fcitx5's conf/keyboard-longpress.conf.

Usage: generate.py characters.json [LANG...] > keyboard-longpress.conf
Languages are merged in the order given (default: all, in the file's order), repeated
characters dropped.
"""

import json
import sys

# The same physical key with Shift on the US and Colemak layouts. fcitx5 looks entries up by
# the typed character, so these need their own entries; PowerToys keys on the physical key.
SHIFTED = dict(zip("1234567890-=,./\\", '!@#$%^&*()_+<>?|'))


def upper(char):
    # Python's upper() turns ß into "SS"
    return "ẞ" if char == "ß" else char.upper()


def quoted(text):
    return '"' + text.replace("\\", "\\\\").replace('"', '\\"') + '"'


def main():
    with open(sys.argv[1], encoding="utf-8") as data:
        languages = json.load(data)

    entries = {}
    for language in sys.argv[2:] or languages:
        for key, chars in languages[language].items():
            entries.setdefault(key, []).extend(chars)

    for key, chars in list(entries.items()):
        if key.isalpha():
            entries[key.upper()] = [upper(char) for char in chars]
        elif key in SHIFTED:
            entries.setdefault(SHIFTED[key], []).extend(chars)

    for index, (key, chars) in enumerate(entries.items()):
        print(f"[Entries/{index}]")
        print(f"Key={quoted(key)}")
        print("Enable=True")
        print()
        print(f"[Entries/{index}/Candidates]")
        # dict.fromkeys: drop repeats and keep the order
        for position, char in enumerate(dict.fromkeys(chars)):
            print(f"{position}={quoted(char)}")
        print()


main()
