package guildcampaign

import (
	"context"
	"errors"
	"time"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/application/playerroot"
	dcombat "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/grant"
	d "gxb.local/backend/v2/internal/domain/guildcampaign"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/mail"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var (
	ErrUnavailable = errors.New("guild campaign unavailable")
	ErrLate        = errors.New("guild campaign result past its window")
	ErrHolder      = errors.New("guild campaign copy held by another member")
)

const (
	combatKind          = "GUILD_CAMPAIGN_RESULT"
	goldResource        = "mana"
	guildCoinResource   = "guild_coin"
	dungeonCoinResource = "team_dungeon_coin"
	crystalResource     = "crystal"
	duplicateResultCode = 30005
	factKind            = "GUILD_ACTIVITY"
	payoutSource        = "GUILD_CAMPAIGN_PAYOUT"
	awardSource         = "GUILD_CAMPAIGN_AWARD"
)

// Settings is the immutable policy and misc table set of the chapter run.
type Settings struct {
	AttemptsPerChapterDay int64
	PrepareSeconds        int64
	BattleSeconds         int64
	RestSecondsOfDay      [2]int64
	ApplicationsPerDay    int64
	BossRankFactor        int64
	RetentionDays         int64
	RewardHurtRank        []int64
	DistRewardTime        []int64
	RewardParamPerMille   int64
	RewardTimeLimitSecond int64
	RecordRewardCrystal   int64
	RecordRewardBadge     int64
	LastStrikeCoin        int64
	MaxFightDamage        int64
}

func (s Settings) InRestWindow(secondsOfDay int64) bool {
	return secondsOfDay >= s.RestSecondsOfDay[0] && secondsOfDay < s.RestSecondsOfDay[1]
}

// DamageRow is one member's best hit of a run.
type DamageRow struct {
	PlayerID int64
	Damage   int64
	HitAt    time.Time
}

// ProfileView is the guild wire profile of a member.
type ProfileView struct {
	PlayerID      identity.PlayerID
	Name          string
	Level         int64
	AvatarID      int64
	AvatarFrameID int64
	ConquerLevel  int64
	ConquerLoopID int64
}

// CopyRow is one copy as the wire reads it.
type CopyRow struct {
	CopyID       int64
	CurrentIndex int64
	Win          bool
	Percent      float64
	Waves        []byte
	HolderID     int64
	Stage        int64
	LastFight    *time.Time
	StartFight   *time.Time
}

// EnemyRow is one wave entry as stored.
type EnemyRow struct {
	TableID int64 `json:"table_id"`
	Lev     int64 `json:"lev"`
	Star    int64 `json:"star"`
	Color   int64 `json:"color"`
	Health  int64 `json:"health"`
	HP      int64 `json:"hp,omitempty"`
	Reborn  int64 `json:"is_reborn,omitempty"`
}

// GuildLogRow is one 609 log entry.
type GuildLogRow struct {
	Type      int64
	PlayerID  int64
	ChapterID int64
	At        time.Time
}

// Detail is the 613 view.
type Detail struct {
	Copy       CopyRow
	IsOpen     bool
	IsWin      bool
	FightInfo  ProfileView
	HolderLive bool
}

// ClaimView is the 614 answer.
type ClaimView struct {
	Stage      int64
	HolderID   int64
	LastFight  *time.Time
	StartFight *time.Time
	FightInfo  ProfileView
}

// Started is the 604 answer.
type Started struct {
	CopyID       int64
	CurrentIndex int64
	Waves        map[int64][]EnemyRow
}

// Settled is the 610 answer; Duplicate replays the stored body with 30005.
type Settled struct {
	Body      map[string]any
	Duplicate bool
}

