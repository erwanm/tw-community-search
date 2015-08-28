#!/bin/bash

# requires a properly configured git repo both local and remote (e.g. github)
# the skeleton wiki must already exist in the repo

# must be run from the project dir

echo "step 1: set git repo right"
git checkout automatic
if [ $? -ne 0 ]; then
    echo "Error, impossible to checkout 'automatic' branch" 1>&2
    exit 1
fi
git pull

echo "step 2: backup previous node.js content"
rm -rf tw-community-search.bak
mv tw-community-search tw-community-search.bak

echo "step 3: run the aggregator"
workDir=$(mktemp -d)
tw-community-search.sh -d "$workDir"
# DEBUG VERSION below:
#tw-community-search.sh -t -d "$workDir"


echo "step 4: extract the output wiki (node.js and html)"
mv "$workDir"/output-wiki tw-community-search
rm -rf "$workDir"

echo "step 5: send the single html output somewhere else"
tmpFile=$(mktemp)
mv tw-community-search.html "$tmpFile"

echo "step 6: committing and pushing changes for node.js version"
git add -A tw-community-search/tiddlers/
git commit -m "automatic update" 
git push

echo "step 7: switching to gh-pages"
git checkout gh-pages
rm -f index.html
mv "$tmpFile" index.html

echo "step 8: committing and pushing changes for single html"
git add index.html
git commit -m "automatic update"
git push

git checkout automatic
