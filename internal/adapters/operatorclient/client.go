// Package operatorclient talks to the gxb-api operator listener from the
// agent. It adds the per-start bearer token and returns the backend's status
// and body verbatim, so refusals pass through the agent unchanged
// (I11A_OPERATOR_COMMANDS_V1 ruling 4).
package operatorclient

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	"gxb.local/backend/v2/internal/application/operator"
	"gxb.local/backend/v2/internal/application/operatoragent"
)

const maxReplyBytes = 4 << 20

// Client is the outbound operator-API client.
type Client struct {
	baseURL string
	tokens  *operatoragent.TokenHolder
	http    *http.Client
}

// New takes the backend's operator address and the token holder the agent
// refreshes on every backend start.
func New(address string, tokens *operatoragent.TokenHolder) *Client {
	if !strings.Contains(address, "://") {
		address = "http://" + address
	}
	return &Client{baseURL: strings.TrimSuffix(address, "/"), tokens: tokens, http: &http.Client{Timeout: 5 * time.Minute}}
}

type commandBody struct {
	Envelope operator.Envelope `json:"envelope"`
	Payload  json.RawMessage   `json:"payload"`
}

// Command posts one typed command.
func (client *Client) Command(ctx context.Context, request operatoragent.OperatorRequest) (operatoragent.BackendResponse, error) {
	body, err := json.Marshal(commandBody{Envelope: request.Envelope, Payload: request.Payload})
	if err != nil {
		return operatoragent.BackendResponse{}, err
	}
	url := client.baseURL + "/operator/v1/commands/" + request.Name
	return client.do(ctx, http.MethodPost, url, body)
}

// Modules fetches the backend module registry for the agent's merged list.
func (client *Client) Modules(ctx context.Context) ([]operator.Module, error) {
	response, err := client.do(ctx, http.MethodGet, client.baseURL+"/operator/v1/modules", nil)
	if err != nil {
		return nil, err
	}
	if response.Status != http.StatusOK {
		return nil, fmt.Errorf("the backend module list answered HTTP %d", response.Status)
	}
	var reply struct {
		Modules []operator.Module `json:"modules"`
	}
	if err := json.Unmarshal(response.Body, &reply); err != nil {
		return nil, err
	}
	return reply.Modules, nil
}

// Read runs one operator read.
func (client *Client) Read(ctx context.Context, name, query string) (operatoragent.BackendResponse, error) {
	url := client.baseURL + "/operator/v1/reads/" + name
	if query != "" {
		url += "?" + query
	}
	return client.do(ctx, http.MethodGet, url, nil)
}

func (client *Client) do(ctx context.Context, method, url string, body []byte) (operatoragent.BackendResponse, error) {
	token := client.tokens.Get()
	if token == "" {
		return operatoragent.BackendResponse{}, operatoragent.Refuse(operatoragent.CodeBackendUnavailable, "the backend is not running")
	}
	var reader io.Reader
	if body != nil {
		reader = bytes.NewReader(body)
	}
	request, err := http.NewRequestWithContext(ctx, method, url, reader)
	if err != nil {
		return operatoragent.BackendResponse{}, err
	}
	request.Header.Set("Authorization", "Bearer "+token)
	if body != nil {
		request.Header.Set("Content-Type", "application/json")
	}
	response, err := client.http.Do(request)
	if err != nil {
		return operatoragent.BackendResponse{}, operatoragent.Refuse(operatoragent.CodeBackendUnavailable, "the backend operator API did not answer")
	}
	defer response.Body.Close()
	reply, err := io.ReadAll(io.LimitReader(response.Body, maxReplyBytes))
	if err != nil {
		return operatoragent.BackendResponse{}, fmt.Errorf("read the backend reply: %w", err)
	}
	return operatoragent.BackendResponse{Status: response.StatusCode, Body: reply}, nil
}
