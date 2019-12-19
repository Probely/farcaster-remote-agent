#!/bin/bash -e

genid() {
    python -c "import base64, os; print(base64.b32encode(os.urandom(8)).decode().rstrip('=').lower())"
}

make_tmp_dir() {
    local id=$(genid)
    local tmp="./tmp/installer-${id}"
    mkdir -p -m 0700 ${tmp}
    echo ${tmp}
}

keybundle="$1"
if [ "$keybundle" == "" ] || [ ! -f "$keybundle" ]; then
    echo "usage: $0 KEY_BUNDLE_FILE"
    echo "KEY_BUNDLE_FILE is an archive containing agent keys"
    exit 1
fi

version=0.0.1
tmp_dir=$(make_tmp_dir)
mkdir -m 0700 -p "${tmp_dir}/keys"
mkdir -m 0700 -p "${tmp_dir}/config"
tar -xpzvf "${keybundle}" --strip 1 -C "${tmp_dir}/keys/"
cp setup.sh "${tmp_dir}"
cp ../compose/docker-compose.yml "${tmp_dir}/config"

./makeself/makeself.sh --gzip --ssl-encrypt --nomd5 --nocrc --sha256 --license ../LICENSE \
    ${tmp_dir} \
    target/probely-agent-${version}.run \
    "Probely Farcaster Remote Agent" \
    ./setup.sh

rm -rf "${tmp_dir}"
