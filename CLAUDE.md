# CLAUDE.md — arxiv-sanity-preserver

> Fork of [karpathy/arxiv-sanity-preserver](https://github.com/karpathy/arxiv-sanity-preserver) (original last touched 2021-11-27). `upstream` remote points at karpathy; `origin` is `cparker9787/arxiv-sanity-preserver`.

## What this is

A personalized arXiv paper recommender. Pipeline:

```
fetch_papers.py       arXiv API -> db.p (pickle of paper metadata)
download_pdfs.py      db.p -> data/pdf/*.pdf
parse_pdf_to_text.py  pdfs -> data/txt/*.txt
analyze.py            txts -> tfidf.p (sparse tf-idf matrix) + tfidf_meta.p + sim_dict.p (precomputed top-K NN)
buildsvm.py           per-user library -> user_sim.p (SVM-ranked recs)
make_cache.py         -> serve_cache.p (date-sorted/top-sorted/search index)
twitter_daemon.py     scrapes paper mentions -> mongodb
serve.py              Flask app: SQLite (users/library) + MongoDB (comments/tweets) + pickles (papers/sim)
```

External dependencies the code assumes:
- **MongoDB** (`serve.py`: comments, tags, follow, goaway, tweets_top1/7/30)
- **SQLite** (`as.db` from `schema.sql`: users, library)
- Several **pickle files** produced by the data pipeline before `serve.py` is useful
- `python-twitter` package + Twitter API creds (only for `twitter_daemon.py`)

## Modernization (Phase 0 — this branch: `phase0-modernize`)

Goal: bring the codebase from 2021/Python 3.7-ish to Python 3.11+ on modern dep versions, without changing functionality. Subsequent phases (out of scope here) would containerize, add real tests, and optionally integrate into a larger system.

### Known 2021 → 2026 API breaks

All in `serve.py`. Fixed in this commit:

| Symptom | Root cause | Fix |
|---|---|---|
| `ImportError: cannot import name 'check_password_hash' from 'werkzeug'` | Werkzeug 3.x moved security helpers | `from werkzeug.security import check_password_hash, generate_password_hash` |
| `TypeError: Limiter.__init__() got an unexpected keyword argument 'global_limits'` | flask-limiter 2.x+ rewrote init API | `Limiter(get_remote_address, app=app, default_limits=[...])` |
| `AttributeError: 'Collection' object has no attribute 'count'` | pymongo 4.x removed `Collection.count()` | `Collection.count_documents({...})` or `estimated_document_count()` for unfiltered counts |

### Out of scope for Phase 0 (left as-is, flagged for later)

- `python-twitter` is unmaintained; `twitter_daemon.py` will fail on first run. Will be replaced with `tweepy` or wired to an X MCP bridge in Phase 2.
- The data pipeline still writes/reads pickle files. A 2026 version would use a real DB + pgvector; that's the link-kb sister project, not this fork.
- `serve.py` still expects local MongoDB on default host/port. Containerized phase will add `docker-compose.yml`.

## Repo conventions

- **Phase 0 = `phase0-modernize` branch** (this one). Merge to `master` only after smoke tests pass.
- Keep `master` synced with `upstream/master` so we can rebase if karpathy ever updates.
- Don't add new app features in `phase0-modernize` — only modernization. New features go in feature branches off `master` (after merging).

## Running locally (post-modernization, future)

(Not yet executable end-to-end — pipeline + MongoDB are not stood up.)

```bash
python3.11 -m venv .venv && . .venv/bin/activate
pip install -r requirements.txt
# Pipeline (each step writes pickles read by the next):
python fetch_papers.py
python download_pdfs.py
python parse_pdf_to_text.py
python analyze.py
python make_cache.py
# Then (needs MongoDB on localhost:27017):
sqlite3 as.db < schema.sql
python serve.py
```
