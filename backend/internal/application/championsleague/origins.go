package championsleague

import (
	"context"
	"encoding/json"
	"fmt"
	app "gxb.local/backend/v2/internal/application/playerdisplay"
	d "gxb.local/backend/v2/internal/domain/championsleague"
	"gxb.local/backend/v2/internal/foundation/tx"
	"strconv"
)

func sameOrigin(a, b app.Origin) bool {
	x, _ := json.Marshal(a)
	y, _ := json.Marshal(b)
	return string(x) == string(y)
}

// ReadCatalogDisplayOriginsTx proves bounded positive grants from immutable
// genuine settlements and exact I5 mirrors. It does not invent legacy history
// completeness or activate ambiguous historical League titles.
func (s Service) ReadCatalogDisplayOriginsTx(c context.Context, q tx.Queryer, r app.CatalogOriginRequest) (app.CatalogOriginObservation, error) {
	out := app.CatalogOriginObservation{Request: r, Origins: []app.Origin{}}
	if q == nil || s.Store == nil || s.Content == nil || s.Entitlements == nil || !r.PlayerID.Valid() || r.ObservedAt.IsZero() || len(r.Revision) != 64 {
		return out, app.ErrUnavailable
	}
	cat, e := s.Content.LeagueCatalogTx(c, q, r.Revision)
	if e != nil {
		return out, e
	}
	known := r.Family == "title" && cat.HasLegacyTitle(r.CatalogID) || r.Family == "bubble" && r.CatalogID >= 10002 && r.CatalogID <= 10007
	for _, id := range cat.TitleIDs {
		known = known || r.Family == "title" && r.CatalogID == id
	}
	if !known {
		return out, app.ErrUnavailable
	}
	awards, e := s.Store.OriginsTx(c, q, r.PlayerID)
	if e != nil {
		return out, e
	}
	canonical := map[string]app.Origin{}
	for _, a := range awards {
		o := a.Origin
		if o.Validate() != nil || o.Owner != "ChampionsLeague" || o.PlayerID != r.PlayerID || o.StartsAt == nil || a.Season < 1 {
			return out, app.ErrConflict
		}
		if o.StartsAt.After(r.ObservedAt) {
			continue
		}
		historical, e := s.Content.LeagueCatalogTx(c, q, o.Revision)
		if e != nil {
			return out, e
		}
		snap, ok, e := s.Store.SettlementTx(c, q, "SEASON", a.Season)
		if e != nil {
			return out, e
		}
		if !ok || snap.Revision != o.Revision || !snap.CutoffAt.Equal(*o.StartsAt) || snap.SettledAt.After(r.ObservedAt) {
			return out, app.ErrConflict
		}
		var row *d.SettlementRow
		for i := range snap.Rows {
			if snap.Rows[i].Player == r.PlayerID {
				row = &snap.Rows[i]
				break
			}
		}
		if row == nil || row.Placement != a.Placement || !row.Placement.Participated {
			return out, app.ErrConflict
		}
		switch o.Family {
		case "bubble":
			reward, ok := historical.FinalReward(a.Placement.Group, a.Placement.Rank)
			if !ok || reward.BubbleID != o.CatalogID || o.Key != fmt.Sprintf("league:season:%d:bubble", a.Season) || o.EndTime != o.StartsAt.Unix()+historical.BubbleSeconds {
				return out, app.ErrConflict
			}
		case "title":
			if d.IsLegacyTitle(o.CatalogID) {
				leagueRoot, found, err := s.Store.RootTx(c, q, false)
				if err != nil {
					return out, err
				}
				if !found || !d.LegacyTitlePlacementEligible(a.Placement, *o.StartsAt, leagueRoot.LegacyTitlesSince) {
					return out, app.ErrConflict
				}
				if !historical.HasLegacyTitle(o.CatalogID) || a.Placement.Group != 3 || a.Placement.Rank < 1 || a.Placement.Rank > 10 || row.TopSeasons != a.Count || a.Count < 1 || o.Key != fmt.Sprintf("league:legacy-title:%d", o.CatalogID) || o.EndTime != 0 {
					return out, app.ErrConflict
				}
				notice, found, err := s.Entitlements.ReadSourceMailTx(c, q, r.PlayerID, "CHAMPIONS_LEAGUE_LEGACY_TITLE", strconv.FormatInt(o.CatalogID, 10))
				if err != nil {
					return out, err
				}
				titleName := ""
				for _, title := range historical.LegacyTitles {
					if title.Identifier == o.CatalogID {
						titleName = title.Name
					}
				}
				expectedBody := fmt.Sprintf("%s: %s", titleName, "The top 10 in the top group of the Champions League can receive")
				if !found || notice.Validate() != nil || notice.Recipient != r.PlayerID || notice.Title != historical.Mail["CROSS_ARENA_MAIL_TITLE"] || notice.Sender != historical.Mail["CROSS_ARENA_MAIL_SENDER"] || notice.Body != expectedBody || !notice.CreatedAt.Equal(*o.StartsAt) || notice.CompatibilityPolicyVersion != d.LegacyTitlePolicy || len(notice.Attachments) != 0 {
					return out, app.ErrConflict
				}
				break
			}
			if a.Placement.Group != 3 || a.Placement.Rank > 10 || a.Count < 1 || a.Count > int64(len(historical.TitleIDs)) || row.TopSeasons != a.Count || historical.TitleIDs[a.Count-1] != o.CatalogID || o.Key != fmt.Sprintf("league:title:%d", o.CatalogID) || o.EndTime != 0 {
				return out, app.ErrConflict
			}
		default:
			return out, app.ErrConflict
		}
		if _, dup := canonical[o.Key]; dup {
			return out, app.ErrConflict
		}
		canonical[o.Key] = o
	}
	mirror, e := s.Entitlements.ReadDisplayEntitlementsTx(c, q, r.PlayerID, r.Family)
	if e != nil {
		return out, e
	}
	matched := map[string]bool{}
	for _, o := range mirror {
		if o.Owner != "ChampionsLeague" || o.StartsAt != nil && o.StartsAt.After(r.ObservedAt) {
			continue
		}
		own, ok := canonical[o.Key]
		if !ok || !sameOrigin(own, o) || matched[o.Key] {
			return out, app.ErrConflict
		}
		matched[o.Key] = true
	}
	for _, a := range awards {
		o := a.Origin
		if o.Family != r.Family || o.StartsAt.After(r.ObservedAt) {
			continue
		}
		if !matched[o.Key] {
			return out, app.ErrConflict
		}
		if o.CatalogID == r.CatalogID {
			out.Origins = append(out.Origins, o)
		}
	}
	out.Qualified = true
	out.CompleteHistory = false
	return out, nil
}

var _ app.CatalogExternalOrigins = Service{}
