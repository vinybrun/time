import smtplib
import ssl
from email.message import EmailMessage
from email.utils import formataddr, parseaddr

from .config import get_settings

settings = get_settings()


def _send(to_addr: str, subject: str, text_body: str, html_body: str) -> None:
    msg = EmailMessage()
    msg["Subject"] = subject
    msg["From"] = settings.mail_from
    msg["To"] = to_addr
    msg.set_content(text_body)
    msg.add_alternative(html_body, subtype="html")

    with smtplib.SMTP(settings.smtp_host, settings.smtp_port, timeout=20) as server:
        if settings.smtp_use_tls:
            server.starttls(context=ssl.create_default_context())
        if settings.smtp_user:
            server.login(settings.smtp_user, settings.smtp_password)
        server.send_message(msg)


def send_verification_email(to_addr: str, name: str, code: str) -> None:
    greeting = f"Hi {name}," if name else "Hi,"
    subject = "Your Time verification code"
    text_body = (
        f"{greeting}\n\n"
        f"Your verification code is: {code}\n\n"
        f"It expires in {settings.code_ttl_minutes} minutes.\n\n"
        f"If you didn't request this, you can ignore this email.\n\n— Time"
    )
    html_body = f"""\
<!doctype html><html><body style="font-family:-apple-system,Segoe UI,Roboto,sans-serif;
background:#f7f6f1;padding:32px;color:#2b2b2b">
  <div style="max-width:440px;margin:auto;background:#fffdf7;border:1px solid #e7e3d8;
       border-radius:16px;padding:32px;text-align:center">
    <h1 style="font-size:20px;margin:0 0 8px">Time</h1>
    <p style="margin:0 0 20px;color:#6b6b6b">{greeting} confirm your email to start.</p>
    <div style="font-size:34px;letter-spacing:8px;font-weight:700;white-space:nowrap;
         background:#f0eee6;border-radius:12px;padding:16px 8px;margin:0 0 16px">{code}</div>
    <p style="margin:0;color:#8a8a8a;font-size:13px">
      Expires in {settings.code_ttl_minutes} minutes. If this wasn't you, ignore this email.</p>
  </div>
</body></html>"""
    _send(to_addr, subject, text_body, html_body)


def send_password_reset_email(to_addr: str, name: str, code: str) -> None:
    greeting = f"Hi {name}," if name else "Hi,"
    subject = "Your Time password reset code"
    text_body = (
        f"{greeting}\n\n"
        f"Your password reset code is: {code}\n\n"
        f"It expires in {settings.code_ttl_minutes} minutes.\n\n"
        f"If you didn't request this, you can safely ignore this email — your "
        f"password won't change.\n\n— Time"
    )
    html_body = f"""\
<!doctype html><html><body style="font-family:-apple-system,Segoe UI,Roboto,sans-serif;
background:#f7f6f1;padding:32px;color:#2b2b2b">
  <div style="max-width:440px;margin:auto;background:#fffdf7;border:1px solid #e7e3d8;
       border-radius:16px;padding:32px;text-align:center">
    <h1 style="font-size:20px;margin:0 0 8px">Time</h1>
    <p style="margin:0 0 20px;color:#6b6b6b">{greeting} use this code to reset your password.</p>
    <div style="font-size:34px;letter-spacing:8px;font-weight:700;white-space:nowrap;
         background:#f0eee6;border-radius:12px;padding:16px 8px;margin:0 0 16px">{code}</div>
    <p style="margin:0;color:#8a8a8a;font-size:13px">
      Expires in {settings.code_ttl_minutes} minutes. If this wasn't you, ignore this
      email — your password stays the same.</p>
  </div>
</body></html>"""
    _send(to_addr, subject, text_body, html_body)


def from_address() -> str:
    name, addr = parseaddr(settings.mail_from)
    return formataddr((name, addr)) if name else addr
