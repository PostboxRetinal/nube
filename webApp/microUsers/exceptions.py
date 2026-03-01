from __future__ import annotations
from typing import Optional
from werkzeug.exceptions import HTTPException

class AppError(HTTPException):
    """Base class for all custom application errors."""
    description = "An application error occurred."

    def __init__(self, message: Optional[str] = None, payload: Optional[dict] = None):
        super().__init__(description=message or self.description)
        self.payload = payload or {}

    def to_dict(self) -> dict:
        return {
            "error": self.description,
            "status": self.code,
            **self.payload,
        }

class BadRequestError(AppError):
    code = 400
    description = "Bad request. Please check the data you submitted."

class NotFoundError(AppError):
    code = 404
    description = "Resource not found."

class ProductNotFoundError(NotFoundError):
    description = "Producto no existe."

    def __init__(self, product_id: Optional[int] = None):
        payload = {"product_id": product_id} if product_id is not None else {}
        super().__init__(message=self.description, payload=payload)

class InsufficientInventoryError(AppError):
    code = 409
    description = "Inventario insuficiente."

    def __init__(self, product_id: Optional[int] = None, available: Optional[int] = None, requested: Optional[int] = None):
        payload = {}
        if product_id is not None:
            payload["product_id"] = product_id
        if available is not None:
            payload["available_stock"] = available
        if requested is not None:
            payload["requested_quantity"] = requested
        super().__init__(message=self.description, payload=payload)

class InternalServerError(AppError):
    code = 500
    description = "Error interno. Por favor intente más tarde."