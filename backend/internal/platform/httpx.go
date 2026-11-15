package platform

import (
	"encoding/json"
	"errors"
	"log/slog"
	"net/http"
)

// APIError é um erro "esperado" que já sabe como virar resposta HTTP.
// As regras de negócio devolvem esses erros (ex.: roda cheia → 409) e o
// handler só precisa chamar WriteError.
type APIError struct {
	Status  int    `json:"-"`
	Code    string `json:"code"`    // estável, para o Flutter tratar (ex.: "group_full")
	Message string `json:"message"` // legível, em português
}

func (e *APIError) Error() string { return e.Code + ": " + e.Message }

func NewError(status int, code, message string) *APIError {
	return &APIError{Status: status, Code: code, Message: message}
}

// WriteJSON escreve um corpo JSON com o status indicado.
func WriteJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	if v != nil {
		json.NewEncoder(w).Encode(v)
	}
}

// WriteError converte um erro em resposta. Erros APIError saem como estão;
// qualquer outro é um defeito nosso: registramos o detalhe no log e devolvemos
// uma mensagem genérica (nunca vazamos texto interno ao cliente).
func WriteError(w http.ResponseWriter, r *http.Request, err error) {
	var apiErr *APIError
	if errors.As(err, &apiErr) {
		WriteJSON(w, apiErr.Status, map[string]any{"error": apiErr})
		return
	}
	slog.Error("erro interno", "method", r.Method, "path", r.URL.Path, "err", err)
	WriteJSON(w, http.StatusInternalServerError, map[string]any{
		"error": NewError(http.StatusInternalServerError, "internal_error", "Erro interno. Tente novamente."),
	})
}

// ReadJSON lê um corpo JSON pequeno (até 1 MiB) para dst.
func ReadJSON(w http.ResponseWriter, r *http.Request, dst any) error {
	r.Body = http.MaxBytesReader(w, r.Body, 1<<20)
	dec := json.NewDecoder(r.Body)
	if err := dec.Decode(dst); err != nil {
		var tooBig *http.MaxBytesError
		if errors.As(err, &tooBig) {
			return NewError(http.StatusRequestEntityTooLarge, "request_too_large", "Corpo da requisição grande demais.")
		}
		return NewError(http.StatusBadRequest, "invalid_json", "Corpo da requisição não é um JSON válido.")
	}
	return nil
}
