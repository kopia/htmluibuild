#!/bin/bash
set -e
kopia_tmp=/tmp/kopia-src

if [ ! -d "$kopia_tmp" ]; then
    git clone https://github.com/kopia/kopia.git $kopia_tmp
fi

(cd $kopia_tmp && git fetch && git checkout -f master && git pull)

# determine SHA to upgrade to
htmluibuild_new_hash=${GITHUB_SHA:-$(git rev-parse HEAD)}
htmluibuild_old_hash=$(cd $kopia_tmp && grep /htmluibuild go.mod | cut -f 3 -d -)

# determine old SHA
echo GITHUB_SHA: $GITHUB_SHA
echo htmluibuild_new_hash: $htmluibuild_new_hash
echo htmluibuild_old_hash: $htmluibuild_old_hash

htmlui_old_hash=$(git show $htmluibuild_old_hash | grep "HTMLUI update for" | cut -f 7 -d /)
echo htmlui_old_hash: $htmlui_old_hash
htmlui_new_hash=$(git show $htmluibuild_new_hash | grep "HTMLUI update for" | cut -f 7 -d /)
echo htmlui_new_hash: $htmlui_new_hash

generate_log() {
    htmlui_old_hash=$1
    htmlui_new_hash=$2
    htmlui_tmp=/tmp/kopia-htmlui-src
    if [ ! -d "$htmlui_tmp" ]; then
        git clone https://github.com/kopia/htmlui.git $htmlui_tmp
    fi

    pushd $htmlui_tmp
    git fetch
    git log --pretty=format:"* https://github.com/kopia/htmlui/commit/%h %an %s" --no-patch $htmlui_old_hash..$htmlui_new_hash | sed -r 's@ [(]#.*$@@g'
    popd
}

generate_log $htmlui_old_hash $htmlui_new_hash