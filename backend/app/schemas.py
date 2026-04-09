from enum import Enum
from typing import Optional

from pydantic import BaseModel, Field

from .core.config import PHRASE_TRANSLATE_MAX_CHARS


class ExamplePair(BaseModel):
    hadrami: str = ""
    fusha: str = ""


class Entry(BaseModel):
    id: int
    hadrami_word: str
    arabic_fus7a: str
    full_definition: str
    fus7a_short: Optional[str] = None
    search_key: Optional[str] = None
    part_of_speech: Optional[str] = None
    thematic_category: Optional[str] = None
    is_archaic: bool = False
    pronunciation_notes: Optional[list[str]] = None
    proverb_record: Optional[list[str]] = None
    cultural_note: Optional[str] = None
    aliases: Optional[list[str]] = None
    examples: Optional[list[ExamplePair]] = None


class TranslateResponse(BaseModel):
    found: bool
    hadrami_word: str
    arabic_fus7a: str
    full_definition: str
    confidence: str


class FeedbackType(str, Enum):
    correction = "correction"
    new_word = "new_word"
    sentence_pair = "sentence_pair"
    spelling_variant = "spelling_variant"


class FeedbackRequest(BaseModel):
    word_id: int = 0
    hadrami_word: str
    suggested_fus7a: str = ""
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
    """First-letter partition (حرف الابتداء) with live word count."""

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


class TranslatePhraseResponse(BaseModel):
    input_text: str
    direction: str
    translated_text: str
    hadrami_spans: list[HadramiSpan]
    mode: str
    rag_mode: str
    context: list[Entry]
