-- +goose Up
ALTER TABLE player_dorm_admissions DROP CONSTRAINT player_dorm_admissions_family_check;
ALTER TABLE player_dorm_admissions ADD CONSTRAINT player_dorm_admissions_family_check
 CHECK(family IN ('DORM_OPEN','DORM_SAVE','DORM_EQUIP','DORM_ENTER','DORM_EXCHANGE','DORM_START','DORM_FINISH','DORM_BUY_GLUE'));
