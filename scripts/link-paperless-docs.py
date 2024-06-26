#!/usr/bin/env python3

import os
from pathlib import Path
import click
from typing import (
    Generator,
    Generic,
    Mapping,
    Optional,
    Type,
    TypeVar,
)
from urllib.parse import urljoin
from datetime import date, datetime

import httpx
import structlog.stdlib
from pydantic import BaseModel, Field
from structlog.contextvars import bound_contextvars


DEFAULT_TIMEOUT = 30
DEFAULT_PAGE_SIZE = 1000

logger = structlog.stdlib.get_logger()


class Connection(BaseModel):
    """
    Represents a connection to the Paperless API.
    """

    api_base_url: str
    client_cert: Optional[str]
    client_key: Optional[str]
    token: Optional[str]

    @property
    def cert(self) -> Optional[tuple[str, str]]:
        """
        Returns the client certificate and key as a tuple.
        """

        if self.client_cert and self.client_key:
            return (self.client_cert, self.client_key)
        return None

    @property
    def headers(self) -> Mapping[str, str]:
        """
        Returns the headers for the API request.
        """

        headers = {}
        if token := self.token:
            headers["Authorization"] = f"Token {token}"
        return headers


def query(
    connection: Connection,
    url: str,
    params: Optional[Mapping[str, str | int]] = None,
) -> httpx.Response:
    """
    Query the Paperless API synchronously.

    Args:
        connection (Connection): The connection object containing API details.
        url (str): The API endpoint to query.
        params (Optional[Mapping[str, str | int]]): Optional query parameters.

    Returns:
        httpx.Response: The response from the API.
    """

    with httpx.Client(cert=connection.cert) as client:
        with bound_contextvars(url=url):
            logger.debug("Querying Paperless API", url=url, params=params)

            res = client.get(
                url,
                headers=connection.headers,
                params=params,
                timeout=DEFAULT_TIMEOUT,
            )

            if res.status_code != 200:
                logger.error(
                    "Failed to fetch data from Paperless API",
                    status_code=res.status_code,
                    reason=res.reason_phrase,
                )
                logger.debug("Response", response=res.text)
                res.raise_for_status()

            return res


TItem = TypeVar("TItem")


class PaginatedResponse(BaseModel, Generic[TItem]):
    """
    Represents a paginated response from the Paperless API.
    """

    next: Optional[str]
    results: list[TItem]


def fetch_data_paginated(
    connection: Connection,
    path: str,
    response_model: Type[PaginatedResponse[TItem]],
    params: Optional[Mapping[str, str | int]] = None,
) -> Generator[TItem, None, None]:
    """
    Fetch paginated data from the Paperless API.

    Args:
        connection (Connection): The connection object containing API details.
        path (str): The API endpoint path.
        response_model (Type[PaginatedResponse[TItem]]): The response model type.
        params (Optional[Mapping[str, str | int]]): Optional query parameters.

    Yields:
        TItem: Items from the paginated response.
    """

    logger.debug(
        "Fetching data from Paperless API",
        connection=connection,
        path=path,
        params=params,
    )

    url = urljoin(connection.api_base_url, path)

    while url is not None:
        res = query(connection, url, params=params)

        data = response_model.model_validate_json(res.content)

        yield from data.results

        url = data.next


class Correspondent(BaseModel):
    """
    Represents a correspondent in the Paperless system.
    """

    id: int
    slug: str
    name: str
    match: str
    matching_algorithm: int
    is_insensitive: bool
    document_count: int
    owner: Optional[int]
    user_can_change: bool


class DocumentType(BaseModel):
    """
    Represents a document type in the Paperless system.
    """

    id: int
    slug: str
    name: str
    match: str
    matching_algorithm: int
    is_insensitive: bool
    document_count: int
    owner: Optional[int]
    user_can_change: bool


class Tag(BaseModel):
    """
    Represents a tag in the Paperless system.
    """

    id: int
    slug: str
    name: str
    colour: int
    match: str
    matching_algorithm: int
    is_insensitive: bool
    is_inbox_tag: bool
    document_count: int
    owner: Optional[int]
    user_can_change: bool


class Document(BaseModel):
    """
    Represents a document in the Paperless system.
    """

    id: int
    correspondent: Optional[int]
    document_type: Optional[int]
    storage_path: Optional[str]
    title: str
    content: str
    tags: list[int]
    created: datetime
    created_date: date
    modified: datetime
    added: datetime
    archive_serial_number: Optional[int]
    original_file_name: str
    archived_file_name: Optional[str]
    owner: Optional[int]
    user_can_change: bool
    is_shared_by_requester: bool
    notes: list[str]
    custom_fields: list[str]

    correspondent_obj: Optional[Correspondent] = None
    document_type_obj: Optional[DocumentType] = None
    tags_obj: list[Tag] = Field(default_factory=list)


