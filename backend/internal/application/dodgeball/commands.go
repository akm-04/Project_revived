package dodgeball

import (
	"context"
	"encoding/json"
	"fmt"
	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/application/combat"
	"gxb.local/backend/v2/internal/application/i5"
	combatdomain "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/dodgeball"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/mail"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"sort"
	"time"
)

func locator(actor identity.ActorContext) combatdomain.Locator {
	return combatdomain.Locator{DomainKind: "dodgeball", AuthorityScope: fmt.Sprintf("server:%d", actor.LogicalServerID), DomainLocator: fmt.Sprint(actor.PlayerID)}
}

func (mode Mode) Enter(ctx context.Context, actor identity.ActorContext, friend identity.PlayerID, operationContext operation.Context) (map[string]any, error) {
	if friend < 0 {
		return nil, dodgeball.ErrInvalid
	}
	return mode.run(ctx, actor, "enter", friend, friend, operationContext, func(ctx context.Context, current scope) (map[string]any, error) {
		state := current.states[actor.PlayerID]
		if state.Sequence >= dodgeball.MaximumSequence || state.Played >= dodgeball.MaximumSequence {
			return nil, dodgeball.ErrUnavailable
		}
		if friend != 0 && current.states[friend].Incoming >= current.catalog.IncomingLimit {
			return nil, dodgeball.ErrRefused
		}
		sequence := state.Sequence + 1
		random := combatdomain.NewStream(current.timed.Operation.Operation().Derive("dodgeball.board/v1", uint64(sequence)))
		board, err := current.catalog.BuildBoard(random)
		if err != nil {
			return nil, err
		}
		if _, err = mode.Costs.DebitMaterialCostTx(ctx, current.timed.Tx, actor.PlayerID, i5.MaterialCost{Stacks: []i5.StackMaterialCost{{ItemID: current.catalog.TicketItem, Amount: 1}}}, current.timed.Operation.Operation()); err != nil {
			return nil, err
		}
		if friend != 0 {
			current.states[friend].Incoming++
			state.Invited[int64(friend)] = true
		}
		state.Sequence, state.Played = sequence, state.Played+1
		state.Pending = &dodgeball.Occurrence{Identity: fmt.Sprintf("%d:%d", actor.PlayerID, sequence), Revision: current.revision, Friend: int64(friend), Deadline: current.timed.Operation.DecisionAt().Add(time.Hour).Unix(), Board: board}
		state.LastFingerprint, state.LastResult = "", nil
		return map[string]any{"monsters": board.Monsters, "buffs": board.Buffs, "select_monsters": board.Marked}, nil
	})
}

func (mode Mode) Start(ctx context.Context, actor identity.ActorContext, marked int64, operationContext operation.Context) (map[string]any, error) {
	if marked <= 0 {
		return nil, dodgeball.ErrInvalid
	}
	return mode.run(ctx, actor, "start", marked, 0, operationContext, func(ctx context.Context, current scope) (map[string]any, error) {
		pending := current.states[actor.PlayerID].Pending
		if pending == nil || current.timed.Operation.DecisionAt().Unix() >= pending.Deadline {
			return nil, dodgeball.ErrRefused
		}
		offered := false
		for _, identifier := range pending.Board.Marked {
			if identifier == marked {
				offered = true
			}
		}
		if !offered || pending.Marked != 0 && pending.Marked != marked {
			return nil, dodgeball.ErrRefused
		}
		if pending.Draws != nil {
			return startResponse(*pending.Draws), nil
		}
		coherent, err := characterasset.NewCoherentReadScope(tx.Scope{Tx: current.timed.Tx, Operation: current.timed.Operation.Operation(), Attempt: current.timed.Attempt, Options: current.timed.Options}, pending.Revision, current.timed.Operation.DecisionAt())
		if err != nil {
			return nil, err
		}
		fingerprint, err := receipt.FingerprintRequest(struct {
			Game   string
			Marked int64
		}{pending.Identity, marked})
		if err != nil {
			return nil, err
		}
		started, err := mode.Combat.StartTx(ctx, current.timed.Tx, coherent, combat.StartRequest{Actor: actor, Locator: locator(actor), GenerationRef: pending.Identity, StartFingerprint: fmt.Sprintf("%x", fingerprint), ResultDeadline: time.Unix(pending.Deadline, 0), TrustProfile: combatdomain.ServerEntropyClientDerived, Replay: combatdomain.ReplaySpec{Response: combatdomain.ReplayFightExist, ErrorCode: combatdomain.FightExistCode}, Challenge: &combatdomain.Challenge{Targets: pending.Board.Monsters}, Package: current.catalog.DrawPolicy().Build})
		if err != nil {
			return nil, err
		}
		if started.Package == nil {
			return nil, dodgeball.ErrUnavailable
		}
		var draws combatdomain.DrawPackage
		if err = json.Unmarshal(started.Package.Canonical, &draws); err != nil {
			return nil, err
		}
		if !current.catalog.DrawPolicy().Issued(draws) {
			return nil, dodgeball.ErrUnavailable
		}
		pending.Marked, pending.Draws = marked, &draws
		return startResponse(draws), nil
	})
}

