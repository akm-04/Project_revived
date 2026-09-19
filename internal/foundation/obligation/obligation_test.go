package obligation

import (
	"testing"
	"time"
)

func TestValidate(t *testing.T) {
	o := Obligation{Kind: "mail.delivery", SemanticKey: "x", DueAt: time.Now(), Args: []byte(`{"mail_id":1}`), Queue: "default"}
	if err := o.Validate(); err != nil {
		t.Fatal(err)
	}
	o.SemanticKey = ""
	if o.Validate() == nil {
		t.Fatal("expected invalid")
	}
}
