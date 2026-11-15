CREATE TABLE stories (
    seq               INTEGER PRIMARY KEY AUTOINCREMENT,   -- ordem de publicação (cursor do feed)
    id                TEXT NOT NULL UNIQUE,                -- id público, aleatório
    author_id         TEXT NOT NULL REFERENCES users(id),
    group_id          TEXT NOT NULL REFERENCES groups(id),
    photo_media_id    TEXT NOT NULL UNIQUE REFERENCES media_files(id),
    caption           TEXT NOT NULL DEFAULT '',
    track_id          TEXT REFERENCES tracks(id),
    track_start_ms    INTEGER,
    track_duration_ms INTEGER,
    client_request_id TEXT NOT NULL,                       -- Idempotency-Key enviada pelo celular
    created_at        INTEGER NOT NULL,
    -- Repetir a mesma publicação (mesmo autor + mesma chave) viola esta restrição:
    -- é assim que o banco impede posts duplicados, mesmo com requisições simultâneas.
    UNIQUE (author_id, client_request_id),
    CHECK (
        (track_id IS NULL AND track_start_ms IS NULL AND track_duration_ms IS NULL) OR
        (track_id IS NOT NULL AND track_start_ms IS NOT NULL AND track_duration_ms IS NOT NULL)
    )
);
CREATE INDEX stories_feed_idx ON stories(group_id, seq DESC);
CREATE INDEX stories_created_idx ON stories(created_at);

-- Uma reação por pessoa por story (a chave primária impõe o limite).
CREATE TABLE reactions (
    story_id   TEXT NOT NULL REFERENCES stories(id) ON DELETE CASCADE,
    user_id    TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    kind       TEXT NOT NULL CHECK (kind IN ('fire', 'muscle', 'clap', 'heart')),
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    PRIMARY KEY (story_id, user_id)
);
