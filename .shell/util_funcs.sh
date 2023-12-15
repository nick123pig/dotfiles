#!/usr/bin/env bash

function gitcleanbranch () {
    mainbranch=${1:-master}
    curbranch=$(git rev-parse --abbrev-ref HEAD)
    dirty=$([[ -z $(git status -s) ]]|| echo 'dirty')
    if [[ "$curbranch" == "$mainbranch" ]]
    then
        echo "Cannot run on $mainbranch"
        return 1
    fi
    if [[ -z "$dirty" ]]
    then
        git checkout $curbranch
        git reset $(git merge-base $mainbranch $curbranch)
        echo "Branch has been condensed and staged. You'll need to force push your branch"
        return 0
    else
        echo "Branch is dirty. Stash/commit before running again"
        return 1
    fi
}