from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """App configuration. Real secrets come from the environment / server .env."""

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # Storage
    database_url: str = "sqlite:///./time.db"

    # Auth
    jwt_secret: str = "dev-insecure-change-me"
    jwt_algorithm: str = "HS256"
    access_token_ttl_hours: int = 24 * 30  # 30 days; personal app, long sessions

    # Email (local Postfix relay on the mail server)
    smtp_host: str = "localhost"
    smtp_port: int = 25
    smtp_use_tls: bool = False
    smtp_user: str = ""
    smtp_password: str = ""
    mail_from: str = "Time <time@alterspring.org>"

    # Verification codes
    code_ttl_minutes: int = 30
    # Local-dev only: return the verification code in the API response so the
    # flow can be driven without SMTP. MUST stay false in production.
    expose_codes: bool = False

    # CORS — comma separated origins, or "*" in dev
    cors_origins: str = "*"

    # Public base URL of the web app (used in verification email links)
    app_base_url: str = "http://localhost:8080"

    @property
    def cors_list(self) -> list[str]:
        if self.cors_origins.strip() == "*":
            return ["*"]
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
