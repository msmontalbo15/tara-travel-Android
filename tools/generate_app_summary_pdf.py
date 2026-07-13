from pathlib import Path
from xml.sax.saxutils import escape

import fitz
from pypdf import PdfReader
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.pdfgen import canvas
from reportlab.platypus import Paragraph


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "output" / "pdf"
TMP_DIR = ROOT / "tmp" / "pdfs"
PDF_PATH = OUT_DIR / "tara_travel_app_summary.pdf"
PNG_PATH = TMP_DIR / "tara_travel_app_summary_page1.png"


PAGE_W, PAGE_H = letter
MARGIN = 34
GAP = 18
COL_W = (PAGE_W - (MARGIN * 2) - GAP) / 2


styles = getSampleStyleSheet()
TITLE = ParagraphStyle(
    "Title",
    parent=styles["Title"],
    fontName="Helvetica-Bold",
    fontSize=22,
    leading=24,
    alignment=TA_CENTER,
    textColor=colors.HexColor("#2B1D17"),
    spaceAfter=0,
)
SUBTITLE = ParagraphStyle(
    "Subtitle",
    parent=styles["Normal"],
    fontName="Helvetica",
    fontSize=9.5,
    leading=12,
    alignment=TA_CENTER,
    textColor=colors.HexColor("#6F625B"),
)
SECTION = ParagraphStyle(
    "Section",
    parent=styles["Heading4"],
    fontName="Helvetica-Bold",
    fontSize=11.5,
    leading=13,
    textColor=colors.HexColor("#A44F2C"),
    spaceAfter=0,
)
BODY = ParagraphStyle(
    "Body",
    parent=styles["BodyText"],
    fontName="Helvetica",
    fontSize=9.2,
    leading=11.2,
    textColor=colors.HexColor("#2F2A27"),
)
NOTE = ParagraphStyle(
    "Note",
    parent=BODY,
    fontSize=8.3,
    leading=10.2,
    textColor=colors.HexColor("#6F625B"),
)


LEFT_SECTIONS = [
    (
        "What It Is",
        [
            (
                "Tara Travel is a Flutter app for coordinating shared trips in one place, with screens for planning, budgets, members, packing, navigation, chat, and notifications."
            ),
            (
                "Repo evidence shows Supabase-backed auth/data plus a local Sembast cache for selected trip, itinerary, expense, and profile data."
            ),
        ],
    ),
    (
        "Who It's For",
        [
            (
                "Primary persona: a small-group trip organizer traveling with friends or family who needs to coordinate plans, people, and shared costs."
            ),
            (
                "Formal persona document: Not found in repo."
            ),
        ],
    ),
    (
        "What It Does",
        [
            "Supports onboarding plus Magic Link, email/password, and Google OAuth sign-in.",
            "Creates trips through a 4-step flow for details, transport, budget, and confirmation.",
            "Tracks itineraries, stop status, and trip activity logs.",
            "Manages shared budgets, expenses, contributions, split modes, and settlements.",
            "Coordinates members with invite codes, trip roles, and contact actions.",
            "Keeps shared packing lists with suggestions, progress, and reminder actions.",
            "Includes screens for notifications, group chat, and live/group navigation UI.",
        ],
    ),
]

RIGHT_SECTIONS = [
    (
        "How It Works",
        [
            (
                "Flutter MaterialApp routes into feature screens; Riverpod providers expose app state and repositories."
            ),
            (
                "Repositories call Supabase for auth and trip data, then cache selected records locally in Sembast for offline fallback and optimistic UI."
            ),
            (
                "Supabase migrations define users, trips, trip_members, itinerary_stops, expenses, settlements, packing_items, contributions, activity_log, notifications, destinations, member_locations, and trip_messages with row-level security."
            ),
            (
                "Supabase Edge Functions send Expo push notifications directly and when expense status changes."
            ),
            (
                "Concrete data-flow diagram or architecture doc: Not found in repo."
            ),
        ],
    ),
    (
        "How To Run",
        [
            "Install Flutter with a Dart SDK compatible with >=3.2.0 and <4.0.0.",
            "Copy .env.example to .env and set EXPO_PUBLIC_SUPABASE_URL plus EXPO_PUBLIC_SUPABASE_ANON_KEY.",
            "Apply Supabase SQL migrations 001_initial_schema.sql and 002_real_data_support.sql. Optional dev data: 003_dev_seed.sql.",
            "Run flutter pub get, then flutter run from the repo root.",
            "Notification/Edge Function deployment steps beyond the source files: Not found in repo.",
        ],
    ),
]


