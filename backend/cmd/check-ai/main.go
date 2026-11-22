// check-ai runs the real AI handler locally using server environment variables.
// It makes one provider request, stores no workout, and prints no credentials.
package main

import (
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"github.com/JanGustavo/MeteMarcha/backend/internal/workoutai"
	"net/http"
	"net/http/httptest"
	"os"
)

func main() {
	focus := flag.String("focus", "calistenia", "Foco")
	split := flag.String("split", "FULL_BODY", "Divisão")
	minutes := flag.Int("minutes", 15, "Minutos por sessão")
	flag.Parse()
	input := map[string]any{"mode": "generate", "focus": *focus, "minutes": *minutes, "split": *split, "equipment": []string{"Peso Corporal"}}
	if *focus == "musculacao" {
		input["equipment"] = []string{"Peso Corporal", "Barra", "Haltere", "Cabo", "Máquina"}
		input["goal"] = "hipertrofia"
		input["experience"] = "iniciante"
		input["text"] = "Academia cheia, prefiro alternativas com halteres quando possível."
	}
	payload, _ := json.Marshal(input)
	mux := http.NewServeMux()
	handler := workoutai.NewHandler()
	handler.OnInvalidDraft = func(workout workoutai.Workout) {
		for _, day := range workout.Days {
			fmt.Println("invalid_day", day.Letter, "exercise_count", len(day.Exercises))
			for _, exercise := range day.Exercises {
				fmt.Println("exercise", exercise.Name, "equipment", exercise.Equipment, "volume", exercise.Volume, "rest", exercise.Rest)
			}
		}
	}
	handler.Register(mux, func(h http.HandlerFunc) http.HandlerFunc { return h })
	req := httptest.NewRequest("POST", "/v1/ai/workouts", bytes.NewReader(payload))
	out := httptest.NewRecorder()
	mux.ServeHTTP(out, req)
	fmt.Println("ai_handler_status", out.Code)
	if out.Code != 200 {
		var result struct {
			Error struct {
				Code string `json:"code"`
			} `json:"error"`
		}
		json.Unmarshal(out.Body.Bytes(), &result)
		fmt.Println("error_code", result.Error.Code)
		os.Exit(1)
	}
	var result struct {
		Workout workoutai.Workout `json:"workout"`
	}
	if json.Unmarshal(out.Body.Bytes(), &result) != nil {
		os.Exit(1)
	}
	fmt.Println("workout_days", len(result.Workout.Days))
	for _, day := range result.Workout.Days {
		fmt.Println("day", day.Letter, "exercise_count", len(day.Exercises))
		for _, exercise := range day.Exercises {
			fmt.Println("exercise", exercise.Name, "equipment", exercise.Equipment, "volume", exercise.Volume)
		}
	}
	fmt.Println("validated_draft", true)
}
