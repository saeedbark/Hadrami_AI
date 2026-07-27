-- 20260503 — add semantic_intent + transliteration columns to entries.
--
-- Rationale:
--   * `semantic_intent` is a single-label classification of what the entry
--     refers to at the semantic level (action, object, person, emotion,
--     place, time, descriptor, expression, function). Useful as a
--     filterable axis alongside `pos`, `tags`, and `region` — and gives
--     downstream users a coarse semantic class without parsing the Arabic
--     definition.
--   * `transliteration` is a Latin-script form of `word_vocalized`. Most
--     non-Arabic-speaking researchers loading this dataset cannot search
--     for an Arabic surface form; a transliteration column is the single
--     biggest accessibility lever.
--
-- Apply via Supabase Dashboard → SQL Editor.

ALTER TABLE public.entries
    ADD COLUMN IF NOT EXISTS semantic_intent TEXT;

ALTER TABLE public.entries
    ADD COLUMN IF NOT EXISTS transliteration TEXT;

-- Helpful indices for filtering / search.
CREATE INDEX IF NOT EXISTS entries_semantic_intent_idx
    ON public.entries (semantic_intent);

CREATE INDEX IF NOT EXISTS entries_transliteration_idx
    ON public.entries (transliteration);