def draw_para(pdf: canvas.Canvas, text: str, style: ParagraphStyle, x: float, y: float, width: float) -> float:
    para = Paragraph(escape(text), style)
    _, h = para.wrap(width, PAGE_H)
    para.drawOn(pdf, x, y - h)
    return y - h


def draw_section(pdf: canvas.Canvas, title: str, items: list[str], x: float, y: float, width: float) -> float:
    y = draw_para(pdf, title, SECTION, x, y, width)
    y -= 5
    for item in items:
        if item.startswith("Primary persona:") or item.startswith("Formal persona") or item.endswith("repo.") or item.endswith("repo.") or item.endswith("repo") or item.startswith("Concrete data-flow") or item.startswith("Notification/Edge Function") or item.startswith("Tara Travel is") or item.startswith("Repo evidence"):
            y = draw_para(pdf, item, BODY, x, y, width)
        else:
            y = draw_para(pdf, f"- {item}", BODY, x, y, width)
        y -= 4
    return y - 4


def build_pdf() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    TMP_DIR.mkdir(parents=True, exist_ok=True)

    pdf = canvas.Canvas(str(PDF_PATH), pagesize=letter)
    pdf.setTitle("Tara Travel App Summary")

    pdf.setFillColor(colors.HexColor("#F7F2EE"))
    pdf.rect(0, 0, PAGE_W, PAGE_H, fill=1, stroke=0)
    pdf.setFillColor(colors.HexColor("#E9DDD5"))
    pdf.roundRect(MARGIN - 8, PAGE_H - 118, PAGE_W - (MARGIN * 2) + 16, 82, 18, fill=1, stroke=0)

    title_y = PAGE_H - 64
    draw_para(pdf, "Tara Travel - One-Page App Summary", TITLE, MARGIN, title_y, PAGE_W - (MARGIN * 2))
    draw_para(
        pdf,
        "Evidence-based summary generated from repo files inspected in this workspace.",
        SUBTITLE,
        MARGIN,
        PAGE_H - 88,
        PAGE_W - (MARGIN * 2),
    )

    left_x = MARGIN
    right_x = MARGIN + COL_W + GAP
    start_y = PAGE_H - 136

    left_y = start_y
    for heading, items in LEFT_SECTIONS:
        left_y = draw_section(pdf, heading, items, left_x, left_y, COL_W)

    right_y = start_y
    for heading, items in RIGHT_SECTIONS:
        right_y = draw_section(pdf, heading, items, right_x, right_y, COL_W)

    footer_y = min(left_y, right_y) - 2
    footer = (
        "Key repo evidence: lib/main.dart, Riverpod providers/repositories, Supabase migrations, "
        "Supabase Edge Functions, and .env.example."
    )
    footer_y = draw_para(pdf, footer, NOTE, MARGIN, footer_y, PAGE_W - (MARGIN * 2))

    if footer_y < 20:
        raise RuntimeError("Content overflowed the single-page layout.")

    pdf.showPage()
    pdf.save()


def validate_pdf() -> None:
    reader = PdfReader(str(PDF_PATH))
    if len(reader.pages) != 1:
        raise RuntimeError(f"Expected 1 page, found {len(reader.pages)}")

    text = (reader.pages[0].extract_text() or "").lower()
    required = [
        "what it is",
        "who it's for",
        "what it does",
        "how it works",
        "how to run",
    ]
    missing = [item for item in required if item not in text]
    if missing:
        raise RuntimeError(f"Missing expected sections in PDF text: {missing}")


def render_preview() -> None:
    doc = fitz.open(str(PDF_PATH))
    page = doc.load_page(0)
    pix = page.get_pixmap(matrix=fitz.Matrix(2, 2), alpha=False)
    pix.save(str(PNG_PATH))
    doc.close()


if __name__ == "__main__":
    build_pdf()
    validate_pdf()
    render_preview()
    print(PDF_PATH)
    print(PNG_PATH)
