create extension if not exists pg_trgm;

alter table public.entries
    add column if not exists aliases text[] not null default '{}'::text[],
    add column if not exists embedding_dirty boolean not null default true,
    add column if not exists updated_at timestamptz not null default timezone('utc', now());

create or replace function public.normalize_hadrami_search_text(input_text text)
returns text
language sql
immutable
as $$
    select trim(
        translate(
            coalesce(input_text, ''),
            'أإآٱ',
            'اااا'
        )
    );
$$;

create or replace function public.entries_prepare_for_search()
returns trigger
language plpgsql
as $$
begin
    new.search_key := public.normalize_hadrami_search_text(coalesce(new.search_key, new.hadrami_word));
    new.aliases := coalesce(new.aliases, '{}'::text[]);
    new.updated_at := timezone('utc', now());

    if tg_op = 'INSERT' then
        new.embedding_dirty := new.embedding is null;
        return new;
    end if;

    if coalesce(new.hadrami_word, '') is distinct from coalesce(old.hadrami_word, '')
       or coalesce(new.search_key, '') is distinct from coalesce(old.search_key, '')
       or coalesce(new.arabic_fus7a, '') is distinct from coalesce(old.arabic_fus7a, '')
       or coalesce(new.full_definition, '') is distinct from coalesce(old.full_definition, '')
       or coalesce(new.cultural_note, '') is distinct from coalesce(old.cultural_note, '')
       or coalesce(new.examples, 'null'::jsonb) is distinct from coalesce(old.examples, 'null'::jsonb)
       or coalesce(new.aliases, '{}'::text[]) is distinct from coalesce(old.aliases, '{}'::text[]) then
        new.embedding := null;
        new.embedding_dirty := true;
    end if;

    return new;
end;
$$;

drop trigger if exists trg_entries_prepare_for_search on public.entries;
create trigger trg_entries_prepare_for_search
before insert or update on public.entries
for each row execute function public.entries_prepare_for_search();

update public.entries
set aliases = coalesce(aliases, '{}'::text[]),
    search_key = public.normalize_hadrami_search_text(coalesce(search_key, hadrami_word)),
    embedding_dirty = (embedding is null),
    updated_at = timezone('utc', now())
where true;

create index if not exists entries_hadrami_word_trgm_idx
    on public.entries using gin (hadrami_word gin_trgm_ops);

create index if not exists entries_search_key_trgm_idx
    on public.entries using gin (search_key gin_trgm_ops);

create index if not exists entries_arabic_fus7a_trgm_idx
    on public.entries using gin (arabic_fus7a gin_trgm_ops);

create index if not exists entries_full_definition_trgm_idx
    on public.entries using gin (full_definition gin_trgm_ops);

create index if not exists entries_aliases_gin_idx
    on public.entries using gin (aliases);

create or replace function public.search_entries_expanded(query_text text, match_count integer default 8)
returns table (
    id integer,
    hadrami_word text,
    search_key text,
    arabic_fus7a text,
    full_definition text,
    cultural_note text,
    part_of_speech text,
    thematic_category text,
    is_archaic boolean,
    proverb_record jsonb,
    examples jsonb,
    aliases text[],
    match_score integer
)
language sql
stable
as $$
with cleaned as (
    select
        trim(coalesce(query_text, '')) as raw_q,
        regexp_replace(
            trim(coalesce(query_text, '')),
            '(ما\s*معنى|مامعنى|ما\s*هو\s*معنى|وش\s*يعني|يعني\s*ايش|ايش\s*يعني|معنى\s*كلمة|^كلمة\s*)',
            ' ',
            'gi'
        ) as stripped_q
),
candidates as (
    select raw_q as cand from cleaned
    union
    select trim(token) as cand
    from cleaned, regexp_split_to_table(stripped_q, '[\s،,.;:!؟?]+') as token
    where char_length(trim(token)) >= 2
    union
    select substring(trim(token) from 3) as cand
    from cleaned, regexp_split_to_table(stripped_q, '[\s،,.;:!؟?]+') as token
    where trim(token) like 'ال%' and char_length(trim(token)) > 3
),
uniq_candidates as (
    select distinct cand, public.normalize_hadrami_search_text(cand) as norm_cand
    from candidates
    where cand <> ''
),
scored as (
    select
        e.id,
        e.hadrami_word,
        e.search_key,
        e.arabic_fus7a,
        e.full_definition,
        e.cultural_note,
        e.part_of_speech,
        e.thematic_category,
        e.is_archaic,
        e.proverb_record,
        e.examples,
        e.aliases,
        max(
            case
                when e.hadrami_word = c.cand
                  or coalesce(e.search_key, '') = c.norm_cand
                  or c.cand = any(coalesce(e.aliases, '{}'::text[]))
                    then 100
                when e.hadrami_word ilike '%' || c.cand || '%'
                  or coalesce(e.search_key, '') ilike '%' || c.norm_cand || '%'
                  or exists (
                        select 1
                        from unnest(coalesce(e.aliases, '{}'::text[])) as alias
                        where alias ilike '%' || c.cand || '%'
                    )
                    then 80
                when e.hadrami_word <> '' and c.cand ilike '%' || e.hadrami_word || '%'
                    then 70
                when coalesce(e.arabic_fus7a, '') ilike '%' || c.cand || '%'
                    then 60
                when coalesce(e.full_definition, '') ilike '%' || c.cand || '%'
                    then 40
                else 0
            end
        )::integer as match_score
    from public.entries e
    cross join uniq_candidates c
    where e.hadrami_word ilike '%' || c.cand || '%'
       or coalesce(e.search_key, '') ilike '%' || c.norm_cand || '%'
       or coalesce(e.arabic_fus7a, '') ilike '%' || c.cand || '%'
       or coalesce(e.full_definition, '') ilike '%' || c.cand || '%'
       or exists (
            select 1
            from unnest(coalesce(e.aliases, '{}'::text[])) as alias
            where alias ilike '%' || c.cand || '%'
       )
    group by
        e.id,
        e.hadrami_word,
        e.search_key,
        e.arabic_fus7a,
        e.full_definition,
        e.cultural_note,
        e.part_of_speech,
        e.thematic_category,
        e.is_archaic,
        e.proverb_record,
        e.examples,
        e.aliases
)
select
    id,
    hadrami_word,
    search_key,
    arabic_fus7a,
    full_definition,
    cultural_note,
    part_of_speech,
    thematic_category,
    is_archaic,
    proverb_record,
    examples,
    aliases,
    match_score
from scored
where match_score > 0
order by match_score desc, char_length(hadrami_word) asc, id asc
limit greatest(match_count, 1);
$$;
