#!/bin/sh

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Neomutt
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 📬
# @raycast.packageName Mail
# @raycast.description Bring neomutt to the front, or start it

# kitty runs neomutt alone (see ~/.config/kitty/kitty.conf): opening it
# starts neomutt, or brings the running one to the front.
open -a kitty
