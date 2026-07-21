from personal_ai_mcp.common.models import StrictModel

class SearchRequest(StrictModel):
    vault_id: str
    query: str
    limit: int = 5

class GetChunkRequest(StrictModel):
    vault_id: str
    chunk_id: str

class VaultRequest(StrictModel):
    vault_id: str
