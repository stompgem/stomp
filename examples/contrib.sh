#!/bin/bash
#
#git log --reverse --all --date=iso-strict --pretty --format='%ad;%cn;%ce'
git log --reverse --all --date=short --pretty --format='%cd;%cn;%ce' | \
    ruby examples/contributors.rb
 