package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"gxb.local/backend/v2/internal/application/operatoragent"
)

const maxAgentReplyBytes = 8 << 20

// agentClient is the CLI's connection to the local agent.
type agentClient struct {
	baseURL string
	token   string
	http    *http.Client
}

func newAgentClient(root string, withSession bool) (*agentClient, error) {
	config, err := operatoragent.LoadConfig(root)
	if err != nil {
		return nil, err
	}
	client := &agentClient{baseURL: "http://" + config.Listen, http: &http.Client{Timeout: 10 * time.Minute}}
	if !withSession {
		return client, nil
	}
	contents, err := os.ReadFile(filepath.Join(root, operatoragent.SessionFileName))
	if err != nil {
		return nil, fmt.Errorf("not logged in: run gxb-operator login")
	}
	client.token = strings.TrimSpace(string(contents))
	if client.token == "" {
		return nil, fmt.Errorf("not logged in: run gxb-operator login")
	}
	return client, nil
}

func (client *agentClient) request(method, path string, body any) (int, []byte, error) {
	var reader io.Reader
	if body != nil {
		encoded, err := json.Marshal(body)
		if err != nil {
			return 0, nil, err
		}
		reader = bytes.NewReader(encoded)
	}
	request, err := http.NewRequest(method, client.baseURL+path, reader)
	if err != nil {
		return 0, nil, err
	}
	if client.token != "" {
		request.Header.Set("Authorization", "Bearer "+client.token)
	}
	if method == http.MethodPost {
		request.Header.Set("Content-Type", "application/json")
	}
	response, err := client.http.Do(request)
	if err != nil {
		return 0, nil, fmt.Errorf("the agent did not answer: %w", err)
	}
	defer response.Body.Close()
	reply, err := io.ReadAll(io.LimitReader(response.Body, maxAgentReplyBytes))
	if err != nil {
		return 0, nil, err
	}
	return response.StatusCode, reply, nil
}

func printResult(status int, body []byte) error {
	if len(body) > 0 {
		fmt.Println(strings.TrimRight(string(body), "\n"))
	}
	if status < 200 || status >= 300 {
		return fmt.Errorf("the agent answered HTTP %d", status)
	}
	return nil
}
