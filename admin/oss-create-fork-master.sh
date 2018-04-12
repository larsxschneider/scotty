#!/usr/bin/env bash
#
# A master branch in the https://github.com/autodesk-forks (external)
# organization is supposed explain the Autodesk fork strategy.
#

TEMP_REPO_PATH=$(mktemp -d)
git init $TEMP_REPO_PATH
cd $TEMP_REPO_PATH
cat << EOF > README.md
This repository contains Open Source contributions by [Autodesk Inc.](http://www.autodesk.com/) that have not been merged upstream, yet.

[List of branches with contributions](../../branches/all?utf8=✓&query=adsk-contrib)

Please contact us via [email](mailto:opensource@autodesk.com) or [Twitter](https://twitter.com/autodeskoss) for any questions.
EOF

git add README.md
git commit -m "initial commit"
git remote add origin $1
git push -f origin master
