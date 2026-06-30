-- arxiv-sanity-preserver: Postgres schema for the social-feature tables
-- (migrated off MongoDB in Phase 0 step 5). Apply to a dedicated database
-- (default: `arxiv_sanity`) on the link-kb Postgres instance:
--
--   psql "$ARXIV_DATABASE_URL" -f schema-postgres.sql
--
-- SQLite still owns `user` + `library` (see schema.sql); that consolidation
-- is Phase 1. The pickle artifacts (`tfidf.p`, `sim_dict.p`, etc.) also
-- still live on disk; pgvector migration is also Phase 1.

CREATE TABLE IF NOT EXISTS comments (
  id          BIGSERIAL PRIMARY KEY,
  username    TEXT NOT NULL,
  pid         TEXT NOT NULL,
  version     INT  NOT NULL,
  conf        TEXT,
  anon        BOOLEAN NOT NULL DEFAULT FALSE,
  time_posted DOUBLE PRECISION NOT NULL,    -- unix seconds (preserves 2021 wire format)
  text        TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_comments_pid  ON comments (pid);
CREATE INDEX IF NOT EXISTS idx_comments_time ON comments (time_posted DESC);

CREATE TABLE IF NOT EXISTS tags (
  id           BIGSERIAL PRIMARY KEY,
  username     TEXT NOT NULL,
  pid          TEXT NOT NULL,
  comment_id   BIGINT NOT NULL REFERENCES comments(id) ON DELETE CASCADE,
  tag_name     TEXT NOT NULL,
  time_toggled DOUBLE PRECISION NOT NULL,
  UNIQUE (username, comment_id, tag_name)
);
CREATE INDEX IF NOT EXISTS idx_tags_comment_tag ON tags (comment_id, tag_name);

-- Twitter mentions of papers (written by twitter_daemon.py). `time_window` collapses
-- the three Mongo collections (tweets_top1/7/30) into one table.
CREATE TABLE IF NOT EXISTS tweets_top (
  id          BIGSERIAL PRIMARY KEY,
  time_window      TEXT NOT NULL CHECK (time_window IN ('day', 'week', 'month')),
  pid         TEXT NOT NULL,
  vote        DOUBLE PRECISION NOT NULL,
  data        JSONB NOT NULL DEFAULT '{}'   -- everything else from the daemon
);
CREATE INDEX IF NOT EXISTS idx_tweets_top_time_window_vote ON tweets_top (time_window, vote DESC);

CREATE TABLE IF NOT EXISTS follow (
  who           TEXT NOT NULL,
  whom          TEXT NOT NULL,
  active        BOOLEAN NOT NULL DEFAULT FALSE,
  time_request  DOUBLE PRECISION NOT NULL,
  PRIMARY KEY (who, whom)
);
CREATE INDEX IF NOT EXISTS idx_follow_whom ON follow (whom);

CREATE TABLE IF NOT EXISTS goaway (
  uid          TEXT PRIMARY KEY,
  time_posted  DOUBLE PRECISION NOT NULL
);
