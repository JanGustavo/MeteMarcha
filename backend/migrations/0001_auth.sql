-- Datas são guardadas como segundos Unix (INTEGER, UTC): fáceis de comparar e somar.

CREATE TABLE users (
    id            TEXT PRIMARY KEY,
    email         TEXT NOT NULL UNIQUE COLLATE NOCASE,
    display_name  TEXT NOT NULL,
    password_hash TEXT NOT NULL,          -- argon2id, nunca a senha
    created_at    INTEGER NOT NULL
);

-- Sessões revogáveis: o token puro só existe no celular; aqui fica o hash dele.
CREATE TABLE sessions (
    id         TEXT PRIMARY KEY,
    user_id    TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash TEXT NOT NULL UNIQUE,
    created_at INTEGER NOT NULL,
    expires_at INTEGER NOT NULL,
    revoked_at INTEGER                    -- NULL = ativa
);
CREATE INDEX sessions_user_idx ON sessions(user_id);
