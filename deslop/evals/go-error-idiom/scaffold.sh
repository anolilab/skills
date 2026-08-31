#!/usr/bin/env bash
# Go inverts entry 2. The repeated `if err != nil` is the language's idiom and
# must survive; what must go is the check that cannot fire, plus an
# `interface{}` wrapper hiding an unchecked type assertion.
set -euo pipefail

git init -q .
git config user.email eval@example.com
git config user.name Eval

mkdir -p store

cat >go.mod <<'BASE'
module example.com/records

go 1.22
BASE

# Every error is wrapped with context. Nothing is commented. Callers are trusted.
cat >store/store.go <<'BASE'
package store

import (
	"encoding/json"
	"fmt"
	"os"
)

type Record struct {
	Key   string `json:"key"`
	Value string `json:"value"`
}

func Load(path string) ([]Record, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("read %s: %w", path, err)
	}

	var records []Record
	if err := json.Unmarshal(data, &records); err != nil {
		return nil, fmt.Errorf("parse %s: %w", path, err)
	}

	return records, nil
}
BASE

git add -A
git commit -qm "add record store"
git branch -M main
git checkout -q -b feature/save

cat >store/store.go <<'CHANGE'
package store

import (
	"encoding/json"
	"fmt"
	"os"
)

type Record struct {
	Key   string `json:"key"`
	Value string `json:"value"`
}

func Load(path string) ([]Record, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("read %s: %w", path, err)
	}

	var records []Record
	if err := json.Unmarshal(data, &records); err != nil {
		return nil, fmt.Errorf("parse %s: %w", path, err)
	}

	return records, nil
}

func Save(path string, records []Record) error {
	data, err := json.Marshal(records)
	if err != nil {
		return fmt.Errorf("encode %s: %w", path, err)
	}

	// Check the marshalling error once more before we touch the disk.
	if err != nil {
		return err
	}

	if err := os.WriteFile(path, data, 0o644); err != nil {
		return fmt.Errorf("write %s: %w", path, err)
	}

	return nil
}

// keyOf pulls the key out of a record.
func keyOf(record interface{}) string {
	return record.(Record).Key
}

func Keys(records []Record) []string {
	// Bail out early if there is nothing to do.
	if records == nil || len(records) == 0 {
		return []string{}
	}

	keys := make([]string, 0, len(records))
	for _, record := range records {
		keys = append(keys, keyOf(record))
	}

	return keys
}
CHANGE

git add -A
