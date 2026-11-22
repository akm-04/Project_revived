package events

import "gxb.local/backend/v2/internal/application/operator"

// Module is the events module (I11A_ARCHITECTURE_V1 section 2): the definition,
// schedule and occurrence commands plus the bounded occurrence list read.
func (commands Commands) Module() operator.Module {
	return operator.Module{
		ID:         "events",
		Title:      "Events",
		Role:       operator.RoleRoot,
		LogChannel: "events",
		Screen:     operator.Screen{Tab: "Events", Columns: []string{"id", "activity_id", "logical_server_id", "state", "starts_at"}},
		Commands: []operator.CommandSpec{
			{Name: "events.definition.deploy", Class: operator.ClassLive, Help: "Validate, gift-expand and store one immutable definition revision.", Fields: definitionFields(), Handler: commands.deployHandler},
			{Name: "events.definition.list", Class: operator.ClassLive, Help: "List the stored definition revisions, newest first.", Fields: []operator.Field{
				operator.NewField("activity_id", operator.FieldInt, false, "client activity id; omitted lists every activity"),
				operator.NewField("limit", operator.FieldInt, false, "page size").Bounded(1, MaxListLimit),
			}, Handler: commands.definitionListHandler},
			{Name: "events.schedule", Class: operator.ClassLive, Help: "Create one occurrence per logical server after the OTA coverage gate.", Fields: []operator.Field{
				operator.NewField("activity_id", operator.FieldInt, true, "client activity id"),
				operator.NewField("logical_server_ids", operator.FieldArray, true, "one to one hundred logical server ids"),
				operator.NewField("start", operator.FieldString, false, "RFC3339 start; omitted starts at the next 05:00 GMT+8 boundary"),
				operator.NewField("duration", operator.FieldDuration, true, "for example 3d, 36h or permanent"),
			}, Handler: commands.scheduleHandler},
			{Name: "events.cancel", Class: operator.ClassLive, Help: "Cancel a SCHEDULED occurrence.", Fields: []operator.Field{occurrenceField()}, Handler: commands.cancelHandler},
			{Name: "events.end_now", Class: operator.ClassLive, Help: "End a RUNNING or CLAIM_WINDOW occurrence now.", Fields: []operator.Field{occurrenceField()}, Handler: commands.endNowHandler},
			{Name: "events.extend", Class: operator.ClassLive, Help: "Move the end of a SCHEDULED or RUNNING occurrence.", Fields: []operator.Field{occurrenceField(), operator.NewField("duration", operator.FieldDuration, true, "timed extension, for example 1d")}, Handler: commands.extendHandler},
			{Name: "events.set_permanent", Class: operator.ClassLive, Help: "Make a SCHEDULED or RUNNING occurrence permanent.", Fields: []operator.Field{occurrenceField()}, Handler: commands.setPermanentHandler},
			{Name: "events.occurrence.show", Class: operator.ClassLive, Help: "Show one occurrence and its claim ledger page.", Fields: []operator.Field{
				occurrenceField(),
				operator.NewField("limit", operator.FieldInt, false, "claim page size").Bounded(1, MaxClaimsLimit),
			}, Handler: commands.occurrenceShowHandler},
		},
		Reads: []operator.Read{
			{Name: "events.list", Help: "One page of occurrences, newest start first.", Fields: []operator.Field{
				operator.NewField("server", operator.FieldInt, true, "logical server id"),
				operator.NewField("state", operator.FieldString, false, "lifecycle state filter").WithEnum("SCHEDULED", "RUNNING", "CLAIM_WINDOW", "ENDED", "ARCHIVED", "CANCELLED"),
				operator.NewField("from", operator.FieldString, false, "RFC3339 lower bound"),
				operator.NewField("to", operator.FieldString, false, "RFC3339 upper bound"),
				operator.NewField("limit", operator.FieldInt, false, "page size").Bounded(1, MaxListLimit),
				operator.NewField("cursor", operator.FieldString, false, "next_cursor of the previous page"),
			}},
		},
	}
}

func occurrenceField() operator.Field {
	return operator.NewField("occurrence_id", operator.FieldInt, true, "occurrence id from events.list")
}

func definitionFields() []operator.Field {
	return []operator.Field{
		operator.NewField("activity_id", operator.FieldInt, true, "client activity id"),
		operator.NewField("revision", operator.FieldInt, true, "immutable revision number"),
		operator.NewField("archetype", operator.FieldString, true, "behaviour family").WithEnum("RULE_MODIFIER", "TIERED_CLAIM", "EXCHANGE", "DISPLAY"),
		operator.NewField("hooks", operator.FieldArray, false, "typed hooks; a RULE_MODIFIER needs at least one"),
		operator.NewField("tiers", operator.FieldArray, false, "tiers with one to three choices; a TIERED_CLAIM needs at least one"),
		operator.NewField("client_requirements", operator.FieldObject, false, "client content the OTA gate must cover"),
		operator.NewField("default_days", operator.FieldInt, false, "factory duration when the operator omits one"),
		operator.NewField("default_start", operator.FieldString, false, "factory start time"),
	}
}
