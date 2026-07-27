"""Round-robin Gemini key rotator for batch jobs that hit free-tier limits.

Reads ``GEMINI_API_KEY``, ``GEMINI_API_KEY1``, ``GEMINI_API_KEY2``,
``GEMINI_API_KEY3`` from the environment and rotates through them on each
call. When the underlying ``gemini_generate`` returns a "quota" / "rate
limit" sentinel, the rotator advances to the next key and retries — so a
batch job effectively gets ``len(keys) × free_tier_quota`` headroom.

Used by ``scripts/validate_pos.py`` and other one-shot batch scripts.
**Not** wired into the runtime ``/chat`` path — that path uses a single
key per request via ``app.rag.config.gemini_api_key``.
"""

from __future__ import annotations

import os
import sys
import time
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO_ROOT / "backend"))

from app.rag.generation import (  # noqa: E402
    GEMINI_UNAVAILABLE_PREFIX,
    gemini_generate,
)


import re as _re

# Any env var matching ``GEMINI_API_KEY`` or ``GEMINI_API_KEY<digits>`` is
# picked up automatically. Adding more keys to ``backend/.env`` requires
# no code change — just bounce the consuming script.
_ENV_PATTERN = _re.compile(r"^GEMINI_API_KEY(\d+)?$")


def _discover_env_names() -> tuple[str, ...]:
    """Return env var names sorted by numeric suffix (unsuffixed first)."""
    names: list[tuple[int, str]] = []
    for name in os.environ:
        m = _ENV_PATTERN.match(name)
        if not m:
            continue
        suffix = m.group(1)
        names.append((int(suffix) if suffix else -1, name))
    return tuple(n for _, n in sorted(names))
_QUOTA_HINTS = ("quota", "rate limit", "resourceexhausted", "exceeded")
_DEAD_HINTS = (
    "permissiondenied",
    "reported as leaked",
    "api_key_invalid",
    "invalid api key",
    "permission_denied",
)


def load_keys() -> list[str]:
    """Return non-empty, deduplicated keys from the env, preserving order."""
    seen: set[str] = set()
    out: list[str] = []
    for name in _discover_env_names():
        v = (os.getenv(name) or "").strip()
        if v and v not in seen:
            seen.add(v)
            out.append(v)
    return out


class KeyRotator:
    """Round-robin key picker with a tiny per-key cool-down on quota errors."""

    def __init__(self, keys: list[str] | None = None, cooldown_s: float = 30.0) -> None:
        self.keys = keys if keys is not None else load_keys()
        if not self.keys:
            raise RuntimeError("No GEMINI_API_KEY* values present in env.")
        self._idx = 0
        self._cool_until: dict[int, float] = {}
        self._dead: set[int] = set()  # permanently dead-listed (leaked / invalid)
        self._cooldown = cooldown_s

    @property
    def n(self) -> int:
        return len(self.keys)

    def _is_cool(self, i: int) -> bool:
        if i in self._dead:
            return False
        until = self._cool_until.get(i, 0.0)
        return time.time() >= until

    def _next_index(self) -> int | None:
        for _ in range(self.n):
            i = self._idx
            self._idx = (self._idx + 1) % self.n
            if self._is_cool(i):
                return i
        return None  # all keys cooling or dead

    def call(
        self,
        prompt: str,
        *,
        generation_config: Any | None = None,
        system_instruction: str | None = None,
        max_wait_s: float = 180.0,
    ) -> str:
        """Try every key; cool down on quota/rate-limit; wait up to ``max_wait_s``
        for a key to become available before giving up.

        Returns the first successful response, or the last failure string
        prefixed with ``GEMINI_UNAVAILABLE_PREFIX`` if everything was
        rate-limited for the full ``max_wait_s`` window.
        """
        last_err: str = f"{GEMINI_UNAVAILABLE_PREFIX} no keys tried"
        deadline = time.time() + max_wait_s
        while time.time() < deadline:
            i = self._next_index()
            if i is None:
                # All keys cooling — wait until the soonest one is ready.
                if all(idx in self._dead for idx in range(self.n)):
                    return f"{GEMINI_UNAVAILABLE_PREFIX} all keys dead-listed"
                next_ready = min(
                    (t for idx, t in self._cool_until.items() if idx not in self._dead),
                    default=time.time() + 5.0,
                )
                wait = max(1.0, min(next_ready - time.time(), 15.0))
                time.sleep(wait)
                continue
            reply = gemini_generate(
                prompt,
                self.keys[i],
                generation_config=generation_config,
                system_instruction=system_instruction,
            )
            if not reply.startswith(GEMINI_UNAVAILABLE_PREFIX):
                return reply
            last_err = reply
            lower = reply.lower()
            if any(h in lower for h in _DEAD_HINTS):
                self._dead.add(i)
                continue
            if any(h in lower for h in _QUOTA_HINTS):
                self._cool_until[i] = time.time() + self._cooldown
                continue
            # Other transient failure — try the next key.
            continue
        return last_err


_default: KeyRotator | None = None


def call(
    prompt: str,
    *,
    generation_config: Any | None = None,
    system_instruction: str | None = None,
) -> str:
    """Module-level convenience wrapper using a single shared rotator."""
    global _default
    if _default is None:
        _default = KeyRotator()
    return _default.call(
        prompt,
        generation_config=generation_config,
        system_instruction=system_instruction,
    )
