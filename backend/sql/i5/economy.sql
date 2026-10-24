-- owner: typed-economy
-- source: Pass415 Wave-E TypedEconomy

-- name: LockScalarBalance :one
SELECT player_id,resource_key,amount,state_version,updated_at
FROM player_currency_balances WHERE player_id=$1 AND resource_key=$2 FOR UPDATE;

-- name: InsertScalarBalance :exec
INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at)
VALUES($1,$2,$3,1,$4);

-- name: UpdateScalarBalance :execrows
UPDATE player_currency_balances SET amount=$3,state_version=state_version+1,updated_at=$4
WHERE player_id=$1 AND resource_key=$2 AND state_version=$5;

-- name: LockTemporalResource :one
SELECT player_id,resource_key,stored_amount,regen_anchor_at,policy_version,state_version,updated_at
FROM player_temporal_resources WHERE player_id=$1 AND resource_key=$2 FOR UPDATE;

-- name: UpdateTemporalResource :execrows
UPDATE player_temporal_resources
SET stored_amount=$3,regen_anchor_at=$4,policy_version=$5,state_version=state_version+1,updated_at=$6
WHERE player_id=$1 AND resource_key=$2 AND state_version=$7;

-- name: LockItemStack :one
SELECT player_id,item_id,quantity,state_version,acquired_at,updated_at
FROM player_item_stacks WHERE player_id=$1 AND item_id=$2 FOR UPDATE;

-- name: InsertItemStack :exec
INSERT INTO player_item_stacks(player_id,item_id,quantity,state_version,acquired_at,updated_at)
VALUES($1,$2,$3,1,$4,$4);

-- name: UpdateItemStack :execrows
UPDATE player_item_stacks SET quantity=$3,state_version=state_version+1,updated_at=$4
WHERE player_id=$1 AND item_id=$2 AND state_version=$5;
