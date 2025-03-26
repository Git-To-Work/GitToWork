# app/exceptions.py

class UserNotFoundException(Exception):
    def __init__(self, message: str = "User not found"):
        self.message = message
        super().__init__(message)

class CompanyNotFoundException(Exception):
    def __init__(self, message: str = "Company not found"):
        self.message = message
        super().__init__(message)
