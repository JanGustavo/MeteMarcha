// Package exercisecatalog owns stable exercise identities and curated references.
package exercisecatalog

import (
	"embed"
	"encoding/json"
	"regexp"
	"strings"
)

//go:embed catalog.json
var files embed.FS

type Video struct {
	URL      string `json:"url"`
	Language string `json:"language"`
}
type Entry struct {
	ID          string   `json:"id"`
	Name        string   `json:"name"`
	Muscle      string   `json:"muscle"`
	Equipment   string   `json:"equipment"`
	Aliases     []string `json:"aliases"`
	MiniWorkout bool     `json:"mini_workout"`
	Video       *Video   `json:"video"`
}

var Entries = func() []Entry {
	data, err := files.ReadFile("catalog.json")
	if err != nil {
		panic(err)
	}
	var catalog struct {
		Exercises []Entry `json:"exercises"`
	}
	if err := json.Unmarshal(data, &catalog); err != nil {
		panic(err)
	}
	return catalog.Exercises
}()

var punctuation = regexp.MustCompile(`[^a-z0-9]+`)

func Normalize(s string) string {
	s = strings.ToLower(strings.TrimSpace(s))
	s = strings.NewReplacer("á", "a", "à", "a", "â", "a", "ã", "a", "é", "e", "ê", "e", "í", "i", "ó", "o", "ô", "o", "õ", "o", "ú", "u", "ü", "u", "ç", "c").Replace(s)
	return strings.TrimSpace(punctuation.ReplaceAllString(s, " "))
}

func compatibleEquipment(equipment string, entry Entry) bool {
	supplied, expected := Normalize(equipment), Normalize(entry.Equipment)
	if supplied == "" || supplied == expected {
		return true
	}
	bodyweight := map[string]bool{"peso corporal": true, "peso do corpo": true, "corporal": true, "sem equipamento": true, "nenhum": true, "solo": true, "colchonete": true, "bodyweight": true}
	if expected == "peso corporal" && (supplied == "livre" || bodyweight[supplied]) {
		return true
	}
	return (entry.ID == "pull-up" || entry.ID == "chin-up" || entry.ID == "scapular-pull-up") && bodyweight[supplied]
}

// Match requires a known name/alias and matching equipment, never fuzzy matching.
func Match(name, equipment string) *Entry {
	for _, entry := range Entries {
		if !compatibleEquipment(equipment, entry) {
			continue
		}
		for _, alias := range append([]string{entry.Name}, entry.Aliases...) {
			if Normalize(alias) == Normalize(name) {
				found := entry
				return &found
			}
		}
	}
	return nil
}
