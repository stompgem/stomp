#!/bin/bash
#
# git log --reverse --all --date=short --pretty --format='%aI;%cI;%cn;%ce' | \
git log --reverse --all --date=short --pretty --format='%ad;%cd;%cn;%ce' | \
    ruby examples/contributors.rb
 
