#!/bin/bash

export PS4='> '

set -u
set -x

recipedir=$(dirname $0 | xargs readlink -f)
meta_yaml="$recipedir/meta.yaml"

cd "$(mktemp -d ${TMPDIR:-/tmp}/dl-XXXXXXX)"
pwd

# the simple one

ver=$(curl --silent http://hackage.haskell.org/package/git-annex | sed -n -e '/hackage.haskell.org.package.git-annex-/s,.*git-annex-\([0-9.]*\).*,\1,p')
wget http://hackage.haskell.org/package/git-annex-$ver/git-annex-$ver.tar.gz
sha=$(sha256sum git-annex-$ver.tar.gz | awk '{print $1;}')

function sedi() {
    var="$1"
    flavor="$2"
    value="$3"
    sed -i \
        -e 's,^\({% set '$var' = "\).*\(" %} *# \['"$flavor"'\].*\),\1'${value}'\2,g' \
        "$meta_yaml"
}

sedi version "not nodep" "$ver"
sedi sha256 "not nodep" "$sha"

git -C $recipedir diff

