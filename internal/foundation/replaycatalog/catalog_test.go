package replaycatalog

import "testing"

func TestEnabledReplayFamiliesAreCompleteAndUnique(t *testing.T) {
	if err := Validate(); err != nil {
		t.Fatal(err)
	}
	if len(Enabled) < 10 {
		t.Fatalf("unexpectedly small replay census: %d", len(Enabled))
	}
	var saveStory, grant, savedPreset bool
	ca73 := map[string]bool{"ca7.hero-skin-on": false, "ca7.hero-skin-cancel": false, "ca7.hero-illusion-select": false}
	wantGuild := map[string]bool{
		"i6c.guild-create": false, "i6c.guild-dissolve": false, "i6c.guild-apply-or-join": false,
		"i6c.guild-accept-application": false, "i6c.guild-refuse-application": false, "i6c.guild-leave": false,
		"i6c.guild-description": false, "i6c.guild-role": false, "i6c.guild-kick": false, "i6c.guild-settings": false,
		"i6c.guild-cancel-application": false, "i6c.guild-invite": false, "i6c.guild-accept-invite": false,
	}
	for _, f := range Enabled {
		if f.Name == "i5.save-story" {
			saveStory = f.Residual != "" && !f.Consumptive
		}
		if f.Name == "i5.grant" {
			grant = f.Consumptive && f.SemanticSource != ""
		}
		if f.Name == "ca5.saved-preset-replace" {
			savedPreset = f.IdentityClass == CurrentStateConvergence && !f.Consumptive && f.Residual != "" && f.ReceiptSchema == "gxb.ca5.saved-preset-replace.v1"
		}
		if _, ok := ca73[f.Name]; ok {
			switch f.Name {
			case "ca7.hero-skin-on":
				ca73[f.Name] = f.IdentityClass == CurrentStateConvergence && f.Consumptive && f.ReceiptSchema == "gxb.ca7-3.skin-on.v1" && f.Residual != ""
			case "ca7.hero-skin-cancel":
				ca73[f.Name] = f.IdentityClass == ParameterStateSet && !f.Consumptive && f.ReceiptSchema == "gxb.ca7-3.skin-cancel.v1"
			case "ca7.hero-illusion-select":
				ca73[f.Name] = f.IdentityClass == ParameterStateSet && !f.Consumptive && f.ReceiptSchema == "gxb.ca7-3.illusion-select.v1"
			}
		}
		if _, ok := wantGuild[f.Name]; ok {
			wantGuild[f.Name] = true
		}
		if f.Name == "i6c.guild-settings" && (!f.Consumptive || f.Residual == "") {
			t.Fatal("paid Guild rename ambiguity must remain explicitly classified")
		}
		if f.Name == "i6c.guild-leave" && f.IdentityClass != MembershipIncarnationBound {
			t.Fatalf("Guild leave identity class=%s", f.IdentityClass)
		}
	}
	for name, ok := range wantGuild {
		if !ok {
			t.Fatalf("missing Guild replay family %s", name)
		}
	}
	if !saveStory {
		t.Fatal("SaveStory ambiguity must remain explicitly classified")
	}
	if !grant {
		t.Fatal("Grant semantic identity classification missing")
	}
	if !savedPreset {
		t.Fatal("CA5 saved-preset current-state replay classification missing")
	}
	for name, ok := range ca73 {
		if !ok {
			t.Fatalf("CA7-3 replay classification missing or drifted for %s", name)
		}
	}
}
