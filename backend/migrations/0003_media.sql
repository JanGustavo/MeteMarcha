-- Fotos enviadas. O nome do arquivo no disco é aleatório (nunca vem do cliente).
-- delete_attempts / next_attempt_at / last_error permitem à limpeza repetir
-- exclusões que falharam, mesmo depois de reiniciar o programa.
CREATE TABLE media_files (
    id              TEXT PRIMARY KEY,
    owner_id        TEXT NOT NULL REFERENCES users(id),
    file_name       TEXT NOT NULL UNIQUE,
    content_type    TEXT NOT NULL,
    size_bytes      INTEGER NOT NULL,
    created_at      INTEGER NOT NULL,
    delete_attempts INTEGER NOT NULL DEFAULT 0,
    next_attempt_at INTEGER NOT NULL DEFAULT 0,
    last_error      TEXT
);

-- Catálogo de músicas (compartilhado). Sincronizado a partir de catalog.json
-- na inicialização. Faixas removidas do JSON ficam com active = 0, porque
-- stories antigos ainda podem referenciá-las. A limpeza nunca toca nesta tabela.
CREATE TABLE tracks (
    id           TEXT PRIMARY KEY,
    title        TEXT NOT NULL,
    artist       TEXT NOT NULL,
    file_name    TEXT NOT NULL,
    content_type TEXT NOT NULL,
    duration_ms  INTEGER NOT NULL,
    license_note TEXT NOT NULL,
    active       INTEGER NOT NULL DEFAULT 1
);