@click.command()
@click.option(
    "--api-base-url",
    type=str,
    required=True,
    help="Base URL for the Paperless API",
    default="https://docs.nn42.de",
    envvar="API_BASE_URL",
)
@click.option(
    "--client-cert",
    type=click.Path(exists=True),
    help="Path to the client certificate",
    envvar="CLIENT_CERT",
)
@click.option(
    "--client-key",
    type=click.Path(exists=True),
    help="Path to the client key",
    envvar="CLIENT_KEY",
)
@click.option("--token", type=str, help="API token for authentication", envvar="TOKEN")
@click.option(
    "--src-dir",
    type=click.Path(exists=True),
    required=True,
    help="Source directory containing the documents",
    envvar="SRC_DIR",
)
@click.option(
    "--dst-dir",
    type=click.Path(),
    required=True,
    help="Destination directory to link the documents",
    envvar="DST_DIR",
)
@click.option(
    "--dry-run",
    is_flag=True,
    default=False,
    help="Run the script in dry-run mode",
    envvar="DRY_RUN",
)
@click.option(
    "--folder-tags",
    type=str,
    help="Comma-separated list of tag IDs to be used for creating subfolders in the destination paths",
    envvar="FOLDER_TAGS",
)
@click.option(
    "--filter-tag-id",
    type=int,
    help="Tag ID to filter documents",
    required=False,
)
@click.option(
    "--all",
    is_flag=True,
    help="Query all documents",
    required=False,
)
def link_paperless_docs(
    api_base_url: str,
    client_cert: Optional[str],
    client_key: Optional[str],
    token: Optional[str],
    src_dir: str,
    dst_dir: str,
    dry_run: bool,
    folder_tags: Optional[str],
    filter_tag_id: Optional[int],
    all: bool,
):
    """
    Main function to link Paperless documents to a destination directory.

    Args:
        api_base_url (str): Base URL for the Paperless API.
        client_cert (Optional[str]): Path to the client certificate.
        client_key (Optional[str]): Path to the client key.
        token (Optional[str]): API token for authentication.
        src_dir (str): Source directory containing the documents.
        dst_dir (str): Destination directory to link the documents.
        dst_path (Path): Destination directory path.
        dry_run (bool): If True, run the script in dry-run mode.
        filter_tag_id (Optional[int]): The tag ID to filter documents.
        all (bool): If True, query all documents.

    Returns:
        None
    """
    if not filter_tag_id and not all:
        raise click.UsageError("You must provide either --filter-tag-id or --all.")

    if filter_tag_id and all:
        raise click.UsageError("You cannot use --filter-tag-id and --all together.")

    connection = Connection(
        api_base_url=api_base_url,
        client_cert=client_cert,
        client_key=client_key,
        token=token,
    )

    correspondent_map = {
        c.id: c
        for c in fetch_data_paginated(
            connection,
            "/api/correspondents/",
            PaginatedResponse[Correspondent],
            {"page_size": DEFAULT_PAGE_SIZE},
        )
    }

    document_type_map = {
        dt.id: dt
        for dt in fetch_data_paginated(
            connection,
            "/api/document_types/",
            PaginatedResponse[DocumentType],
            {"page_size": DEFAULT_PAGE_SIZE},
        )
    }

    tag_map = {
        t.id: t
        for t in fetch_data_paginated(
            connection,
            "/api/tags/",
            PaginatedResponse[Tag],
            {"page_size": DEFAULT_PAGE_SIZE},
        )
    }

    params = {
        "truncate_content": "true",
        "page_size": DEFAULT_PAGE_SIZE,
    }

    if filter_tag_id:
        params["tags__id__all"] = filter_tag_id

    docs = list(
        fetch_data_paginated(
            connection,
            "/api/documents/",
            PaginatedResponse[Document],
            params,
        )
    )

    # Resolve references
    for doc in docs:
        doc.correspondent_obj = (
            correspondent_map[doc.correspondent] if doc.correspondent else None
        )
        doc.document_type_obj = (
            document_type_map[doc.document_type] if doc.document_type else None
        )
        doc.tags_obj = [tag_map[tag_id] for tag_id in doc.tags]

    folder_tag_ids = (
        {int(tag_id) for tag_id in folder_tags.split(",")} if folder_tags else set()
    )

    link_documents_to_dst(src_dir, dst_dir, docs, dry_run, folder_tag_ids, tag_map)


