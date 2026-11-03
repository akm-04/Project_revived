-- +goose Up
-- owner: library-local-progression
-- I9_LIBRARY_V1 C6/C21: 837 marks one dialog read through the admission/receipt lane.
ALTER TABLE player_library_admissions DROP CONSTRAINT player_library_admissions_family_check;
ALTER TABLE player_library_admissions ADD CONSTRAINT player_library_admissions_family_check CHECK (family IN (
 'LIBRARY_GIFT','LIBRARY_FEED','LIBRARY_SAVE','LIBRARY_NORMAL_CLAIM','LIBRARY_SPECIAL_CLAIM',
 'LIBRARY_BUY_GIFT','LIBRARY_BOARD','LIBRARY_TALK_AWARD','LIBRARY_ACT_AWARD','LIBRARY_SCHOOL_STORY',
 'LIBRARY_CG','LIBRARY_BG','LIBRARY_MISSION_AWARD','LIBRARY_READ_DIALOG'
));
