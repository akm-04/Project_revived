# Source this: the pinned r4 Go toolchain for the backend module (cd backend). Never edits system Go or caches outside tmp/.
W=/home/akm/Chatgpt/EOL_Game
T=$W/tmp/tools_r4_accept/gxb-e2e-self-contained
export GOROOT=$T/opt/go-1.27.3 GOMODCACHE=$W/tmp/cache/tools_r4/go-mod GOCACHE=$W/tmp/cache/tools_r4/go-build GOTOOLCHAIN=local GOPROXY=file://$T/cache/go-mod/cache/download GOSUMDB=off CC=$T/bin/zig-cc GOFLAGS=-mod=mod
export PATH=$T/bin:$GOROOT/bin:$PATH
cd $W/work/backend_i7c4_full/backend
