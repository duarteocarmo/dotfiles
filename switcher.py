#!/Users/duarteocarmo/.asdf/shims/python
import contextlib
import os
import time
import subprocess

CURRENT_APPEARANCE_COMMAND = "dark-notify -e"
DARK_THEME = "hyper"
LIGHT_THEME = "paper-theme"
COMMAND = "/Users/duarteocarmo/.asdf/shims/alacritty-themes"

with contextlib.redirect_stdout(None):
    while True:
        current_appearance = subprocess.run(
            ["defaults", "read", "-g", "AppleInterfaceStyle"], stdout=subprocess.PIPE
        ).stdout.decode("utf-8")

        if "Dark" in current_appearance:
            subprocess.run(
                [COMMAND, DARK_THEME],
            )
        else:
            subprocess.run([COMMAND, LIGHT_THEME])

        os.system("rm /Users/duarteocarmo/.alacritty.yml*.bak")

        time.sleep(0.25)


# import sys
# import subprocess

# mode = sys.argv[1]
# DARK_THEME = "hyper"
# LIGHT_THEME = "paper-theme"
# COMMAND = "/Users/duarteocarmo/.asdf/shims/alacritty-themes"

# if mode == "dark":
#     subprocess.run([COMMAND, DARK_THEME])

# elif mode == "light":
#     subprocess.run([COMMAND, LIGHT_THEME])

# sys.exit(0)