// ModeStore is the guildcampaignstore surface this leaf adds.
type ModeStore interface {
	IsRegisteredTx(context.Context, tx.Queryer, int64, int64, identity.PlayerID) (bool, error)
	LockCopyTx(context.Context, tx.Tx, int64, int64, int64) (d.Copy, bool, error)
	ReadCopyTx(context.Context, tx.Queryer, int64, int64, int64) (d.Copy, bool, error)
	SaveCopyTx(context.Context, tx.Tx, d.Copy) error
	ListCopiesTx(context.Context, tx.Queryer, int64, int64) ([]CopyRow, error)
	MemberClearsTx(context.Context, tx.Queryer, identity.PlayerID, int64, int64) (int64, error)
	LockMemberDayTx(context.Context, tx.Tx, identity.PlayerID, int64, int64) (int64, error)
	BumpMemberClearsTx(context.Context, tx.Tx, identity.PlayerID, int64, int64) error
	SaveChapterProgressTx(context.Context, tx.Tx, int64, int64, int64, float64, bool, *time.Time) error
	UpsertDamageTx(context.Context, tx.Tx, int64, int64, int64, int64, int64, time.Time) error
	ListDamageTx(context.Context, tx.Queryer, int64, int64, int64, int) ([]DamageRow, error)
	UpsertServerRecordTx(context.Context, tx.Tx, identity.LogicalServerID, int64, int64, int64, int64, []byte, time.Time) error
	TopServerDamageTx(context.Context, tx.Queryer, identity.LogicalServerID, int64) (int64, error)
	ListServerRecordsTx(context.Context, tx.Queryer, identity.LogicalServerID, int64, int) ([]ServerRecord, error)
	ServerKillTx(context.Context, tx.Tx, identity.LogicalServerID, int64, int64, int64, time.Time, int64) (ServerKill, bool, error)
	ServerKillReadTx(context.Context, tx.Queryer, identity.LogicalServerID, int64) (ServerKill, bool, error)
	ListGuildLogTx(context.Context, tx.Queryer, int64, time.Time, int) ([]GuildLogRow, error)
	InsertAwardsTx(context.Context, tx.Tx, int64, int64, int64, []AwardSeed) error
	ListAwardsTx(context.Context, tx.Queryer, int64, int64, int64) ([]AwardRow, error)
	ListDueAwardsTx(context.Context, tx.Queryer, time.Time, int) ([]AwardRow, error)
	SaveAwardTx(context.Context, tx.Tx, AwardRow) error
	ApplicationTx(context.Context, tx.Queryer, int64, int64, int64, identity.PlayerID) (ApplicationRow, bool, error)
	ApplicationsByAwardTx(context.Context, tx.Queryer, int64, int64, int64) ([]ApplicationRow, error)
	ApplyTx(context.Context, tx.Tx, int64, int64, int64, identity.PlayerID, int64, time.Time) error
	ApplicationCountTx(context.Context, tx.Queryer, identity.PlayerID, int64) (int64, error)
	BumpApplicationCountTx(context.Context, tx.Tx, identity.PlayerID, int64) error
	InsertDistributionTx(context.Context, tx.Tx, int64, identity.PlayerID, int64, time.Time) error
	ListDistributionsTx(context.Context, tx.Queryer, int64, int) ([]DistributionRow, error)
	ListRegisteredTx(context.Context, tx.Queryer, int64, int64) ([]identity.PlayerID, error)
	ReadChapterTx(context.Context, tx.Queryer, int64, int64) (d.Chapter, bool, error)
	LockAwardTx(context.Context, tx.Tx, AwardRow) (AwardRow, bool, error)
}

// ServerRecord is one 608 highest-hit row.
type ServerRecord struct {
	PlayerID int64
	GuildID  int64
	Damage   int64
	Partners []byte
	HitAt    time.Time
}

// ServerKill is the 608 first and fastest kill state of a copy.
type ServerKill struct {
	FirstPlayerID int64
	FirstGuildID  int64
	FirstAt       time.Time
	FastestGuild  int64
	FastestSecond int64
}

// AwardSeed seeds one award pool row.
type AwardSeed struct {
	AwardID   int64
	Remaining int64
	ExpiresAt time.Time
	NextSlot  time.Time
}

// AwardRow is one 605/606 row and the reconciler's due row.
type AwardRow struct {
	GuildID   int64
	ChapterID int64
	Run       int64
	AwardID   int64
	Remaining int64
	ExpiresAt time.Time
	NextSlot  time.Time
}

// ApplicationRow is one member application.
type ApplicationRow struct {
	PlayerID  int64
	AwardID   int64
	AppliedAt time.Time
}

// DistributionRow is one 615 log row.
type DistributionRow struct {
	PlayerID    int64
	ItemID      int64
	Distributed time.Time
}

