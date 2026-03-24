from typing import Optional

from pydantic import BaseModel


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
