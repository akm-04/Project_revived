package profile

import (
	"errors"
	"strings"
	"unicode/utf8"
)

// ModerateIntro applies the versioned scalar-safe case-sensitive source-list
// policy to an introduction and enforces its 40-codepoint bound.
func ModerateIntro(text string, words []string) (string, error) {
	if utf8.RuneCountInString(text) > 40 {
		return "", errors.New("invalid intro")
	}
	return MaskWords(text, words)
}

// MaskWords applies the same published corpus to text whose length the owning
// domain already bounds. Literal ASCII spaces are traversed and included in a
// matched span; the first terminal is masked. It never trusts prior client
// filtering.
func MaskWords(text string, words []string) (string, error) {
	if !utf8.ValidString(text) || strings.ContainsRune(text, 0) {
		return "", errors.New("invalid text")
	}
	type node struct {
		end      bool
		children map[rune]*node
	}
	root := &node{children: map[rune]*node{}}
	for _, word := range words {
		if word == "" || !utf8.ValidString(word) {
			return "", errors.New("invalid moderation word")
		}
		n := root
		for _, r := range word {
			if n.children[r] == nil {
				n.children[r] = &node{children: map[rune]*node{}}
			}
			n = n.children[r]
		}
		n.end = true
	}
	runes := []rune(text)
	for start := 0; start < len(runes); start++ {
		n := root
		for end := start; end < len(runes); end++ {
			if runes[end] != ' ' {
				n = n.children[runes[end]]
			}
			if n == nil {
				break
			}
			if n.end {
				for i := start; i <= end; i++ {
					runes[i] = '*'
				}
				start = end
				break
			}
		}
	}
	return string(runes), nil
}
