package app

import (
	"bytes"
	"encoding/binary"
	"encoding/json"
	"mime/multipart"
	"net/http"
	"os/exec"
	"testing"
)

func waveAudio() []byte {
	var b bytes.Buffer
	b.WriteString("RIFF")
	binary.Write(&b, binary.LittleEndian, uint32(36+16000))
	b.WriteString("WAVEfmt ")
	binary.Write(&b, binary.LittleEndian, uint32(16))
	for _, v := range []uint16{1, 1} {
		binary.Write(&b, binary.LittleEndian, v)
	}
	binary.Write(&b, binary.LittleEndian, uint32(8000))
	binary.Write(&b, binary.LittleEndian, uint32(16000))
	binary.Write(&b, binary.LittleEndian, uint16(2))
	binary.Write(&b, binary.LittleEndian, uint16(16))
	b.WriteString("data")
	binary.Write(&b, binary.LittleEndian, uint32(16000))
	b.Write(make([]byte, 16000))
	return b.Bytes()
}
func (e *env) uploadAudio(token, license string, audio []byte) (int, map[string]any) {
	var body bytes.Buffer
	mw := multipart.NewWriter(&body)
	mw.WriteField("title", "Áudio aberto")
	mw.WriteField("license", license)
	part, _ := mw.CreateFormFile("audio", "audio.wav")
	part.Write(audio)
	mw.Close()
	req, _ := http.NewRequest("POST", e.srv.URL+"/v1/tracks/upload", &body)
	req.Header.Set("Content-Type", mw.FormDataContentType())
	req.Header.Set("Authorization", "Bearer "+token)
	response, err := http.DefaultClient.Do(req)
	if err != nil {
		e.t.Fatal(err)
	}
	defer response.Body.Close()
	var data map[string]any
	json.NewDecoder(response.Body).Decode(&data)
	return response.StatusCode, data
}
func TestPrivateAudioUpload(t *testing.T) {
	if _, err := exec.LookPath("ffprobe"); err != nil {
		t.Skip("ffprobe required for audio validation")
	}
	e := newEnv(t)
	owner, member, other := e.register("audioowner"), e.register("audiomember"), e.register("audioother")
	e.newGroup("Audio", owner, member)
	e.newGroup("Other", other)
	if status, _ := e.uploadAudio(owner.token, "", waveAudio()); status != 422 {
		t.Fatalf("license: %d", status)
	}
	if status, _ := e.uploadAudio(owner.token, "open-or-owned", []byte("not audio")); status != 422 {
		t.Fatalf("invalid: %d", status)
	}
	status, body := e.uploadAudio(owner.token, "open-or-owned", waveAudio())
	if status != 201 {
		t.Fatalf("upload: %d %v", status, body)
	}
	id := str(body, "track", "id")
	if status, _, _ := e.getBytes("/v1/tracks/"+id+"/audio", other.token); status != 404 {
		t.Fatalf("other reads audio: %d", status)
	}
	fields := map[string]string{"track_id": id, "track_duration_ms": "1000"}
	if status, _, _ := e.publish(member.token, keyN("foreignaudio", 1), fields, jpegBytes(20, 20)); status != 422 {
		t.Fatalf("member reused private audio: %d", status)
	}
	if status, _, body := e.publish(owner.token, keyN("ownaudio", 1), fields, jpegBytes(20, 20)); status != 201 {
		t.Fatalf("publish: %d %v", status, body)
	}
	if status, _, _ := e.getBytes("/v1/tracks/"+id+"/audio", member.token); status != 200 {
		t.Fatalf("member cannot hear story: %d", status)
	}
	if status, _ := e.uploadAudio(owner.token, "open-or-owned", waveAudio()); status != 201 {
		t.Fatalf("retry: %d", status)
	}
	if n := e.count(`SELECT COUNT(*) FROM tracks WHERE owner_id=?`, owner.id); n != 1 {
		t.Fatalf("duplicate personal audio: %d", n)
	}
}
