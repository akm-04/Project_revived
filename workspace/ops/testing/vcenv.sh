# Source this: goenv.sh plus the virtual client module's own caches (cd virtualclient).
. /home/akm/Chatgpt/EOL_Game/ops/testing/goenv.sh
export GOMODCACHE=$W/tmp/cache/virtualclient/go-mod GOCACHE=$W/tmp/cache/virtualclient/go-build
export GOPROXY=file://$W/tmp/cache/virtualclient/go-mod/cache/download,file://$T/cache/go-mod/cache/download
cd virtualclient
