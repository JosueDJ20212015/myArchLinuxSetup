#!/bin/bash
cd /home/josuepc/.dotfiles || exit
git add .
echo "Ingresa el mensaje del commit:"
read commit_message
git commit -m "$commit_message"
git push
