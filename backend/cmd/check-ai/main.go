// check-ai runs the real AI handler locally using server environment variables.
// It makes one provider request, stores no workout, and prints no credentials.
package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"github.com/JanGustavo/MeteMarcha/backend/internal/workoutai"
	"net/http"
	"net/http/httptest"
	"os"
)

func main() {
	mux := http.NewServeMux()
	workoutai.NewHandler().Register(mux, func(h http.HandlerFunc) http.HandlerFunc { return h })
	req := httptest.NewRequest("POST", "/v1/ai/workouts", bytes.NewBufferString(`{"mode":"generate","focus":"calistenia","minutes":15,"equipment":["Peso Corporal"]}`))
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
	fmt.Println("exercise_count", len(result.Workout.Days[0].Exercises))
	fmt.Println("validated_draft", true)
}
