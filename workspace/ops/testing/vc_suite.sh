#!/bin/bash
# Every scenario directly in backend/virtualclient/scenarios (clock/ holds operator clock-move scenarios, run by hand), one fresh device each, on database $VCDB. Expect "client=0" on every line.
cd /home/akm/Chatgpt/EOL_Game
SC=${GXB_BACKEND:-work/backend_i7c4_full/backend}/virtualclient/scenarios
for n in injected $(cd $SC && ls *.json | sed "s/.json//" | grep -vx injected); do
  r=$(UPDATE_TREE=$PWD/tmp/virtualclient/update-tree SCENARIO=$SC/$n.json LIMIT=400s bash ops/testing/vc_run.sh ${n}t 2>&1 | tail -1)
  echo "$n $r $(tail -1 tmp/virtualclient/runs/${n}t/client.log | grep 'scenario failed' | cut -c1-200)"
done
