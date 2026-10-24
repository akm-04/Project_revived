package lockkey

import "errors"

// CreationFence documents the lock/constraint pair required before discovering
// or creating a potentially absent child row. FOR UPDATE on an absent child is
// never considered protection.
type CreationFence struct {
	Parent           Key
	UniqueConstraint string
}

func (f CreationFence) Validate() error {
	if f.Parent.DomainRank == 0 || f.Parent.OwnerKind == "" || f.Parent.Identity.Kind == 0 {
		return errors.New("missing canonical parent/directory fence")
	}
	if f.UniqueConstraint == "" {
		return errors.New("missing uniqueness constraint name")
	}
	return nil
}
