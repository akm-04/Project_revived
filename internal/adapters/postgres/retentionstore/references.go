package retentionstore

import (
	"fmt"
	"strings"
)

// BatchSize is one rule statement's row bound (named constant, not a policy).
const BatchSize int64 = 1000

// ownReceiptColumn is the receipts table's own key; a receipt cannot keep itself.
const ownReceiptColumn = "gxb_operation_receipts.receipt_id"

// RuleReferenceColumns is the kept-while table read by
// tools/retention_references.py --check. Every generated reference list entry
// must appear here, and every non-key entry keeps its row while it holds the id.
var RuleReferenceColumns = map[string][]string{
	"combat-chain": attemptReferences,
	"receipts":     append(append([]string{}, receiptIdReferences...), operationIdReferences...),
}

// The combat chain's kept-while list. An attempt is kept while any generated
// attempt-id column still holds it or another attempt supersedes it.
var attemptReferences = []string{
	"adventure_single_attempts.attempt_id",
	"arena_matches.attempt_id",
	"combat_attempts.supersedes_attempt_id",
	"conquer_school_reports.attempt_id",
	"illusion_attempts.attempt_id",
	"league_matches.attempt_id",
	"one_on_one_rounds.attempt_id",
	"top_floor_fights.attempt_id",
	"top_floor_records.attempt_id",
	"top_floor_task_fights.attempt_id",
	"top_floor_task_records.attempt_id",
	"worldboss_attempts.attempt_id",
}

var receiptIdReferences = []string{
	"combat_attempts.semantic_receipt_id",
	"combat_member_settlements.semantic_receipt_id",
	"guild_broadcast_recipients.target_receipt_id",
	"guild_broadcast_sources.source_receipt_id",
	"guild_invite_projection_deliveries.target_receipt_id",
	"guild_invite_projection_markers.core_receipt_id",
	"guild_invite_projection_markers.cursor_receipt_id",
	"guild_invite_projection_sources.core_receipt_id",
	"gxb_operation_receipts.receipt_id",
	"redeem_redemptions.grant_receipt_id",
	"social_gift_claim_operations.grant_receipt_id",
	"social_gift_transfers.grant_receipt_id",
	"social_guild_invite_invalidations.receipt_id",
	"social_guild_invite_materializations.receipt_id",
}

var operationIdReferences = []string{
	"achievement_award_claims.operation_id",
	"friend_dm_projection_receipts.operation_id",
	"guild_audit_log.operation_id",
	"guild_invite_send_events.operation_id",
	"guild_membership_events.operation_id",
	"personal_dm_delivery.operation_id",
	"personal_dm_intents.operation_id",
	"personal_dm_payloads.operation_id",
	"player_book_admissions.operation_id",
	"player_course_admissions.operation_id",
	"player_display_admissions.operation_id",
	"player_dorm_admissions.operation_id",
	"player_element_admissions.operation_id",
	"player_gm_questions.operation_id",
	"player_hero_evolution_admissions.operation_id",
	"player_hero_practice_candidates.generation_operation_id",
	"player_inscription_admissions.operation_id",
	"player_library_admissions.operation_id",
	"player_login_observations.source_operation_id",
	"player_pet_practice_candidates.generation_operation_id",
	"player_profile_comment_operations.operation_id",
	"player_public_profile_media_current.operation_id",
	"player_public_profile_media_history.operation_id",
	"player_spirit_admissions.operation_id",
	"ranking_girls_snapshots.operation_id",
	"social_gift_claim_operations.operation_id",
	"social_gift_transfers.claim_operation_id",
	"social_gift_transfers.send_operation_id",
	"social_invite_bindings.operation_id",
	"social_invite_mission_claims.operation_id",
	"social_recall_awards.operation_id",
	"social_recall_tasks.operation_id",
}

func receiptKeptWhileSQL() string {
	clauses := make([]string, 0, len(receiptIdReferences)+len(operationIdReferences))
	for _, reference := range operationIdReferences {
		clauses = append(clauses, heldClause(reference, "r.operation_id"))
	}
	for _, reference := range receiptIdReferences {
		if reference == ownReceiptColumn {
			continue
		}
		clauses = append(clauses, heldClause(reference, "r.receipt_id"))
	}
	return strings.Join(clauses, "\n\tAND ")
}

func combatKeptWhileSQL() string {
	clauses := make([]string, 0, len(attemptReferences))
	for _, reference := range attemptReferences {
		clauses = append(clauses, heldClause(reference, "a.attempt_id"))
	}
	return strings.Join(clauses, "\n\tAND ")
}

func heldClause(reference, targetColumn string) string {
	table, column, ok := strings.Cut(reference, ".")
	if !ok || table == "" || column == "" {
		panic("retentionstore: reference " + reference + " is not table.column")
	}
	return fmt.Sprintf("NOT EXISTS (SELECT 1 FROM %s held WHERE held.%s::text = %s::text)", table, column, targetColumn)
}
