"""Some pipeline scripts call sys.exit / os.system / read files at import time
(2021-era patterns). conftest gives us a stable cwd so tests run identically
regardless of pytest invocation directory."""

import os
import pytest

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))


@pytest.fixture(autouse=True)
def chdir_repo_root(monkeypatch):
    monkeypatch.chdir(REPO_ROOT)