func startResponse(draws combatdomain.DrawPackage) map[string]any {
	return map[string]any{"self_rd": draws.Streams["self"], "friend_rd": draws.Streams["friend"]}
}

func (mode Mode) Result(ctx context.Context, actor identity.ActorContext, records []dodgeball.HitRecord, operationContext operation.Context) (map[string]any, error) {
	if records == nil || len(records) > 25 {
		return nil, dodgeball.ErrInvalid
	}
	return mode.run(ctx, actor, "result", records, 0, operationContext, func(ctx context.Context, current scope) (map[string]any, error) {
		state := current.states[actor.PlayerID]
		fingerprint, err := receipt.FingerprintRequest(records)
		if err != nil {
			return nil, err
		}
		fingerprintText := fmt.Sprintf("%x", fingerprint)
		pending := state.Pending
		if pending == nil {
			if state.LastResult != nil && state.LastFingerprint == fingerprintText {
				return map[string]any{"error_code": int64(combatdomain.FightExistCode)}, nil
			}
			return nil, dodgeball.ErrRefused
		}
		if pending.Draws == nil || current.timed.Operation.DecisionAt().Unix() >= pending.Deadline {
			return nil, dodgeball.ErrRefused
		}
		evaluated, err := current.catalog.Evaluate(pending.Board, pending.Marked, records, *pending.Draws, pending.Friend != 0)
		if err != nil {
			return nil, err
		}
		judged, err := mode.Combat.AttestDerivedTx(ctx, current.timed.Tx, combat.DerivedRequest{Locator: locator(actor), GenerationRef: pending.Identity, TerminalKind: "DODGEBALL_RESULT", At: current.timed.Operation.DecisionAt(), Policy: current.catalog.DrawPolicy(), Derivation: evaluated.Derivation})
		if err != nil {
			return nil, err
		}
		if judged.Drained || judged.Attestation.Verdict == combatdomain.VerdictRejected {
			state.Pending = nil
			return map[string]any{"error_code": int64(combatdomain.FightExistCode)}, nil
		}
		participants := []identity.PlayerID{actor.PlayerID}
		if len(evaluated.FriendAwards) > 0 {
			participants = append(participants, identity.PlayerID(pending.Friend))
		}
		sort.Slice(participants, func(left, right int) bool { return participants[left] < participants[right] })
		for _, player := range participants {
			if err = mode.Mail.LockMailNamespaceCounterTx(ctx, current.timed.Tx, player, mail.Normal); err != nil {
				return nil, err
			}
		}
		frozenOperation := current.timed.Operation.Operation()
		references := frozenOperation.Policies.Refs()
		for index := range references {
			if references[index].Name == "content" {
				references[index].Version = pending.Revision
			}
		}
		frozenOperation.Policies, err = policy.NewSet(references...)
		if err != nil {
			return nil, err
		}
		if len(evaluated.FriendAwards) > 0 {
			presentations, err := mode.Presentation.ReadManyAtTx(ctx, current.timed.Tx, []identity.PlayerID{actor.PlayerID}, current.timed.Operation.DecisionAt())
			if err != nil {
				return nil, err
			}
			presentation, present := presentations.Players[actor.PlayerID]
			if !present {
				return nil, dodgeball.ErrUnavailable
			}
			_, _, err = mode.Delivery.DeliverTx(ctx, current.timed.Tx, i5.SettlementMailRequest{Recipient: identity.PlayerID(pending.Friend), SourceKind: "DODGEBALL_FRIEND", SourceKey: pending.Identity, Title: "A winning report from Dodgeball", Sender: "The school committee is observing secretly", Body: fmt.Sprintf("Your friend %s invited you to play Dodgeball and you did great winning rewards for him. Let's help each other out more from now on!", presentation.Minimal.Name), PolicyVersion: dodgeball.PolicyID, Lines: evaluated.FriendAwards, At: current.timed.Operation.DecisionAt()})
			if err != nil {
				return nil, err
			}
		}
		if len(evaluated.ActorAwards) > 0 {
			plan := grant.Plan{PlayerID: actor.PlayerID, Source: grant.SourceIdentity{Domain: "dodgeball", Operation: "reward", BusinessKey: pending.Identity, Occurrence: pending.Identity, PolicyVersion: dodgeball.PolicyID}, Lines: evaluated.ActorAwards}
			if _, err = mode.Values.SettleGrantTx(ctx, current.timed.Tx, actor, plan, frozenOperation, i5.GrantTxOptions{AllowOverflowMail: true}); err != nil {
				return nil, err
			}
		}
		response := map[string]any{"error_code": int64(0)}
		state.Pending, state.LastFingerprint, state.LastResult = nil, fingerprintText, response
		return response, nil
	})
}
