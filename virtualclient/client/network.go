package client

import (
	"bytes"
	"compress/zlib"
	"encoding/json"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"

	lua "github.com/yuin/gopher-lua"
)

// stockOrigins are the engine origins hard-coded in stock src_64 that the app_repack patch rewrites to the private server.
var stockOrigins = []string{"http://xuemeien.carolgames.com:9000", "http://119.81.215.217:9000"}

// Exchange is one HTTP request the stock client made and how it ended.
type Exchange struct {
	At       float64 `json:"at_virtual_seconds"`
	Method   string  `json:"method"`
	URL      string  `json:"url"`
	MID      float64 `json:"mid,omitempty"`
	Encoding string  `json:"encoding"`
	Status   int     `json:"status"`
	// ErrorCode is the stock error_code of a JSON response body (0 when absent), what stock Backend.lua checks.
	ErrorCode float64 `json:"error_code,omitempty"`
	Bytes     int     `json:"response_bytes"`
	Failure   string  `json:"failure,omitempty"`
	// NullFields are the JSON paths a response answers null: stock cjson decodes null to the truthy cjson.null, so a consumer
	// guarding with `if x` or `x or {}` then indexes or adds to userdata.
	NullFields []string `json:"null_fields,omitempty"`
}

type formPart struct {
	name     string
	value    string
	filePath string
}

type httpRequest struct {
	callback *lua.LFunction
	url      string
	method   int
	values   []string
	parts    []formPart
	timeout  time.Duration
	started  bool
	status   int
	body     []byte
	userdata *lua.LUserData
}

type network struct {
	origin  string
	report  *Report
	queue   []*httpRequest
	methods map[string]lua.LGFunction
	clock   func() float64
}

func newNetwork(origin string, report *Report, clock func() float64) *network {
	network := &network{origin: strings.TrimSuffix(origin, "/"), report: report, clock: clock}
	network.methods = map[string]lua.LGFunction{
		"addPOSTValue": func(state *lua.LState) int {
			request := checkRequest(state)
			request.values = append(request.values, state.CheckString(2)+"="+state.ToStringMeta(state.Get(3)).String())
			return 0
		},
		"addFormContents": func(state *lua.LState) int {
			request := checkRequest(state)
			request.parts = append(request.parts, formPart{name: state.CheckString(2), value: state.ToStringMeta(state.Get(3)).String()})
			return 0
		},
		"addFormFile": func(state *lua.LState) int {
			request := checkRequest(state)
			request.parts = append(request.parts, formPart{name: state.CheckString(2), filePath: state.CheckString(3)})
			return 0
		},
		"setTimeout": func(state *lua.LState) int {
			checkRequest(state).timeout = time.Duration(float64(state.CheckNumber(2)) * float64(time.Second))
			return 0
		},
		"start": func(state *lua.LState) int {
			request := checkRequest(state)
			if !request.started {
				request.started = true
				network.queue = append(network.queue, request)
			}
			return 0
		},
		"getResponseString": func(state *lua.LState) int {
			state.Push(lua.LString(checkRequest(state).body))
			return 1
		},
		"getResponseData": func(state *lua.LState) int {
			state.Push(lua.LString(checkRequest(state).body))
			return 1
		},
		"getResponseDataLength": func(state *lua.LState) int {
			state.Push(lua.LNumber(len(checkRequest(state).body)))
			return 1
		},
		"getResponseStatusCode": func(state *lua.LState) int {
			state.Push(lua.LNumber(checkRequest(state).status))
			return 1
		},
		"setAcceptEncoding": noOperation,
		"retain":            noOperation,
		"release":           noOperation,
	}
	return network
}

func noOperation(*lua.LState) int { return 0 }

func checkRequest(state *lua.LState) *httpRequest {
	request, ok := state.CheckUserData(1).Value.(*httpRequest)
	if !ok {
		state.ArgError(1, "cc.HTTPRequest expected")
	}
	return request
}

// create is cc.HTTPRequest:createWithUrl(callback, url, method).
func (network *network) create(state *lua.LState) int {
	request := &httpRequest{callback: state.CheckFunction(1), url: state.CheckString(2), method: state.OptInt(3, 1), timeout: 30 * time.Second}
	metatable := state.NewTable()
	metatable.RawSetString("__index", state.NewFunction(func(state *lua.LState) int {
		name := state.CheckString(2)
		method, ok := network.methods[name]
		if !ok {
			missing := state.GetGlobal("__vc").(*lua.LTable).RawGetString("report").(*lua.LTable).RawGetString("missing").(*lua.LTable)
			key := lua.LString("cc.HTTPRequest." + name)
			count, _ := missing.RawGet(key).(lua.LNumber)
			missing.RawSet(key, count+1)
			method = noOperation
		}
		state.Push(state.NewFunction(method))
		return 1
	}))
	request.userdata = state.NewUserData()
	request.userdata.Value = request
	state.SetMetatable(request.userdata, metatable)
	state.Push(request.userdata)
	return 1
}

