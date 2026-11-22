package operator

import (
	"context"

	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// ModServer is the backend server module (OPERATOR_GUI_V2 design item 1): the
// logical-server list that feeds every server picker and scope field. Its
// commands are the agent's; MergeModules joins them by module id.
const ModServer = "server"

// OperatorServer is one registered logical server, read from its owner.
type OperatorServer struct {
	ServerID int64
	Name     string
	// Open is true while the server admits existing logins (Open or
	// ExistingOnly); Maintenance, Provisioned and Retired servers are closed.
	Open bool
}

// ServerRow is one server.list row.
type ServerRow struct {
	ServerID    int64  `json:"server_id"`
	Name        string `json:"name"`
	Open        bool   `json:"open"`
	OnlineCount int64  `json:"online_count"`
}

// ServerListPage is the server.list reply.
type ServerListPage struct {
	Servers []ServerRow `json:"servers"`
}

// ServerDirectory is I4's operator logical-server read port; it owns the SQL.
type ServerDirectory interface {
	OperatorServersTx(context.Context, tx.Queryer) ([]OperatorServer, error)
}

// ServerOnlineCounter is identitylifecycle's online-count port, so server.list
// never reads another owner's tables.
type ServerOnlineCounter interface {
	OnlineCountsByServerTx(context.Context, tx.Queryer) (map[int64]int64, error)
}

// ServerReadService answers server.list in one read-only transaction.
type ServerReadService struct {
	Runner     tx.Runner
	Operations operation.Factory
	Servers    ServerDirectory
	Online     ServerOnlineCounter
}

// List joins the logical servers with the live-session count per server.
func (s ServerReadService) List(ctx context.Context) (ServerListPage, error) {
	if s.Servers == nil || s.Online == nil || s.Runner.DB == nil {
		return ServerListPage{}, ErrUnavailable
	}
	current, err := s.Operations.New(policy.Set{})
	if err != nil {
		return ServerListPage{}, err
	}
	page := ServerListPage{Servers: []ServerRow{}}
	_, err = s.Runner.Run(ctx, current, readProfile("operator-server-list-v1"), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, scope tx.Scope) error {
		servers, readErr := s.Servers.OperatorServersTx(ctx, scope.Tx)
		if readErr != nil {
			return readErr
		}
		counts, countErr := s.Online.OnlineCountsByServerTx(ctx, scope.Tx)
		if countErr != nil {
			return countErr
		}
		page.Servers = make([]ServerRow, 0, len(servers))
		for _, server := range servers {
			page.Servers = append(page.Servers, ServerRow{ServerID: server.ServerID, Name: server.Name, Open: server.Open, OnlineCount: counts[server.ServerID]})
		}
		return nil
	})
	if err != nil {
		return ServerListPage{}, err
	}
	return page, nil
}
