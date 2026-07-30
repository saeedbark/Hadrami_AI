Hadrami Database Reset & Full-Stack Refactor

Current State Analysis





Supabase DB: Essentially empty. Only a test table saeed exists. No entries table, no pgvector functions.



JSON dataset (hadrami_dataset.json): Completely restructured with new field names (see mapping below).



Backend/Flutter code: Still references the old field names -- every layer needs updating.

Field Mapping (Old -> New)







Old DB/Code Field



New JSON Field



Type





hadrami_word



word_vocalized



text





search_key



word_clean



text





arabic_fus7a



fusha_equivalent



text





full_definition



definition



text





part_of_speech



pos



text





thematic_category



(removed, replaced by tags)



-





is_archaic



(removed)



-





cultural_note



note



text





proverb_record



proverbs



jsonb





aliases



synonyms



jsonb





fus7a_short



(removed)



-





pronunciation_notes



phonetic_variants



jsonb





examples[].hadrami



examples[].h



-





examples[].fusha



examples[].f



-





(new)



root



text





(new)



region



text





(new)



source



text





(new)



tags



jsonb (string array)



Step 1: Database & Schema Setup (Supabase MCP)

1a. Clean up and enable extensions





Drop the test table saeed



Enable vector extension (pgvector) if not already enabled

1b. Create the entries table

CREATE TABLE public.entries (
  id            BIGINT PRIMARY KEY,
  word_vocalized TEXT NOT NULL,
  word_clean    TEXT,
  root          TEXT,
  pos           TEXT,
  fusha_equivalent TEXT,
  definition    TEXT,
  region        TEXT DEFAULT 'General',
  synonyms      JSONB DEFAULT '[]',
  phonetic_variants JSONB DEFAULT '[]',
  note          TEXT DEFAULT '',
  source        TEXT DEFAULT '',
  examples      JSONB DEFAULT '[]',
  proverbs      JSONB DEFAULT '[]',
  tags          JSONB DEFAULT '[]',
  embedding     vector(768),
  embedding_dirty BOOLEAN DEFAULT TRUE,
  created_at    TIMESTAMPTZ DEFAULT now()
);

1c. Create indexes





GIN index on synonyms, tags for fast JSONB containment queries



btree index on word_clean, pos, region



IVFFlat or HNSW index on embedding for vector search

1d. Create match_entries pgvector RPC function





Accepts query_embedding vector(768), match_threshold float, match_count int



Returns entries ranked by cosine similarity, including a similarity score



Must return ALL new columns (not the old ones)

1e. Create search_entries_expanded keyword RPC function





Tokenizes the input query, searches across word_vocalized, word_clean, fusha_equivalent, definition



Returns entries with a match_score

1f. Configure RLS





Enable RLS on entries



Add a policy for SELECT using the anon key (public read)



Add a policy for INSERT/UPDATE using the service-role key

1g. Environment variables





Update backend/.env.example to include all required vars



User must create backend/.env with:





SUPABASE_URL=https://your-project-ref.supabase.co



SUPABASE_SERVICE_KEY=<service-role key from Supabase dashboard>



GEMINI_API_KEY=<your Gemini API key>



Step 2: Backend Refactoring (FastAPI)

2a. Update Pydantic models (backend/app/schemas.py)





Rename Entry fields to match new DB columns: word_vocalized, word_clean, root, pos, fusha_equivalent, definition, region, synonyms, phonetic_variants, note, source, proverbs, tags



Remove: fus7a_short, is_archaic, thematic_category, search_key, hadrami_word, arabic_fus7a, full_definition, cultural_note, aliases, pronunciation_notes, proverb_record



Update ExamplePair to use h and f fields



Update TranslateResponse, FeedbackRequest, and all response models accordingly



Add new ChatMessage and ChatRequest/ChatResponse models for the chat feature

2b. Update data store (backend/app/core/data_store.py)





Update _SELECT_COLS to reference new column names



Update all query helpers: fetch_all, fetch_by_id, text_search, rpc_match_entries



Update text_search to search across word_vocalized, word_clean, fusha_equivalent, definition

2c. Update dictionary service (backend/app/services/dictionary_service.py)





Update all field references from old to new names throughout



Update _entry_match_score to use word_vocalized, word_clean, fusha_equivalent, definition, synonyms



Update get_sections to group by word_vocalized first character



Update get_stats to use pos, tags, proverbs instead of old fields



Update translate, search, list_words with new column names

2d. Update RAG engine (backend/app/rag_engine.py)





Update all entry.get("hadrami_word") -> entry.get("word_vocalized") etc.



Update _entries_to_response to construct Entry with new field names



Update ExamplePair construction to use h/f keys



Update _context_block, _collect_highlight_surfaces, _few_shot_pairs_from_entry

2e. Update main.py routes (backend/app/main.py)





Update route handlers and response model references for renamed fields



Add new /chat POST endpoint that accepts ChatRequest (message history + new query)



The chat endpoint: retrieve context via pgvector, build a multi-turn Gemini prompt with history, return streamed response

2f. Update sync script (scripts/sync_to_supabase.py)





Fix _load_dataset(): the JSON is a raw array, not {"entries": [...]} -- change to handle both formats



Update _entry_to_row() to map new JSON fields to new DB columns



Update _embedding_text_for_entry() to use new field names



Step 3: Frontend Refactoring (Flutter)

3a. Update Dart models (flutter_app/lib/src/core/models/word_entry.dart)





Rename WordEntry fields to match new API response:





hadramiWord -> wordVocalized, arabicFus7a -> fushaEquivalent, fullDefinition -> definition, etc.



Add new fields: root, region, source, tags



Remove: fus7aShort, isArchaic, thematicCategory, searchKey



Update ExamplePair to use h/f instead of hadrami/fusha



Update TranslateResult, AskResult, PhraseTranslateResult field names



Run dart run build_runner build --delete-conflicting-outputs

3b. Update API service (flutter_app/lib/src/core/services/api_service.dart)





Update field references in translate(), submitFeedback()



Add new sendChatMessage() method for the chat feature



Add streaming support via SSE or chunked responses

3c. Update Dictionary/Search UI





Update word_card.dart, word_detail_sheet.dart to display new field names



Update dictionary_provider.dart, search_provider.dart for new model fields



Update any home_page.dart references



Step 4: Chat Interface (Flutter)

4a. Create chat module structure

flutter_app/lib/src/modules/chat/
  pages/chat_page.dart
  providers/chat_provider.dart
  widgets/chat_bubble.dart
  widgets/chat_input.dart
  models/chat_message.dart

4b. Chat data model (chat_message.dart)





ChatMessage with role (user/assistant), content, timestamp



Chat state holds List<ChatMessage> history and loading flag

4c. Chat provider (chat_provider.dart)





Riverpod StateNotifier or AsyncNotifier managing message history



Calls ApiService.sendChatMessage() with full history + new query



Handles loading, error, and streaming states

4d. Chat UI (chat_page.dart)





Scrollable ListView of ChatBubble widgets (user right, AI left)



Bottom input bar with text field + send button



Auto-scroll to newest message on new content



Loading indicator while AI is responding



RTL-aware layout for Arabic content

4e. Router integration





Add /chat route as a new StatefulShellBranch in router.dart



Add chat icon to the bottom navigation in LandingPage



Execution Order

Step 1 first (database), then Step 2 (backend) to validate the API works, then Step 3 (Flutter models/UI), and finally Step 4 (chat feature). Each step will be confirmed before moving to the next.