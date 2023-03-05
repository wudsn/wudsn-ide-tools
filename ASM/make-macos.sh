#!/bin/bash

#------------------------------------------------------------------------
# Create MADS.
#------------------------------------------------------------------------
function fetchGitRepo($URL){

	rm -rf .git
	echo Getting latest MADS sources from github.
	git init -b master  --quiet
	git remote add origin $URL
	git fetch origin master --force  --quiet
	rm -rf .git

}


