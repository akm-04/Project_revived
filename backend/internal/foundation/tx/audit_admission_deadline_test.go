package tx

import (
	"context"
	"testing"
	"time"
)

func TestAuditExpiredRequestAdmissionHasNoRemainingWait(t *testing.T) {
	requestContext := WithAdmissionDeadline(context.Background(), time.Now().Add(-time.Hour))
	if remaining := admissionWait(requestContext, shortAcquireProfile()); remaining != 0 {
		t.Fatalf("expired request receives a new admission wait: %v", remaining)
	}
}

func TestAuditRequestAdmissionDoesNotExtendShortRemainingBudget(t *testing.T) {
	transactionProfile := profile()
	transactionProfile.AcquireTimeout = 2 * time.Hour
	requestContext := WithAdmissionDeadline(context.Background(), time.Now().Add(time.Hour))
	if remaining := admissionWait(requestContext, transactionProfile); remaining > time.Hour {
		t.Fatalf("request admission exceeds its remaining hour: %v", remaining)
	}
}
