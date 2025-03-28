# app/exceptions.py

class UserNotFoundException(Exception):
    def __init__(self, message: str = "User not found"):
        self.message = message
        super().__init__(message)

class CompanyNotFoundException(Exception):
    def __init__(self, message: str = "Company not found"):
        self.message = message
        super().__init__(message)

class TokenException(Exception):
    def __init__(self, message: str, code: str = "TKN_ERR"):
        self.message = message
        self.code = code
        super().__init__(message)

class TokenExpiredException(TokenException):
    def __init__(self, message: str = "Token has expired"):
        super().__init__(message, code="TKN_EXP")

class InvalidSignatureException(TokenException):
    def __init__(self, message: str = "Invalid token signature"):
        super().__init__(message, code="TKN_SIG")

class InvalidTokenException(TokenException):
    def __init__(self, message: str = "Invalid token"):
        super().__init__(message, code="TKN_INV")
