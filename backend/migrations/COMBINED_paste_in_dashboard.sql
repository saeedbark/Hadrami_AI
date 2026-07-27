-- ============================================================
-- Hadrami AI — combined v2 schema migrations (2026-05-03)
-- ============================================================
-- Open: https://supabase.com/dashboard/project/notmkrzxycbtipdrnhpj/sql/new
-- Paste this entire file and click "Run".
-- All statements are idempotent (use IF NOT EXISTS) so re-running is safe.
-- ============================================================

-- 1) Canonical embedding-doc text + version (paper reproducibility +
--    secondary FTS retriever).
ALTER TABLE public.entries
    ADD COLUMN IF NOT EXISTS searchable_text TEXT;

ALTER TABLE public.entries
    ADD COLUMN IF NOT EXISTS searchable_text_version TEXT;

CREATE INDEX IF NOT EXISTS entries_searchable_tsv_idx
    ON public.entries
    USING GIN (to_tsvector('simple', coalesce(searchable_text, '')));

-- 2) Coarse semantic intent class for filtering / browsing
--    (action, object, person, emotion, place, time, descriptor,
--     expression, function).
ALTER TABLE public.entries
    ADD COLUMN IF NOT EXISTS semantic_intent TEXT;

CREATE INDEX IF NOT EXISTS entries_semantic_intent_idx
    ON public.entries (semantic_intent);

-- 3) Latin-script transliteration of the headword (accessibility for
--    non-Arabic-speaking dataset users).
ALTER TABLE public.entries
    ADD COLUMN IF NOT EXISTS transliteration TEXT;

CREATE INDEX IF NOT EXISTS entries_transliteration_idx
    ON public.entries (transliteration);

-- 4) Sanity check the schema looks right after running.
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'entries'
  AND column_name IN ('searchable_text', 'searchable_text_version',
                       'semantic_intent', 'transliteratx§ion')
ORDER BY column_name;
