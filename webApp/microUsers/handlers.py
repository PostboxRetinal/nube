import logging
import traceback
from typing import Optional

from flask import jsonify
from werkzeug.exceptions import HTTPException

from exceptions import AppError

logger = logging.getLogger(__name__)

def _json_error(status: int, message: str, extra: Optional[dict] = None) -> tuple:
    body = {"error": message, "status": status}
    if extra:
        body.update(extra)
    return jsonify(body), status

def register_error_handlers(app):

    @app.errorhandler(AppError)
    def handle_app_error(exc: AppError):
        """Handles all subclasses of AppError (400, 404, 409, 500, …)."""
        code = exc.code or 500
        if code >= 500:
            logger.error("AppError %s: %s", code, exc.description, exc_info=True)
        else:
            logger.warning("AppError %s: %s", code, exc.description)
        return _json_error(code, exc.description or "An error occurred.", exc.payload)

    # ── Flask / Werkzeug built-in HTTP errors (e.g. abort(404)) ───────────────
    @app.errorhandler(HTTPException)
    def handle_http_exception(exc: HTTPException):
        code = exc.code or 500
        description = exc.description or "An error occurred."
        logger.warning("HTTPException %s: %s", code, description)
        return _json_error(code, description)

    @app.errorhandler(400)
    def bad_request(exc):
        return _json_error(400, "400 | Bad request. Please check the data you submitted.")

    @app.errorhandler(404)
    def not_found(exc):
        return _json_error(404, "404 | Resource not found.")

    @app.errorhandler(409)
    def conflict(exc):
        return _json_error(409, "409 | Insufficient inventory.")

    @app.errorhandler(500)
    def internal_error(exc):
        logger.error("Unhandled 500:\n%s", traceback.format_exc())
        return _json_error(500, "500 | Internal error. Please try again later.")

    @app.errorhandler(Exception)
    def handle_unexpected(exc):
        """Safety net: logs full traceback but never leaks details to the client."""
        logger.error(
            "Unexpected exception: %s\n%s",
            str(exc),
            traceback.format_exc(),
        )
        return _json_error(500, "500 | Internal error. Please try again later.")