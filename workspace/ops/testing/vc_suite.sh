#!/bin/bash
# Every scenario in backend/virtualclient/scenarios, one fresh device each, on database $VCDB. Expect "client=0" on every line.
cd /home/akm/Chatgpt/EOL_Game
SC=work/backend_i7c4_full/backend/virtualclient/scenarios
for n in injected $(ls $SC | sed 's/.json//' | grep -vx injected); do
  r=$(UPDATE_TREE=$PWD/tmp/virtualclient/update-tree SCENARIO=$SC/$n.json LIMIT=400s bash ops/testing/vc_run.sh ${n}t 2>&1 | tail -1)
  echo "$n $r $(tail -1 tmp/virtualclient/runs/${n}t/client.log | grep 'scenario failed' | cut -c1-200)"
done
