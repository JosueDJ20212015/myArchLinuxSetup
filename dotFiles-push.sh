#!/bin/bash
cd /home/josuepc/.dotfiles || exit
git add .
echo "Ingresa el mensaje del commit:"
read commit_message
git commit -m "$commit_message"
git push https://JosueDJ20212015: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@github.com/JosueDJ20212015/$(basename $(git config --get remote.origin.url) .git).git
