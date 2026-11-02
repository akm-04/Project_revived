package arena

import (
	"context"
	"strconv"

	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	d "gxb.local/backend/v2/internal/domain/arena"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/foundation/operation"
)

// FulfillTournamentChampion is an operator application seam; I11 owns authenticated transport.
func (service Service) FulfillTournamentChampion(requestContext context.Context, operator i5.AdminOperator, season, tableIdentifier int64, operationContext operation.Context) (d.TournamentPeriod, error) {
	if err := operator.Validate(); err != nil {
		return d.TournamentPeriod{}, err
	}
	if tableIdentifier <= 0 {
		return d.TournamentPeriod{}, d.ErrInvalid
	}
	return service.tournamentPeriodWork(requestContext, season, operationContext, "champion-choice:"+strconv.FormatInt(tableIdentifier, 10)+":"+operator.ID+":"+operator.ReasonCode, func(requestContext context.Context, scope gen.TimedScope, _ d.TournamentCatalog, period *d.TournamentPeriod) error {
		if !period.Settled || period.Cancelled || !period.ChampionPrizeOwed {
			return d.ErrRefused
		}
		if period.ChampionPrizeChosen != 0 {
			if period.ChampionPrizeChosen == tableIdentifier {
				return nil
			}
			return d.ErrRefused
		}
		revision, err := service.Content.ActiveRevision(requestContext, scope.Tx)
		if err != nil {
			return err
		}
		templates, err := service.Content.ArenaTemplatesTx(requestContext, scope.Tx, revision)
		if err != nil {
			return err
		}
		template, known := templates[tableIdentifier]
		if !known || !template.Super || template.Awakened {
			return d.ErrRefused
		}
		for _, entrant := range period.Entrants {
			if entrant.Placement != 1 {
				continue
			}
			if _, _, err := service.Mail.DeliverTx(requestContext, scope.Tx, i5.SettlementMailRequest{Recipient: entrant.PlayerID, SourceKind: "ARENA_PLAYOFFS_CHAMPION_CHOICE", SourceKey: strconv.FormatInt(season, 10), Title: "Arena Playoffs Champion", Sender: "Arena", Body: "Your selected SX prize", PolicyVersion: d.TournamentPolicyIdentifier, Lines: []grant.Line{{Kind: grant.PartnerEntity, ItemID: tableIdentifier, Amount: 1}}, At: scope.Operation.DecisionAt()}); err != nil {
				return err
			}
			period.ChampionPrizeChosen, period.ChampionPrizeOperator, period.ChampionPrizeReason = tableIdentifier, operator.ID, operator.ReasonCode
			period.StateVersion++
			return nil
		}
		return d.ErrConflict
	})
}
