#!/bin/bash

export PS4='> '

set -u
set -x

recipedir=$(dirname $0 | xargs readlink -f)
meta_yaml="$recipedir/meta.yaml"

cd "$(mktemp -d ${TMPDIR:-/tmp}/annex-update-XXXXXXX)"
pwd


function sedi() {
    var="$1"
    flavor="$2"
    value="$3"
    sed -i \
        -e 's,^\({% set '$var' = "\).*\(" %} *# \['"$flavor"'\].*\),\1'${value}'\2,g' \
        "$meta_yaml"
}

# ensure we are at build 0
sed -i \
    -e 's,^{% set build = [0-9] .*,{% set build = 0 %},g'\
    "$meta_yaml"

# the simple one

ver=$(curl --silent http://hackage.haskell.org/package/git-annex | sed -n -e '/hackage.haskell.org.package.git-annex-/s,.*git-annex-\([0-9.]*\).*,\1,p')
wget http://hackage.haskell.org/package/git-annex-$ver/git-annex-$ver.tar.gz
sha=$(sha256sum git-annex-$ver.tar.gz | awk '{print $1;}')

sedi version "not nodep" "$ver"
sedi sha256 "not nodep" "$sha"

# now the nodep one for which there is a dance to do
standalone=git-annex-standalone-amd64.tar.gz
[ ! -e "$standalone" ] || rm -f "$standalone"
wget https://downloads.kitenet.net/git-annex/linux/current/$standalone
nodep_sha=$(sha256sum "$standalone" | awk '{print $1;}')
nodep_size=$(du -b "$standalone" | awk '{print $1;}')
tar -xzf "$standalone"
nodep_version_printed=$(git-annex.linux/git-annex version | awk '/git-annex version:/{print $3;}')

sedi version "nodep" "$ver"
sedi size "nodep" "$nodep_size"
sedi sha256 "nodep" "$nodep_sha"
sedi version_printed "nodep" "$nodep_version_printed"

git -C "$recipedir" diff

