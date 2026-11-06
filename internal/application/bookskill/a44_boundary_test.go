package bookskill

import (
	"context"
	"errors"
	"reflect"
	"strings"
	"testing"
	"time"

	book "gxb.local/backend/v2/internal/domain/bookskill"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const a44Revision = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

type a44Queryer struct{}

func (a44Queryer) QueryRow(context.Context, string, ...any) tx.Row { return a44Row{} }

type a44Row struct{}

func (a44Row) Scan(...any) error { return errors.New("a44 fixture never queries") }

type a44Owner struct {
	root   book.Root
	writes int
}

func (o *a44Owner) ReadRootTx(context.Context, tx.Queryer, identity.PlayerID) (book.Root, error) {
	return o.root, nil
}
func (o *a44Owner) LockRootTx(context.Context, tx.Tx, identity.PlayerID) (book.Root, error) {
	return book.Root{}, errors.New("a44 fixture does not lock")
}
func (o *a44Owner) SaveRootTx(context.Context, tx.Tx, book.Root, int64) error {
	o.writes++
	return errors.New("a44 fixture does not save")
}
func (*a44Owner) LockAdmissionTx(context.Context, tx.Tx, identity.PlayerID, string) (Admission, bool, error) {
	return Admission{}, false, errors.New("a44 fixture does not admit")
}
func (*a44Owner) SaveAdmissionTx(context.Context, tx.Tx, Admission) error {
	return errors.New("a44 fixture does not admit")
}

type a44Content struct {
	catalogs map[string]book.Catalog
	err      error
	reads    []string
}

func (c *a44Content) BookCatalogTx(_ context.Context, _ tx.Queryer, revision string) (book.Catalog, error) {
	c.reads = append(c.reads, revision)
	if c.err != nil {
		return book.Catalog{}, c.err
	}
	catalog, ok := c.catalogs[revision]
	if !ok {
		return book.Catalog{}, book.ErrUnqualified
	}
	return catalog, nil
}
func (*a44Content) BookInputsActive(context.Context) (string, bool, error) {
	return "", false, errors.New("a44 fixture does not activate")
}
func (*a44Content) BookInputsRevisionTx(context.Context, tx.Queryer, string) (bool, error) {
	return false, errors.New("a44 fixture does not activate")
}

func a44Catalog(extension bool) book.Catalog {
	counts := map[int64]int64{1: 6, 3: 6, 4: 100}
	if extension {
		counts[2] = 8
		counts[5] = 5
		counts[6] = 5
		counts[7] = 5
	}
	buildings := map[[2]int64]book.BookBuildingRule{}
	for sourceType, levels := range counts {
		for level := int64(1); level <= levels; level++ {
			buildings[[2]int64{sourceType, level}] = book.BookBuildingRule{Type: sourceType, Level: level, Duration: 60, RequiresType: 1}
		}
	}
	return book.Catalog{
		Buildings: buildings,
		Books:     map[int64]book.BookRule{100: {ID: 100, Star: 1, Type: 1, Skills: []int64{200}}},
		Skills:    map[int64]book.BookSkillRule{200: {ID: 200, Book: 100, Partner: 1, CostClass: 1, Times: []int64{60}}},
		Costs:     map[[2]int64]book.BookCostRule{{1, 1}: {Level: 1, Class: 1, Resources: map[string]int64{"mana": 1}}},
	}
}

func a44Root(at time.Time) book.Root {
	return book.Root{Player: identity.PlayerID(1), Version: 1, Revision: strings.Repeat("c", 64), Facts: book.Seed(), CreatedAt: at, UpdatedAt: at}
}

func a44Service(catalog book.Catalog) (*Service, *a44Owner, *a44Content, time.Time) {
	at := time.Unix(1000, 0).UTC()
	owner := &a44Owner{root: a44Root(at)}
	content := &a44Content{catalogs: map[string]book.Catalog{a44Revision: catalog}}
	return &Service{Owner: owner, Content: content}, owner, content, at
}

// Baseline control: an old three-building root read through a seven-rule
// caller catalog is already valid and must stay so. Inputs remain exactly the
// caller revision, and the pure port performs no owner write.
func TestA44BookInputsLegacyRootSevenRuleCatalog(t *testing.T) {
	catalog := a44Catalog(true)
	service, owner, content, at := a44Service(catalog)
	inputs, e := service.BookInputsTx(context.Background(), a44Queryer{}, InputScope{Player: 1, ContentRevision: a44Revision, ObservedAt: at})
	if e != nil {
		t.Fatalf("legacy root rejected by seven-rule catalog: %v", e)
	}
	if inputs.ContentRevision != a44Revision || !inputs.ObservedAt.Equal(at) {
		t.Fatalf("caller pin changed: revision %q observed %v", inputs.ContentRevision, inputs.ObservedAt)
	}
	if len(inputs.Catalog.Buildings) != 135 || !reflect.DeepEqual(inputs.Catalog.Buildings, catalog.Buildings) {
		t.Fatal("returned catalog is not the caller catalog")
	}
	if !reflect.DeepEqual(inputs.Applied, book.Seed()) || inputs.MaterializationDue {
		t.Fatalf("legacy applied facts changed: %+v", inputs.Applied)
	}
	if owner.writes != 0 {
		t.Fatalf("pure BookInputs wrote %d roots", owner.writes)
	}
	if !reflect.DeepEqual(content.reads, []string{a44Revision}) {
		t.Fatalf("catalog reads = %v, want only the caller revision", content.reads)
	}
}

// The command boundary is independent of catalogs: type 2/5/6/7 is refused
// before any content lookup.
func TestA44CommandRejectsExtensionTypesToday(t *testing.T) {
	for _, buildingType := range []int64{2, 5, 6, 7} {
		if e := (Command{Family: Start, Type: buildingType}).Validate(); !errors.Is(e, book.ErrInvalid) {
			t.Fatalf("extension type %d admitted: %v", buildingType, e)
		}
	}
	for _, buildingType := range []int64{1, 3, 4} {
		if e := (Command{Family: Start, Type: buildingType}).Validate(); e != nil {
			t.Fatalf("legacy type %d refused: %v", buildingType, e)
		}
	}
}

// Current refusal that the qualified view must later replace without
// weakening: an old-pinned consumer cannot read a root holding extension
// facts, even when the caller catalog knows those rule rows.
func TestA44OldConsumerRefusesPersistedExtensionFactsToday(t *testing.T) {
	for name, catalog := range map[string]book.Catalog{"seven-rule": a44Catalog(true), "legacy": a44Catalog(false)} {
		service, owner, _, at := a44Service(catalog)
		owner.root.Facts.Buildings[2] = book.Building{Level: 1}
		_, e := service.BookInputsTx(context.Background(), a44Queryer{}, InputScope{Player: 1, ContentRevision: a44Revision, ObservedAt: at})
		if !errors.Is(e, book.ErrUnqualified) {
			t.Fatalf("%s caller accepted unqualified extension facts: %v", name, e)
		}
	}
}

// A pin that cannot be resolved must fail closed, never yield partial inputs.
func TestA44UnavailableCatalogFailsClosed(t *testing.T) {
	service, _, content, at := a44Service(a44Catalog(true))
	content.err = errors.New("content revision unavailable")
	inputs, e := service.BookInputsTx(context.Background(), a44Queryer{}, InputScope{Player: 1, ContentRevision: a44Revision, ObservedAt: at})
	if e == nil || inputs.ContentRevision != "" || inputs.Catalog.Buildings != nil {
		t.Fatalf("unavailable catalog returned partial inputs: %+v %v", inputs, e)
	}
}
