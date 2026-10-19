// Package combatcorpus embeds the generated I7C-5A combat rules corpus: exact
// source Lua modules, decoded source table rows and the fighter-class
// manifest compiled by tools/generate_combat_corpus.py from the pinned archive.
package combatcorpus

import (
	"bytes"
	"compress/gzip"
	"crypto/sha256"
	"embed"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"strconv"
	"sync"
)

const (
	SchemaVersion       = 1
	SourceArchiveSHA256 = "c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf"
)

//go:embed generated
var generatedFS embed.FS

var ErrCorrupt = errors.New("combat corpus: embedded bytes differ from manifest")

type ModuleRecord struct {
	Name         string `json:"name"`
	SourcePath   string `json:"source_path"`
	SourceSHA256 string `json:"source_sha256"`
}
type TableRecord struct {
	Name          string `json:"name"`
	Kind          string `json:"kind"`
	Rows          int    `json:"rows"`
	SourcePath    string `json:"source_path"`
	SourceSHA256  string `json:"source_sha256"`
	Payload       string `json:"payload"`
	PayloadSHA256 string `json:"payload_sha256"`
}
type Manifest struct {
	SchemaVersion        int            `json:"schema_version"`
	CompilerVersion      string         `json:"compiler_version"`
	SourceArchiveSHA256  string         `json:"source_archive_sha256"`
	Modules              []ModuleRecord `json:"modules"`
	ModulesPayloadSHA256 string         `json:"modules_payload_sha256"`
	Tables               []TableRecord  `json:"tables"`
	FighterClassesSHA256 string         `json:"fighter_classes_sha256"`
}

// FighterClasses maps source table rows to their class_name and lists the
// fighter modules present under lib/battle/fighters. requireFighter has no fallback.
type FighterClasses struct {
	Present                 []string                     `json:"present"`
	ByTable                 map[string]map[string]string `json:"by_table"`
	PresentationOnlySummons []int64                      `json:"presentation_only_summons"`
}

// Table is one source data file as the server TableParser seam hands it to
// table-class callbacks: INDEXED rows go with their keys, NAMED rows alone.
type Table struct {
	Kind string            `json:"kind"`
	Keys map[string]int    `json:"keys,omitempty"`
	Rows []json.RawMessage `json:"rows"`
}

type Corpus struct {
	id       string
	manifest Manifest
	modules  map[string]string
	classes  FighterClasses
	present  map[string]bool
	tables   map[string]TableRecord
	cache    sync.Map
}

var (
	loadOnce sync.Once
	loaded   *Corpus
	loadErr  error
)

// Load verifies the embedded corpus once per process.
func Load() (*Corpus, error) {
	loadOnce.Do(func() { loaded, loadErr = load() })
	return loaded, loadErr
}

func load() (*Corpus, error) {
	raw, err := generatedFS.ReadFile("generated/manifest.json")
	if err != nil {
		return nil, err
	}
	sum := sha256.Sum256(raw)
	out := &Corpus{id: hex.EncodeToString(sum[:]), tables: map[string]TableRecord{}, present: map[string]bool{}}
	if err = json.Unmarshal(raw, &out.manifest); err != nil {
		return nil, err
	}
	if out.manifest.SchemaVersion != SchemaVersion || out.manifest.SourceArchiveSHA256 != SourceArchiveSHA256 || len(out.manifest.Modules) == 0 {
		return nil, ErrCorrupt
	}
	modules, err := payload("modules.json", out.manifest.ModulesPayloadSHA256)
	if err != nil {
		return nil, err
	}
	if err = json.Unmarshal(modules, &out.modules); err != nil {
		return nil, err
	}
	if len(out.modules) != len(out.manifest.Modules) {
		return nil, ErrCorrupt
	}
	for _, m := range out.manifest.Modules {
		if _, ok := out.modules[m.Name]; !ok {
			return nil, ErrCorrupt
		}
	}
	classes, err := payload("fighter_classes.json", out.manifest.FighterClassesSHA256)
	if err != nil {
		return nil, err
	}
	if err = json.Unmarshal(classes, &out.classes); err != nil {
		return nil, err
	}
	for _, name := range out.classes.Present {
		out.present[name] = true
	}
	for _, t := range out.manifest.Tables {
		out.tables[t.Name] = t
	}
	return out, nil
}

func payload(name, want string) ([]byte, error) {
	compressed, err := generatedFS.ReadFile("generated/" + name + ".gz")
	if err != nil {
		return nil, err
	}
	reader, err := gzip.NewReader(bytes.NewReader(compressed))
	if err != nil {
		return nil, err
	}
	data, err := io.ReadAll(reader)
	if err != nil {
		return nil, err
	}
	sum := sha256.Sum256(data)
	if hex.EncodeToString(sum[:]) != want {
		return nil, fmt.Errorf("%w: %s", ErrCorrupt, name)
	}
	return data, nil
}

// ID is the SHA-256 of the canonical manifest bytes.
func (c *Corpus) ID() string                  { return c.id }
func (c *Corpus) SourceArchiveSHA256() string { return c.manifest.SourceArchiveSHA256 }
func (c *Corpus) Manifest() Manifest          { return c.manifest }

// Module returns exact source text for a dotted module name.
func (c *Corpus) Module(name string) (string, bool) {
	v, ok := c.modules[name]
	return v, ok
}

// Table decodes and verifies one data file on first use.
func (c *Corpus) Table(name string) (*Table, error) {
	if v, ok := c.cache.Load(name); ok {
		return v.(*Table), nil
	}
	record, ok := c.tables[name]
	if !ok {
		return nil, fmt.Errorf("combat corpus: table %q is not in the pinned corpus", name)
	}
	data, err := payload(record.Payload, record.PayloadSHA256)
	if err != nil {
		return nil, err
	}
	var t Table
	if err = json.Unmarshal(data, &t); err != nil {
		return nil, err
	}
	if t.Kind != record.Kind || len(t.Rows) != record.Rows {
		return nil, ErrCorrupt
	}
	v, _ := c.cache.LoadOrStore(name, &t)
	return v.(*Table), nil
}

// FighterClass resolves a partner, super_partner, pet, activity_partner or
// monster row to its class_name and reports whether that fighter module exists.
func (c *Corpus) FighterClass(table string, id int64) (class string, present bool, known bool) {
	rows, ok := c.classes.ByTable[table]
	if !ok {
		return "", false, false
	}
	class, known = rows[strconv.FormatInt(id, 10)]
	return class, known && class != "" && c.present[class], known
}

// Classes is the fighter-class manifest, for qualification sweeps.
func (c *Corpus) Classes() FighterClasses { return c.classes }
