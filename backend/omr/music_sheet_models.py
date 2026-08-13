from pydantic import BaseModel


class OmrConversionRequest(BaseModel):
    ownerId: str
