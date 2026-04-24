import json
from enum import Enum
from typing import Any, Optional

from pydantic import BaseModel, Field, field_validator

from .core.config import ASK_MAX_CHARS, PHRASE_TRANSLATE_MAX_CHARS


class ExamplePair(BaseModel):
    h: str = ""
    f: str = ""


def _parse_json_list(v: Any) -> Any:
    """Coerce a JSON-encoded string to a list; leave lists/None untouched."""
    if isinstance(v, str):
        try:
            parsed = json.loads(v)
            return parsed if isinstance(parsed, list) else None
        except (json.JSONDecodeError, ValueError):
            return None
    return v


class Entry(BaseModel):
    id: int
    word_vocalized: str
    word_clean: Optional[str] = None
    root: Optional[str] = None
    pos: Optional[str] = None
    fusha_equivalent: Optional[str] = None
    definition: Optional[str] = None
    region: str = "General"
    synonyms: Optional[list[str]] = None
    phonetic_variants: Optional[list[str]] = None
    note: Optional[str] = None
    source: Optional[str] = None
    examples: Optional[list[ExamplePair]] = None
    proverbs: Optional[list[str]] = None
    tags: Optional[list[str]] = None

    @field_validator("synonyms", "phonetic_variants", "proverbs", "tags", mode="before")
    @classmethod
    def coerce_str_to_list(cls, v: Any) -> Any:
        return _parse_json_list(v)

    @field_validator("examples", mode="before")
    @classmethod
    def coerce_examples_str(cls, v: Any) -> Any:
        return _parse_json_list(v)


class TranslateResponse(BaseModel):
    found: bool
    word_vocalized: str
    fusha_equivalent: str
    definition: str
    confidence: str


class FeedbackType(str, Enum):
    correction = "correction"
    new_word = "new_word"
    sentence_pair = "sentence_pair"
    spelling_variant = "spelling_variant"


class FeedbackRequest(BaseModel):
    word_id: int = 0
    word_vocalized: str
    suggested_fusha: str = ""
    comment: Optional[str] = None
    feedback_type: FeedbackType = FeedbackType.correction
    spelling_variants: Optional[list[str]] = None
    sentence_pair_hadrami: Optional[str] = None
    sentence_pair_fusha: Optional[str] = None
    consent: bool = False


class SearchResult(BaseModel):
    total: int
    results: list[Entry]


class LexiconSection(BaseModel):
    letter: str = Field(..., description="First Arabic letter of headwords in this section")
    word_count: int = Field(..., ge=0)


class LexiconSectionsResponse(BaseModel):
    sections: list[LexiconSection]


class TranslatePhraseDirection(str, Enum):
    ar_to_hadrami = "ar_to_hadrami"
    hadrami_to_ar = "hadrami_to_ar"


class TranslatePhraseRequest(BaseModel):
    text: str = Field(..., min_length=1, max_length=PHRASE_TRANSLATE_MAX_CHARS)
    direction: TranslatePhraseDirection


class HadramiSpan(BaseModel):
    start: int
    end: int
    surface: str = ""


class AskResponse(BaseModel):
    question: str
    answer: str
    mode: str
    hadrami_spans: list[HadramiSpan] = Field(default_factory=list)
    highlight_surfaces: list[str] = Field(default_factory=list)
    context: list[Entry] = Field(default_factory=list)


class AskRequest(BaseModel):
    """POST body for /ask."""
    q: str = Field(..., min_length=1, max_length=ASK_MAX_CHARS)


class TranslatePhraseResponse(BaseModel):
    input_text: str
    direction: str
    translated_text: str
    hadrami_spans: list[HadramiSpan]
    mode: str
    rag_mode: str
    context: list[Entry]


# ---------------------------------------------------------------------------
# Chat models (conversational AI)
# ---------------------------------------------------------------------------

class ChatRole(str, Enum):
    user = "user"
    assistant = "assistant"


class ChatMessage(BaseModel):
    role: ChatRole
    content: str


class ChatRequest(BaseModel):
    message: str = Field(..., min_length=1, max_length=ASK_MAX_CHARS)
    history: list[ChatMessage] = Field(default_factory=list)


class ChatResponse(BaseModel):
    reply: str
    context: list[Entry] = Field(default_factory=list)
    hadrami_spans: list[HadramiSpan] = Field(default_factory=list)
    highlight_surfaces: list[str] = Field(default_factory=list)
