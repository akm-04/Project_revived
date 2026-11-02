-- +goose Up
-- owner: identity/logicalserver/bootstrap
-- D435: the stock region list (data table region) offers four servers. Seed
-- 3 and 4 with the same shape as 1 and 2; 00077's robot-range rule implies
-- next_player_id = server*100000 + 25001.
INSERT INTO logical_servers(logical_server_id,name,first_opened_at,directory_visible,existing_login_allowed,new_character_allowed,next_player_id,max_player_id,state_version,created_at)
VALUES
 (3,'Server 3',CURRENT_TIMESTAMP,true,true,true,325001,399999,1,CURRENT_TIMESTAMP),
 (4,'Server 4',CURRENT_TIMESTAMP,true,true,true,425001,499999,1,CURRENT_TIMESTAMP)
ON CONFLICT (logical_server_id) DO NOTHING;
