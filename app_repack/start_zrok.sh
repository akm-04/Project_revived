#!/bin/bash

echo "Cleaning up any old zrok processes..."
killall zrok2 2>/dev/null
sleep 1

echo "Starting SDK tunnel (Port 5000)..."
nohup zrok2 share public localhost:5000 -n public:gxbsdk --headless > zrok_sdk.log 2>&1 &

echo "Starting Engine tunnel (Port 9000)..."
nohup zrok2 share public localhost:9000 -n public:gxbengine --headless > zrok_engine.log 2>&1 &

echo ""
echo "================================================="
echo "✅ Tunnels are running in the background!"
echo "================================================="
echo "SDK URL:    https://gxbsdk.shares.zrok.io"
echo "Engine URL: https://gxbengine.shares.zrok.io"
echo "================================================="
echo ""
echo "To watch live traffic logs, run:"
echo "  tail -f zrok_sdk.log"
echo "  tail -f zrok_engine.log"
echo ""
echo "To stop the tunnels, run: killall zrok2"