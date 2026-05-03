-- 20260503 — add searchable_text column for canonical embedding-doc text.
--
-- Rationale: the embedding vector is stored on each row, but the document
-- TEXT that produced it is not. Persisting it lets future re-embedders
-- (paper reproducibility, alternative models like LaBSE / multilingual-e5)
-- use the same input and get comparable vectors. Also makes Postgres
-- full-text search a viable secondary retriever.
--
-- Apply via Supabase Dashboard → SQL Editor.

ALTER TABLE public.entries
    ADD COLUMN IF NOT EXISTS searchable_text TEXT;

-- Optional: a tsvector + GIN index for fuzzy/phrase matching on the new
-- column. Arabic config falls back to 'simple' since Postgres doesn't
-- ship a stemmer for Arabic; we get tokenisation but no stemming.
CREATE INDEX IF NOT EXISTS entries_searchable_tsv_idx
    ON public.entries
    USING GIN (to_tsvector('simple', coalesce(searchable_text, '')));

-- Optional: track the embedding-doc layout version that produced
-- ``searchable_text`` so we can regenerate selectively.
ALTER TABLE public.entries
    ADD COLUMN IF NOT EXISTS searchable_text_version TEXT;
