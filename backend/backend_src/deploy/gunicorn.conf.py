import os

workers = int(os.environ.get("GXB_HTTP_WORKERS", "1"))
if workers not in (1, 2, 4):
    raise RuntimeError("Pass348 proves gradual Gunicorn stages 1, 2, and 4")
worker_class = "gthread"
threads = int(os.environ.get("GXB_HTTP_THREADS", "8"))
bind = os.environ.get("GXB_HTTP_BIND", "unix:/run/gxb/http.sock")
preload_app = False
umask = 0o007
timeout = 120
graceful_timeout = 30
accesslog = "-"
errorlog = "-"
