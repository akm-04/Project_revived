package i5

import "testing"

func TestMissingPrivilegeProviderFailsStartup(t *testing.T) {
	if err := (Service{}).ValidateStartup(); err == nil {
		t.Fatal("a service without a privilege provider must fail startup")
	}
	service := Service{Privileges: BaselinePrivilegeProvider{}}
	if err := service.ValidateStartup(); err != nil {
		t.Fatalf("baseline privilege provider rejected at startup: %v", err)
	}
}
