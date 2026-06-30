# arxiv-sanity-preserver — Phase 0 container.
# Build: docker build -t arxiv-sanity .
# Run via docker-compose (see docker-compose.yml) — needs Mongo on the network.
FROM python:3.11-slim

# System binaries the pipeline shells out to (parse_pdf_to_text, thumb_pdf).
# poppler-utils provides pdftotext; imagemagick provides montage/convert.
# NOTE: imagemagick's default policy.xml blocks PDF processing on Debian (CVE-2016-3714
# era hardening). thumb_pdf.py will appear to "succeed" but emit empty thumbnails until
# /etc/ImageMagick-*/policy.xml is loosened — out of Phase 0 scope; documented in CLAUDE.md.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        poppler-utils \
        imagemagick \
        sqlite3 \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy app code (.dockerignore filters .venv, .git, data/, etc.)
COPY . .

EXPOSE 5000

# Default = run the web server. Pipeline steps are invoked explicitly:
#   docker compose run --rm app python fetch_papers.py
#   docker compose run --rm app python analyze.py
#   docker compose run --rm app python make_cache.py
CMD ["python", "serve.py", "--port", "5000"]
