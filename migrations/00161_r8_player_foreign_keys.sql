-- +goose Up
-- owner: R8 player data (A-040)
-- R8-3 part A: every player column that no foreign key covers now references players.
-- NOT VALID takes a short lock and checks only new rows; 00162 validates existing rows outside a transaction.
-- Excluded: client logs, request_journal and the logical_servers counters (journals and allocators), and
-- redeem_redemptions.subject_id (text). NO ACTION: players are never deleted. No index: the key is checked on insert only.

ALTER TABLE guild_broadcast_recipients ADD CONSTRAINT guild_broadcast_recipients_recipient_player_id_fkey FOREIGN KEY (recipient_player_id) REFERENCES players(player_id) NOT VALID;
ALTER TABLE guild_broadcast_sources ADD CONSTRAINT guild_broadcast_sources_leader_player_id_fkey FOREIGN KEY (leader_player_id) REFERENCES players(player_id) NOT VALID;
ALTER TABLE guild_campaign_copies ADD CONSTRAINT guild_campaign_copies_holder_id_fkey FOREIGN KEY (holder_id) REFERENCES players(player_id) NOT VALID;
ALTER TABLE guild_campaign_copies ADD CONSTRAINT guild_campaign_copies_settled_by_fkey FOREIGN KEY (settled_by) REFERENCES players(player_id) NOT VALID;
ALTER TABLE guild_campaign_distributions ADD CONSTRAINT guild_campaign_distributions_player_id_fkey FOREIGN KEY (player_id) REFERENCES players(player_id) NOT VALID;
ALTER TABLE guild_campaign_log ADD CONSTRAINT guild_campaign_log_player_id_fkey FOREIGN KEY (player_id) REFERENCES players(player_id) NOT VALID;
ALTER TABLE guild_campaign_server_kills ADD CONSTRAINT guild_campaign_server_kills_first_player_id_fkey FOREIGN KEY (first_player_id) REFERENCES players(player_id) NOT VALID;
ALTER TABLE guild_invite_projection_cursors ADD CONSTRAINT guild_invite_projection_cursors_recipient_player_id_fkey FOREIGN KEY (recipient_player_id) REFERENCES players(player_id) NOT VALID;
ALTER TABLE guild_invite_projection_deliveries ADD CONSTRAINT guild_invite_projection_deliveries_recipient_player_id_fkey FOREIGN KEY (recipient_player_id) REFERENCES players(player_id) NOT VALID;
ALTER TABLE guild_invite_projection_markers ADD CONSTRAINT guild_invite_projection_markers_subject_player_id_fkey FOREIGN KEY (subject_player_id) REFERENCES players(player_id) NOT VALID;
ALTER TABLE guild_invite_projection_sources ADD CONSTRAINT guild_invite_projection_sources_inviter_player_id_fkey FOREIGN KEY (inviter_player_id) REFERENCES players(player_id) NOT VALID;
ALTER TABLE guild_invite_projection_sources ADD CONSTRAINT guild_invite_projection_sources_recipient_player_id_fkey FOREIGN KEY (recipient_player_id) REFERENCES players(player_id) NOT VALID;
ALTER TABLE guild_rental_uses ADD CONSTRAINT guild_rental_uses_lender_id_fkey FOREIGN KEY (lender_id) REFERENCES players(player_id) NOT VALID;
ALTER TABLE player_dorm_admissions ADD CONSTRAINT player_dorm_admissions_player_id_fkey FOREIGN KEY (player_id) REFERENCES players(player_id) NOT VALID;
ALTER TABLE player_dorm_comment_reactions ADD CONSTRAINT player_dorm_comment_reactions_actor_player_id_fkey FOREIGN KEY (actor_player_id) REFERENCES players(player_id) NOT VALID;
ALTER TABLE player_dorm_comments ADD CONSTRAINT player_dorm_comments_author_player_id_fkey FOREIGN KEY (author_player_id) REFERENCES players(player_id) NOT VALID;
ALTER TABLE player_dorm_praises ADD CONSTRAINT player_dorm_praises_actor_player_id_fkey FOREIGN KEY (actor_player_id) REFERENCES players(player_id) NOT VALID;
ALTER TABLE player_dorm_roots ADD CONSTRAINT player_dorm_roots_player_id_fkey FOREIGN KEY (player_id) REFERENCES players(player_id) NOT VALID;
ALTER TABLE player_library_admissions ADD CONSTRAINT player_library_admissions_player_id_fkey FOREIGN KEY (player_id) REFERENCES players(player_id) NOT VALID;
ALTER TABLE player_library_roots ADD CONSTRAINT player_library_roots_player_id_fkey FOREIGN KEY (player_id) REFERENCES players(player_id) NOT VALID;
ALTER TABLE player_profile_comment_operations ADD CONSTRAINT player_profile_comment_operations_actor_player_id_fkey FOREIGN KEY (actor_player_id) REFERENCES players(player_id) NOT VALID;
ALTER TABLE player_profile_comment_operations ADD CONSTRAINT player_profile_comment_operations_target_player_id_fkey FOREIGN KEY (target_player_id) REFERENCES players(player_id) NOT VALID;
ALTER TABLE player_profile_comment_reactions ADD CONSTRAINT player_profile_comment_reactions_actor_player_id_fkey FOREIGN KEY (actor_player_id) REFERENCES players(player_id) NOT VALID;
ALTER TABLE player_profile_comments ADD CONSTRAINT player_profile_comments_author_player_id_fkey FOREIGN KEY (author_player_id) REFERENCES players(player_id) NOT VALID;
ALTER TABLE player_profile_feedback_roots ADD CONSTRAINT player_profile_feedback_roots_player_id_fkey FOREIGN KEY (player_id) REFERENCES players(player_id) NOT VALID;
ALTER TABLE player_profile_praises ADD CONSTRAINT player_profile_praises_actor_player_id_fkey FOREIGN KEY (actor_player_id) REFERENCES players(player_id) NOT VALID;
ALTER TABLE social_gift_epochs ADD CONSTRAINT social_gift_epochs_player_id_fkey FOREIGN KEY (player_id) REFERENCES players(player_id) NOT VALID;
ALTER TABLE social_gift_transfers ADD CONSTRAINT social_gift_transfers_sender_player_id_fkey FOREIGN KEY (sender_player_id) REFERENCES players(player_id) NOT VALID;
ALTER TABLE social_guild_invite_invalidations ADD CONSTRAINT social_guild_invite_invalidations_recipient_player_id_fkey FOREIGN KEY (recipient_player_id) REFERENCES players(player_id) NOT VALID;
ALTER TABLE social_guild_invite_materializations ADD CONSTRAINT social_guild_invite_materializations_recipient_player_id_fkey FOREIGN KEY (recipient_player_id) REFERENCES players(player_id) NOT VALID;
ALTER TABLE social_invite_bindings ADD CONSTRAINT social_invite_bindings_invitee_player_id_fkey FOREIGN KEY (invitee_player_id) REFERENCES players(player_id) NOT VALID;
ALTER TABLE social_invite_bindings ADD CONSTRAINT social_invite_bindings_inviter_player_id_fkey FOREIGN KEY (inviter_player_id) REFERENCES players(player_id) NOT VALID;
ALTER TABLE social_invite_mission_claims ADD CONSTRAINT social_invite_mission_claims_player_id_fkey FOREIGN KEY (player_id) REFERENCES players(player_id) NOT VALID;
ALTER TABLE social_recall_tasks ADD CONSTRAINT social_recall_tasks_caller_player_id_fkey FOREIGN KEY (caller_player_id) REFERENCES players(player_id) NOT VALID;
ALTER TABLE social_recall_tasks ADD CONSTRAINT social_recall_tasks_target_player_id_fkey FOREIGN KEY (target_player_id) REFERENCES players(player_id) NOT VALID;
ALTER TABLE top_floor_offer_snapshots ADD CONSTRAINT top_floor_offer_snapshots_player_id_fkey FOREIGN KEY (player_id) REFERENCES players(player_id) NOT VALID;
