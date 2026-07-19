#!/usr/bin/env python3

"""Deterministic identity and hashing conventions for Obsidian indexing."""

from __future__ import annotations

import hashlib
import uuid


UUID_NAMESPACE = uuid.UUID("b83a8b73-03e0-5f87-a8fb-3f8996cf6f21")


def normalize_identity_component(value: str) -> str:
    """Normalize a stable identity component without losing path meaning."""

    return value.strip().replace("\\", "/")


def document_identity_input(
    vault_id: str,
    relative_path: str,
) -> str:
    return "|".join(
        (
            "obsidian",
            normalize_identity_component(vault_id),
            normalize_identity_component(relative_path),
        )
    )


def chunk_identity_input(
    vault_id: str,
    relative_path: str,
    chunk_key: str,
) -> str:
    return "|".join(
        (
            "obsidian",
            normalize_identity_component(vault_id),
            normalize_identity_component(relative_path),
            normalize_identity_component(chunk_key),
        )
    )


def deterministic_uuid(identity_input: str) -> str:
    return str(uuid.uuid5(UUID_NAMESPACE, identity_input))


def document_id(
    vault_id: str,
    relative_path: str,
) -> str:
    return deterministic_uuid(
        document_identity_input(vault_id, relative_path)
    )


def chunk_id(
    vault_id: str,
    relative_path: str,
    chunk_key: str,
) -> str:
    return deterministic_uuid(
        chunk_identity_input(
            vault_id,
            relative_path,
            chunk_key,
        )
    )


def sha256_text(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()