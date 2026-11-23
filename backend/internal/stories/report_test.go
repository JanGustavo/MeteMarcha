package stories

import (
	"strings"
	"testing"
)

func TestValidateWorkoutReport(t *testing.T) {
	valid := `{"version":1,"title":"Treino A","date":"2026-11-20","duration_seconds":60,"sets":[{"exercise":"Supino","number":1,"weight_kg":20,"reps":10,"side":"ambos","completed":true,"equipment":"barra","notes":"","at":"2026-11-20"}]}`
	if _, err := validateReport(valid); err != nil {
		t.Fatal(err)
	}
	for _, raw := range []string{`{}`, `{"version":99}`, `{"private_history":true}`} {
		if _, err := validateReport(raw); err == nil {
			t.Fatalf("accepted %s", raw)
		}
	}
}

func TestCalisthenicsReportUnits(t *testing.T) {
	raw := `{"version":1,"title":"Calistenia","date":"2026-11-22","duration_seconds":60,"sets":[{"exercise":"Prancha","number":1,"weight_kg":0,"reps":0,"side":"ambos","completed":true,"calisthenics":{"measure":"seconds","value":45,"variation":"Prancha","load_source":"unknown","external_kg":null,"apparatus":"mochila azul","assistance":""}}]}`
	normalized, err := validateReport(raw)
	if err != nil || !strings.Contains(normalized, `"external_kg":null`) {
		t.Fatal("unknown load was lost", err, normalized)
	}
	if _, err = validateReport(strings.Replace(raw, `"value":45`, `"value":-1`, 1)); err == nil {
		t.Fatal("negative duration accepted")
	}
}
