package client

import (
	"encoding/json"
	"sort"

	lua "github.com/yuin/gopher-lua"
)

type skeletonFile struct {
	Bones []struct {
		Name string  `json:"name"`
		X    float64 `json:"x"`
		Y    float64 `json:"y"`
	} `json:"bones"`
	Animations map[string]json.RawMessage `json:"animations"`
}

type skeletonEvent struct {
	Time   float64 `json:"time"`
	Name   string  `json:"name"`
	Int    float64 `json:"int"`
	Float  float64 `json:"float"`
	String string  `json:"string"`
}

// latestTime is an animation's duration: the last "time" of any of its timelines, as spine-runtimes computes it.
func latestTime(value any) float64 {
	latest := 0.0
	switch typed := value.(type) {
	case map[string]any:
		if time, ok := typed["time"].(float64); ok {
			latest = time
		}
		for _, child := range typed {
			latest = max(latest, latestTime(child))
		}
	case []any:
		for _, child := range typed {
			latest = max(latest, latestTime(child))
		}
	}
	return latest
}

// skeletonTable reads a Spine 2.1 skeleton JSON into {animations = {name = {duration, events}}, bones = {name = {x, y}}}.
func skeletonTable(state *lua.LState, data []byte) (*lua.LTable, error) {
	var file skeletonFile
	if err := json.Unmarshal(data, &file); err != nil {
		return nil, err
	}
	bones := state.NewTable()
	for _, bone := range file.Bones {
		position := state.NewTable()
		position.RawSetString("x", lua.LNumber(bone.X))
		position.RawSetString("y", lua.LNumber(bone.Y))
		bones.RawSetString(bone.Name, position)
	}
	animations := state.NewTable()
	for name, raw := range file.Animations {
		var timelines any
		var keyed struct {
			Events []skeletonEvent `json:"events"`
		}
		if err := json.Unmarshal(raw, &timelines); err != nil {
			return nil, err
		}
		if err := json.Unmarshal(raw, &keyed); err != nil {
			return nil, err
		}
		sort.SliceStable(keyed.Events, func(left, right int) bool { return keyed.Events[left].Time < keyed.Events[right].Time })
		events := state.NewTable()
		for _, event := range keyed.Events {
			entry := state.NewTable()
			entry.RawSetString("time", lua.LNumber(event.Time))
			entry.RawSetString("name", lua.LString(event.Name))
			entry.RawSetString("intValue", lua.LNumber(event.Int))
			entry.RawSetString("floatValue", lua.LNumber(event.Float))
			entry.RawSetString("stringValue", lua.LString(event.String))
			events.Append(entry)
		}
		animation := state.NewTable()
		animation.RawSetString("duration", lua.LNumber(latestTime(timelines)))
		animation.RawSetString("events", events)
		animations.RawSetString(name, animation)
	}
	skeleton := state.NewTable()
	skeleton.RawSetString("animations", animations)
	skeleton.RawSetString("bones", bones)
	return skeleton, nil
}

func (files *fileSystem) loadSkeleton(state *lua.LState) int {
	data, ok := files.read(state.CheckString(1))
	if !ok {
		state.Push(lua.LNil)
		state.Push(lua.LString("unreadable"))
		return 2
	}
	skeleton, err := skeletonTable(state, data)
	if err != nil {
		state.Push(lua.LNil)
		state.Push(lua.LString(err.Error()))
		return 2
	}
	state.Push(skeleton)
	return 1
}
