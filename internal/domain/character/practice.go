package character

import "errors"

const MaxPracticeAttr = 200

type PracticeAttrs [3]int64

func (p PracticeAttrs) Validate() error {
	for _, v := range p {
		if v < 0 || v > MaxPracticeAttr {
			return errors.New("character practice: attribute outside canonical bounds")
		}
	}
	return nil
}
