package stockruntime

import "testing"

func TestLibrarySelectInfoRetainsSourceReward(t *testing.T) {
	for _, test := range []struct {
		input  string
		reward int64
	}{
		{"0|203001", 0}, {"1|203001", 1}, {"2|203001", 2}, {"3|203001", 3},
	} {
		option, reward, present, err := librarySelectInfo(map[string]any{"select_info": test.input})
		if err != nil || option != 203001 || reward != test.reward || !present {
			t.Fatalf("%q: %d %v %v %v", test.input, option, reward, present, err)
		}
	}
	for _, input := range []any{"-1|203001", "+1|203001", "01|203001", "2|0", "2|203001|1", "99999999999999999999|203001", int64(2)} {
		if _, _, _, err := librarySelectInfo(map[string]any{"select_info": input}); err == nil {
			t.Fatalf("accepted malformed select_info %v", input)
		}
	}
	option, reward, present, err := librarySelectInfo(map[string]any{})
	if err != nil || option != 0 || reward != 0 || present {
		t.Fatalf("end-call: %d %v %v %v", option, reward, present, err)
	}
}
