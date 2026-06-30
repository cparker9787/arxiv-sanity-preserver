"""Smoke tests: each non-Twitter module must import cleanly.

These are intentionally cheap — they catch the dominant failure mode for a
modernization (broken imports from API changes) without needing any of the
runtime artifacts the pipeline produces (db.p, MongoDB, etc.).

Excluded: twitter_daemon (python-twitter is unmaintained; out of Phase 0 scope).
"""

import importlib
import os
import sys
import pytest

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
sys.path.insert(0, REPO_ROOT)

# Order matters slightly: utils first (everyone imports it), then leaves.
MODULES = [
    "utils",
    "analyze",
    "buildsvm",
    "download_pdfs",
    "fetch_papers",
    "make_cache",
    "parse_pdf_to_text",
    "thumb_pdf",
    "serve",
]


@pytest.mark.parametrize("mod", MODULES)
def test_module_imports(mod):
    """Importing each pipeline/app module must not raise."""
    importlib.import_module(mod)


def test_utils_helpers():
    """utils' pure helpers behave as documented (no I/O)."""
    from utils import strip_version, isvalidid

    assert strip_version("1511.08198v1") == "1511.08198"
    assert strip_version("1511.08198") == "1511.08198"
    assert isvalidid("1511.08198v1")
    assert isvalidid("1511.08198")
    assert not isvalidid("not-an-arxiv-id")
