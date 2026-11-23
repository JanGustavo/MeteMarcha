package stories

import (
	"encoding/json"
	"github.com/JanGustavo/MeteMarcha/backend/internal/platform"
	"math"
	"strings"
)

// WorkoutReport is a publication snapshot, never a link to a private local database.
type WorkoutReport struct {
	Version  int         `json:"version"`
	Title    string      `json:"title"`
	Date     string      `json:"date"`
	Duration int         `json:"duration_seconds"`
	Sets     []ReportSet `json:"sets"`
}
type Calisthenics struct {
	Measure    string   `json:"measure"`
	Value      float64  `json:"value"`
	Variation  string   `json:"variation"`
	LoadSource string   `json:"load_source"`
	ExternalKG *float64 `json:"external_kg"`
	Apparatus  string   `json:"apparatus"`
	Assistance string   `json:"assistance"`
}

func (c Calisthenics) valid() bool {
	if (c.Measure != "reps" && c.Measure != "seconds" && c.Measure != "meters") || math.IsNaN(c.Value) || math.IsInf(c.Value, 0) || c.Value <= 0 || c.Value > 100000 || c.Variation == "" || len(c.Variation) > 800 || len(c.Apparatus) > 800 || len(c.Assistance) > 800 {
		return false
	}
	if c.Measure == "reps" && c.Value != math.Trunc(c.Value) {
		return false
	}
	if c.LoadSource == "none" || c.LoadSource == "unknown" {
		return c.ExternalKG == nil && (c.LoadSource != "unknown" || c.Apparatus != "")
	}
	return (c.LoadSource == "measured" || c.LoadSource == "estimated" || c.LoadSource == "reported") && c.ExternalKG != nil && !math.IsNaN(*c.ExternalKG) && !math.IsInf(*c.ExternalKG, 0) && *c.ExternalKG >= 0 && *c.ExternalKG <= 10000 && (c.LoadSource != "estimated" || c.Apparatus != "")
}

type ReportSet struct {
	Calisthenics *Calisthenics `json:"calisthenics,omitempty"`
	Exercise     string        `json:"exercise"`
	Number       int           `json:"number"`
	Weight       float64       `json:"weight_kg"`
	Reps         int           `json:"reps"`
	Side         string        `json:"side"`
	Completed    bool          `json:"completed"`
	Equipment    string        `json:"equipment"`
	Notes        string        `json:"notes"`
	RPE          *float64      `json:"rpe,omitempty"`
	RIR          *int          `json:"rir,omitempty"`
	At           string        `json:"at"`
}

func validateReport(raw string) (string, error) {
	if raw == "" {
		return "", nil
	}
	bad := platform.NewError(422, "invalid_workout_report", "O relatório de treino é inválido ou grande demais.")
	if len(raw) > 128*1024 {
		return "", bad
	}
	var report WorkoutReport
	dec := json.NewDecoder(strings.NewReader(raw))
	dec.DisallowUnknownFields()
	if err := dec.Decode(&report); err != nil {
		return "", bad
	}
	if report.Version != 1 || len(report.Title) == 0 || len(report.Title) > 200 || len(report.Date) > 60 || report.Duration < 0 || report.Duration > 604800 || len(report.Sets) == 0 || len(report.Sets) > 500 {
		return "", bad
	}
	for _, s := range report.Sets {
		if s.Calisthenics != nil && !s.Calisthenics.valid() {
			return "", bad
		}
		if len(s.Exercise) == 0 || len(s.Exercise) > 200 || s.Number < 1 || s.Number > 1000 || math.IsNaN(s.Weight) || math.IsInf(s.Weight, 0) || s.Weight < 0 || s.Weight > 100000 || s.Reps < 0 || s.Reps > 100000 || len(s.Notes) > 2000 || len(s.Equipment) > 200 || len(s.At) > 60 || (s.Side != "ambos" && s.Side != "esquerdo" && s.Side != "direito") || (s.RPE != nil && (*s.RPE < 0 || *s.RPE > 10)) || (s.RIR != nil && (*s.RIR < 0 || *s.RIR > 100)) {
			return "", bad
		}
	}
	normalized, err := json.Marshal(report)
	return string(normalized), err
}
