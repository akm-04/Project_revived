package amf3

import "fmt"

type Undefined struct{}

var UndefinedValue = Undefined{}

type Property struct {
	Name  string
	Value any
}
type Object struct{ Properties []Property }

func (o *Object) Get(name string) (any, bool) {
	if o == nil {
		return nil, false
	}
	for _, p := range o.Properties {
		if p.Name == name {
			return p.Value, true
		}
	}
	return nil, false
}
func (o *Object) Map() map[string]any {
	m := make(map[string]any, len(o.Properties))
	if o != nil {
		for _, p := range o.Properties {
			m[p.Name] = p.Value
		}
	}
	return m
}

func (o *Object) StrictMap() (map[string]any, error) {
	m := make(map[string]any)
	if o == nil {
		return m, nil
	}
	for _, p := range o.Properties {
		if _, exists := m[p.Name]; exists {
			return nil, fmt.Errorf("duplicate AMF3 object property %q", p.Name)
		}
		m[p.Name] = p.Value
	}
	return m, nil
}
