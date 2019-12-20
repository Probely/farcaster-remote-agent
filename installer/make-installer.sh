#!/bin/bash -e

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

genid() {
    python -c "import base64, os; print(base64.b32encode(os.urandom(8)).decode().rstrip('=').lower())"
}

make_tmp_dir() {
    local id=$(genid)
    local tmp="${script_dir}/tmp/installer-${id}"
    mkdir -p -m 0700 ${tmp}
    echo ${tmp}
}

keybundle="$1"
if [ "$keybundle" == "" ] || [ ! -f "$keybundle" ]; then
    echo "usage: $0 KEY_BUNDLE_FILE"
    echo "KEY_BUNDLE_FILE is an archive containing agent keys"
    exit 1
fi

keyid=$(basename ${keybundle} | sed s/.tar.gz$//)
tmp_dir=$(make_tmp_dir)
docker_image="${AGENT_DOCKER_IMAGE:-probely/farcaster-remote-agent}"

mkdir -m 0700 -p "${tmp_dir}/keys"
mkdir -m 0700 -p "${tmp_dir}/config"
tar -xpzvf "${keybundle}" --strip 1 -C "${tmp_dir}/keys/"
cp ${script_dir}/setup.sh "${tmp_dir}"
cp "${script_dir}/../compose/docker-compose.yml" "${tmp_dir}/config"

# Configure docker-compose.yml
agenthub="$(<${tmp_dir}/keys/tunnel/env/AGENT_HUB_HOST)"
sed -i s/__AGENT_HUB_HOST__/${agenthub}/g ${tmp_dir}/config/docker-compose.yml
sed -i s#__DOCKER_IMAGE__#${docker_image}#g "${tmp_dir}/config/docker-compose.yml" 

cd ${script_dir} && ./makeself/makeself.sh --gzip --ssl-encrypt --nomd5 --nocrc \
    --sha256 --license ${script_dir}/../LICENSE \
    ${tmp_dir} \
    ${script_dir}/target/probely-agent-${keyid}.run \
    "Probely Farcaster Remote Agent" \
    ./setup.sh

rm -rf "${tmp_dir}"
