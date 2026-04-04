from enum import Enum
from typing import Optional

from pydantic import BaseModel, Field

from .core.config import PHRASE_TRANSLATE_MAX_CHARS


class Entry(BaseModel):
    id: int
    hadrami_word: str
    arabic_fus7a: str
    full_definition: str


class TranslateResponse(BaseModel):
    found: bool
    hadrami_word: str
    arabic_fus7a: str
    full_definition: str
    confidence: str


class FeedbackRequest(BaseModel):
    word_id: int
    hadrami_word: str
    suggested_fus7a: str
    comment: Optional[str] = None


class SearchResult(BaseModel):
    total: int
    results: list[Entry]


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


class TranslatePhraseResponse(BaseModel):
    input_text: str
    direction: str
    translated_text: str
    hadrami_spans: list[HadramiSpan]
    mode: str
    rag_mode: str
    context: list[Entry]