def link_documents_to_dst(
    src_dir: str,
    dst_dir: str,
    docs: list[Document],
    dry_run: bool,
    folder_tag_ids: set[int],
    tag_map: Mapping[int, Tag],
):
    """
    Link documents from the source directory to the destination directory.

    Args:
        src_dir (str): Source directory containing the documents.
        dst_dir (str): Destination directory to link the documents.
        docs (list[Document]): List of documents to link.
        dry_run (bool): If True, run the script in dry-run mode.

    Returns:
        None
    """

    src_path = Path(src_dir)
    dst_path = Path(dst_dir)

    # Ensure dst_dir exists
    if not dry_run:
        logger.debug("Creating directory", dst_path=dst_path)
        dst_path.mkdir(parents=True, exist_ok=True)
    elif not dst_path.exists():
        print(f"Would create directory: {dst_path}")

    # Existing files mapping
    existing_files = set(dst_path.rglob("*.pdf"))

    linked_files = set()

    for doc in docs:
        with bound_contextvars(doc_id=doc.id, doc_title=doc.title):
            logger.debug("Processing document")

            doc_type_name = (
                doc.document_type_obj.name if doc.document_type_obj else "Unknown"
            )
            date_path = doc.created_date.strftime("%Y-%m")
            file_name = f"{doc.created_date.strftime('%Y-%m-%d')} {doc.correspondent_obj.name if doc.correspondent_obj else 'Unknown'} {doc.title}.pdf"
            # Construct special tag layer if applicable
            special_tag_layer = ""
            matching_folder_tags = [
                tag_map[tag_id].name for tag_id in doc.tags if tag_id in folder_tag_ids
            ]
            if matching_folder_tags:
                special_tag_layer = "-".join(matching_folder_tags)

            dst_file_path = (
                dst_path / special_tag_layer / doc_type_name / date_path / file_name
            )

            # Ensure target directory exists
            if not dry_run:
                logger.debug("Creating directory", dst_file_path=dst_file_path)
                dst_file_path.parent.mkdir(parents=True, exist_ok=True)
            elif not dst_file_path.parent.exists():
                print(f"Would create directory: {dst_file_path.parent}")

            archive_src_file_path = src_path / "archive" / f"{doc.id:07}.pdf"
            originals_src_file_path = src_path / "originals" / f"{doc.id:07}.pdf"

            if archive_src_file_path.exists():
                link_file(
                    archive_src_file_path,
                    dst_file_path,
                    dry_run,
                    linked_files,
                )
            elif originals_src_file_path.exists():
                link_file(
                    originals_src_file_path,
                    dst_file_path,
                    dry_run,
                    linked_files,
                )
            else:
                logger.warning(
                    "Source file does not exist (checked both archive and originals)",
                    archive_src_file_path=archive_src_file_path,
                    originals_src_file_path=originals_src_file_path,
                    doc_id=doc.id,
                )

    # Remove stale files and empty directories
    remove_stale_files_and_empty_dirs(existing_files, linked_files, dst_path, dry_run)


def remove_stale_files_and_empty_dirs(
    existing_files: set[Path], linked_files: set[Path], dst_path: Path, dry_run: bool
):
    """
    Remove stale files and empty directories.

    Args:
        existing_files (set[Path]): Set of existing files.
        linked_files (set[Path]): Set of linked files.
        dry_run (bool): If True, run the script in dry-run mode.

    Returns:
        None
    """

    logger.debug(
        "Removing stale files and empty directories",
        existing_files=existing_files,
        linked_files=linked_files,
    )

    # Remove stale files
    stale_files = existing_files - linked_files
    for stale_file in stale_files:
        if dry_run:
            print(f"Would remove stale file: {stale_file}")
        else:
            logger.debug("Removing stale file", stale_file=stale_file)
            os.remove(stale_file)

    # Remove empty directories recursively
    for dir_path in sorted(dst_path.rglob("*"), reverse=True):
        if dir_path.is_dir() and not any(dir_path.iterdir()) and dir_path != dst_path:
            if dry_run:
                print(f"Would remove empty directory: {dir_path}")
            else:
                logger.debug("Removing empty directory", dir_path=dir_path)
                dir_path.rmdir()


def link_file(
    src_file_path: Path,
    dst_file_path: Path,
    dry_run: bool,
    linked_files: set[Path],
):
    """
    Link the file from the source path to the destination path.

    Args:
        src_file_path (Path): Source file path.
        dst_file_path (Path): Destination file path.
        dry_run (bool): If True, run the script in dry-run mode.
        linked_files (set[Path]): Set of linked files.
        doc_id (int): Document ID.

    Returns:
        None
    """
    if not src_file_path.exists():
        raise FileNotFoundError(f"Source file does not exist: {src_file_path}")

    if dry_run:
        print(f"Would link {src_file_path} to {dst_file_path}")
    else:
        if not dst_file_path.exists():
            logger.debug(
                "Linking file",
                src_file_path=src_file_path,
                dst_file_path=dst_file_path,
            )
            os.link(src_file_path, dst_file_path)
        else:
            logger.warning(
                "Destination file already exists",
                src_file_path=src_file_path,
                dst_file_path=dst_file_path,
            )
    linked_files.add(dst_file_path)


if __name__ == "__main__":
    link_paperless_docs()
