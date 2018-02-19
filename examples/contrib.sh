#!/bin/bash
#
git log --all --no-merges --date=short --reverse --pretty | egrep "(^Author|^Date)" | \
    sed 's/^Author://;s/Date://' | sed 'N;s/\n/ /' | \
    ruby $HOME/bin/contributors.rb