// ModeCombat is the combat surface this leaf uses.
type ModeCombat interface {
	StartTx(context.Context, tx.Tx, ca.CoherentReadScope, combat.StartRequest) (combat.Started, error)
	AttestSummaryTx(context.Context, tx.Tx, combat.SummaryRequest) (combat.SummaryAttested, error)
	BorrowedTx(context.Context, tx.Tx, dcombat.Locator) (bool, error)
}

// Facts is the F11 port.
type Facts interface {
	PrepareTx(context.Context, tx.Tx, identity.PlayerID, gen.TimedOperation) (context.Context, error)
	RecordTx(context.Context, tx.Tx, operation.Context, ...objective.Fact) error
}

// Grants is i5's grant plan port.
type Grants interface {
	SettleGrantTx(context.Context, tx.Tx, identity.ActorContext, grant.Plan, operation.Context, i5.GrantTxOptions) (i5.GrantResult, error)
}

// Directory resolves display profiles.
type Directory interface {
	Profile(context.Context, identity.PlayerID) (playerdirectory.Profile, bool, error)
	ProfileTx(context.Context, tx.Queryer, identity.PlayerID) (playerdirectory.Profile, bool, error)
}

// Mailer is i5's settlement mail.
type Mailer interface {
	DeliverTx(context.Context, tx.Tx, i5.SettlementMailRequest) (mail.Record, bool, error)
}

// NoticeMailer is C13's notice seam.
type NoticeMailer interface {
	DeliverNoticeTx(context.Context, tx.Tx, i5.SettlementMailRequest) (mail.Record, bool, error)
}

// Notifier publishes push 36853 after commit. A nil notifier is a no-op.
type Notifier interface {
	Notify(context.Context, int64, int64, int64, identity.PlayerID) error
}

// pushInputs are the outbox reference fields of the 36853 wakeup.
type pushInputs struct {
	GuildID   int64
	ChapterID int64
	CopyID    int64
	PlayerID  identity.PlayerID
}

// ChapterInfo is a chapter's numbers and its copy ids.
type ChapterInfo struct {
	ChapterID      int64
	Previous       int64
	OpenCost       int64
	CoinReward     int64
	AdditionReward int64
	Items          []int64
	Copies         []int64
}

// CopyInfo is one copy's fight and seeded waves.
type CopyInfo struct {
	CopyID    int64
	FightID   int64
	BossFight bool
	Waves     map[int64][]EnemyRow
}

// Content is the immutable catalog surface the 604/613/601 paths read.
type Content interface {
	ChapterInfo(int64) (ChapterInfo, bool)
	CopyInfo(int64, int64) (CopyInfo, bool)
	ChapterOfCopy(int64) (int64, bool)
}

// Mode is the Guild Campaign gameplay owner. Service keeps the lead-owned open,
// reset and departure paths; Mode adds claim, fight, settle, awards and reads.
type Mode struct {
	Service
	ModeStore  ModeStore
	Content    Content
	Tables     map[int64]ChapterInfo
	Settings   Settings
	Combat     ModeCombat
	Grants     Grants
	Facts      Facts
	Directory  Directory
	Mail       Mailer
	NoticeMail NoticeMailer
	Notifier   Notifier
	Fence      Fence
	Players    playerroot.TxLocker
	Timed      gen.TimedRunner
	Fresh      tx.Queryer
}

func (m Mode) ready() bool {
	return m.ModeStore != nil && m.Content != nil && m.Combat != nil && m.Grants != nil && m.Facts != nil && m.Directory != nil && m.Mail != nil && m.Fence != nil && m.Players != nil
}

// TxProfile resolves one member's display row inside a transaction.
func (m Mode) profileTx(c context.Context, q tx.Queryer, player identity.PlayerID) (ProfileView, error) {
	profile, found, err := m.Directory.ProfileTx(c, q, player)
	if err != nil {
		return ProfileView{}, err
	}
	if !found {
		return ProfileView{}, ErrUnavailable
	}
	return ProfileView{PlayerID: profile.PlayerID, Name: profile.Name, Level: profile.Level, AvatarID: profile.AvatarID,
		AvatarFrameID: profile.AvatarFrameID, ConquerLevel: profile.ConquerLevel, ConquerLoopID: profile.ConquerLoopID}, nil
}
