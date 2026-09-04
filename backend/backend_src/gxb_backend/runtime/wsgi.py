"""Gunicorn WSGI entrypoint for the PostgreSQL-authoritative HTTP process."""
from .composition import create_postgres_app

app = create_postgres_app()
