CREATE TABLE groups (
    id         TEXT PRIMARY KEY,
    name       TEXT NOT NULL,
    created_by TEXT NOT NULL REFERENCES users(id),
    created_at INTEGER NOT NULL
);

-- user_id é a CHAVE PRIMÁRIA: o próprio banco garante "uma roda por pessoa".
CREATE TABLE group_members (
    user_id   TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    group_id  TEXT NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
    role      TEXT NOT NULL CHECK (role IN ('owner', 'member')),
    joined_at INTEGER NOT NULL
);
CREATE INDEX group_members_group_idx ON group_members(group_id);

-- Convite de roda: código de uso único; só o hash é guardado.
CREATE TABLE group_invites (
    id         TEXT PRIMARY KEY,
    group_id   TEXT NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
    code_hash  TEXT NOT NULL UNIQUE,
    created_by TEXT NOT NULL REFERENCES users(id),
    created_at INTEGER NOT NULL,
    expires_at INTEGER NOT NULL,
    used_by    TEXT REFERENCES users(id),
    used_at    INTEGER
);
