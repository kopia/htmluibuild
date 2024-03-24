#!/bin/bash
set -e
kopia_tmp=/tmp/kopia-src

if [ ! -d "$kopia_tmp" ]; then
    git clone https://$GH_TOKEN@github.com/kopia/kopia.git $kopia_tmp
fi

(cd $kopia_tmp && git fetch && git checkout -f master && git pull)

# determine SHA to upgrade to
htmluibuild_new_hash=${GITHUB_SHA:-$(git rev-parse HEAD)}
htmluibuild_old_hash=$(cd $kopia_tmp && grep /htmluibuild go.mod | cut -f 3 -d -)

echo htmluibuild_new_hash: $htmluibuild_new_hash
echo htmluibuild_old_hash: $htmluibuild_old_hash

htmlui_old_hash=$(git show $htmluibuild_old_hash | grep "HTMLUI update for" | cut -f 7 -d /)
echo htmlui_old_hash: $htmlui_old_hash
htmlui_new_hash=$(git show $htmluibuild_new_hash | grep "HTMLUI update for" | cut -f 7 -d /)
echo htmlui_new_hash: $htmlui_new_hash

if [ "$htmlui_new_hash" == "" ]; then
    echo Not a HTMLUI update commit, ignoring.
    exit 0
fi

generate_log() {
    htmlui_old_hash=$1
    htmlui_new_hash=$2
    htmlui_tmp=/tmp/kopia-htmlui-src

    if [ ! -d "$htmlui_tmp" ]; then
        git clone https://github.com/kopia/htmlui.git $htmlui_tmp
    fi

    echo "## Changes"

    (cd $htmlui_tmp && git fetch && git log --pretty=format:"* https://github.com/kopia/htmlui/commit/%h %an %s" --no-patch $htmlui_old_hash..$htmlui_new_hash | sed -r 's@ [(]#.*$@@g')
}

generate_log $htmlui_old_hash $htmlui_new_hashg > /tmp/pr-body.txt
pr_title="feat(ui): upgraded htmlui to the latest version"

cd $kopia_tmp

git checkout -B htmlui-update
go get github.com/kopia/htmluibuild@$htmluibuild_new_hash
go mod tidy
git add -A 
git -c "user.name=Kopia Builder" -c "user.email=builder@kopia.io" 
git commit -m "$pr_title"
git push -u -f

existing_pr=$(gh pr list -L 1 -l htmlui-update | cut -f 1)
if [ "$existing_pr" == "" ]; then
  echo PR does not exist, creating...
  gh pr create --title="$pr_title" --body-file=/tmp/pr-body.txt -l htmlui-update
else
  echo PR $existing_pr exists updating...
  gh pr edit $existing_pr --title="$pr_title" --body-file=/tmp/pr-body.txt
fi