// complete performs every request started before this point, in start order, and runs the stock callbacks.
func (network *network) complete(state *lua.LState) {
	queue := network.queue
	network.queue = nil
	invoke := state.GetGlobal("__vc").(*lua.LTable).RawGetString("invoke")
	for _, request := range queue {
		exchange := network.perform(request)
		network.report.Requests = append(network.report.Requests, exchange)
		event := state.NewTable()
		event.RawSetString("name", lua.LString("completed"))
		if exchange.Failure != "" {
			event.RawSetString("name", lua.LString("failed"))
		}
		event.RawSetString("request", request.userdata)
		if err := state.CallByParam(lua.P{Fn: invoke, NRet: 0, Protect: true}, request.callback, event); err != nil {
			network.report.LuaErrors = append(network.report.LuaErrors, err.Error())
		}
	}
}

func (network *network) target(raw string) string {
	for _, origin := range stockOrigins {
		if strings.HasPrefix(raw, origin) {
			return network.origin + strings.TrimPrefix(raw, origin)
		}
	}
	return raw
}

func (network *network) perform(request *httpRequest) Exchange {
	target := network.target(request.url)
	exchange := Exchange{At: network.clock(), Method: "POST", URL: target}
	if request.method == 0 {
		exchange.Method = "GET"
	}
	body, contentType, err := request.encode(&exchange)
	if err != nil {
		exchange.Failure = err.Error()
		return exchange
	}
	outgoing, err := http.NewRequest(exchange.Method, target, body)
	if err != nil {
		exchange.Failure = err.Error()
		return exchange
	}
	if contentType != "" {
		outgoing.Header.Set("Content-Type", contentType)
	}
	response, err := (&http.Client{Timeout: request.timeout}).Do(outgoing)
	if err != nil {
		exchange.Failure = err.Error()
		return exchange
	}
	defer response.Body.Close()
	request.body, err = io.ReadAll(response.Body)
	if err != nil {
		exchange.Failure = err.Error()
		return exchange
	}
	request.status = response.StatusCode
	exchange.Status, exchange.Bytes = response.StatusCode, len(request.body)
	var stock struct {
		ErrorCode float64 `json:"error_code"`
	}
	if json.Unmarshal(request.body, &stock) == nil {
		exchange.ErrorCode = stock.ErrorCode
	}
	var decoded any
	if json.Unmarshal(request.body, &decoded) == nil {
		exchange.NullFields = nullFields(decoded, "")
	}
	return exchange
}

func nullFields(value any, path string) []string {
	var found []string
	switch typed := value.(type) {
	case nil:
		return []string{path}
	case map[string]any:
		for key, child := range typed {
			found = append(found, nullFields(child, path+"."+key)...)
		}
	case []any:
		for index, child := range typed {
			found = append(found, nullFields(child, fmt.Sprintf("%s[%d]", path, index))...)
		}
	}
	sort.Strings(found)
	return found
}

// encode builds the body CCHTTPRequest sends: url-encoded POST values joined as given (stock already escapes them), otherwise a
// multipart form of contents and files in the order they were added.
func (request *httpRequest) encode(exchange *Exchange) (io.Reader, string, error) {
	if len(request.parts) == 0 && len(request.values) == 0 {
		exchange.Encoding = "empty"
		return nil, "", nil
	}
	if len(request.parts) == 0 {
		exchange.Encoding = "form-urlencoded"
		body := strings.Join(request.values, "&")
		if values, err := url.ParseQuery(body); err == nil {
			exchange.MID = midOf([]byte(values.Get("payload")))
		}
		return strings.NewReader(body), "application/x-www-form-urlencoded", nil
	}
	exchange.Encoding = "multipart"
	var buffer bytes.Buffer
	writer := multipart.NewWriter(&buffer)
	for _, part := range request.parts {
		if part.filePath == "" {
			if err := writer.WriteField(part.name, part.value); err != nil {
				return nil, "", err
			}
			request.noteMID(exchange, part)
			continue
		}
		content, err := os.ReadFile(part.filePath)
		if err != nil {
			return nil, "", fmt.Errorf("form file %s: %w", part.name, err)
		}
		file, err := writer.CreateFormFile(part.name, filepath.Base(part.filePath))
		if err != nil {
			return nil, "", err
		}
		if _, err := file.Write(content); err != nil {
			return nil, "", err
		}
	}
	if err := writer.Close(); err != nil {
		return nil, "", err
	}
	return &buffer, writer.FormDataContentType(), nil
}

func (request *httpRequest) noteMID(exchange *Exchange, part formPart) {
	if part.name == "mid" {
		fmt.Sscan(part.value, &exchange.MID)
		return
	}
	if part.name != "payload" {
		return
	}
	reader, err := zlib.NewReader(strings.NewReader(part.value))
	if err != nil {
		return
	}
	defer reader.Close()
	inflated, err := io.ReadAll(reader)
	if err == nil {
		exchange.Encoding = "multipart-zlib"
		exchange.MID = midOf(inflated)
	}
}

func midOf(payload []byte) float64 {
	var envelope struct {
		MID float64 `json:"mid"`
	}
	if json.Unmarshal(payload, &envelope) != nil {
		return 0
	}
	return envelope.MID
}
