#!/usr/bin/env python3
"""Generate the PulseScore legal site.

One static page per language per document, so the app can link straight to a
reader's own language and the page renders with no JavaScript — a legal notice
should not depend on scripts being enabled.

    python3 web/legal/build.py          # writes web/legal/dist/

Output:
    dist/index.html            language-aware landing page
    dist/privacy.html          redirects to a language, for bare links
    dist/terms.html            ditto
    dist/<lang>/privacy.html   the real pages
    dist/<lang>/terms.html
"""

import json
import html
import pathlib
import shutil

ROOT = pathlib.Path(__file__).parent
CONTENT = ROOT / "content"
DIST = ROOT / "dist"

# Edit these two, then re-run the script.
CONTACT_EMAIL = "support@pulsescore.app"
APP_NAME = "PulseScore"

# Mirrors kSupportedLocales in lib/l10n/app_locales.dart, same order.
LANGS = [
    ("vi", "Tiếng Việt"), ("hi", "हिन्दी"), ("en", "English"),
    ("pt", "Português"), ("es", "Español"), ("fr", "Français"),
    ("id", "Bahasa Indonesia"), ("ko", "한국어"), ("ja", "日本語"),
    ("zh", "中文"), ("th", "ไทย"), ("tr", "Türkçe"),
    ("de", "Deutsch"), ("ar", "العربية"),
]

CSS = """
*{box-sizing:border-box}
:root{
  --bg:#0B1220; --surface:#131D2E; --border:#1E2A3D; --green:#2BE06B;
  --text:#FFFFFF; --muted:#8A94A6; --faint:#5C6678;
  --sans:'Inter',-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;
  --mono:'JetBrains Mono',ui-monospace,SFMono-Regular,Menlo,monospace;
}
html{-webkit-text-size-adjust:100%}
body{margin:0;background:var(--bg);color:var(--text);font-family:var(--sans);
  font-size:16px;line-height:1.6;-webkit-font-smoothing:antialiased}
.wrap{max-width:720px;margin:0 auto;padding:32px 20px 96px}
header{display:flex;align-items:center;gap:12px;padding-bottom:20px;
  border-bottom:1px solid var(--border);margin-bottom:28px}
.mark{width:40px;height:40px;border-radius:11px;flex:0 0 auto;
  border:1.5px solid var(--green);background:linear-gradient(135deg,#14202F,#060A11);
  display:flex;align-items:center;justify-content:center;font-weight:800;
  color:#fff;font-size:20px;box-shadow:0 0 18px rgba(43,224,107,.25)}
.brand{font-weight:800;font-size:19px;letter-spacing:-.4px}
.brand span{color:var(--green)}
.tagline{color:var(--muted);font-size:12.5px;font-family:var(--mono)}
h1{font-size:30px;line-height:1.2;letter-spacing:-.8px;margin:0 0 8px;font-weight:800}
.updated{font-family:var(--mono);font-size:12.5px;color:var(--faint);
  letter-spacing:.6px;text-transform:uppercase;margin:0 0 24px}
.summary{background:rgba(43,224,107,.08);border:1px solid rgba(43,224,107,.35);
  border-radius:14px;padding:16px 18px;margin:0 0 32px;color:#D6F5E2}
h2{font-size:15px;margin:36px 0 10px;font-family:var(--mono);font-weight:500;
  letter-spacing:1.4px;text-transform:uppercase;color:var(--muted);
  display:flex;align-items:center;gap:10px}
h2::before{content:"";width:3px;height:14px;border-radius:2px;
  background:var(--green);flex:0 0 auto}
p{margin:0 0 12px;color:#C9D2E0}
ul{margin:0 0 12px;padding-inline-start:22px;color:#C9D2E0}
li{margin-bottom:6px}
a{color:var(--green)}
nav.docs{display:flex;gap:10px;margin-bottom:26px;flex-wrap:wrap}
nav.docs a{display:inline-block;padding:9px 16px;border-radius:100px;
  border:1px solid var(--border);background:rgba(19,29,46,.6);
  font-size:13.5px;font-weight:600;text-decoration:none;color:var(--muted)}
nav.docs a.on{background:var(--green);border-color:var(--green);color:#04210F}
.langs{margin-top:52px;padding-top:22px;border-top:1px solid var(--border)}
.langs-label{font-family:var(--mono);font-size:11.5px;letter-spacing:1.4px;
  text-transform:uppercase;color:var(--faint);margin-bottom:12px}
.langs-list{display:flex;flex-wrap:wrap;gap:8px}
.langs-list a{font-size:13.5px;text-decoration:none;color:var(--muted);
  padding:6px 12px;border:1px solid var(--border);border-radius:9px}
.langs-list a.on{color:var(--green);border-color:rgba(43,224,107,.5)}
footer{margin-top:34px;color:var(--faint);font-size:13px}
.langs a{font-size:13.5px;text-decoration:none}
table.index{width:100%;border-collapse:collapse;margin-top:8px}
table.index th{text-align:start;font-weight:600;font-size:14.5px;color:var(--text);
  padding:11px 10px 11px 0;border-bottom:1px solid var(--border);white-space:nowrap}
table.index td{padding:11px 0 11px 10px;border-bottom:1px solid var(--border);
  font-size:13.5px}
table.index a{text-decoration:none}
[dir="rtl"] nav.docs,[dir="rtl"] .langs-list{direction:rtl}
@media (max-width:520px){.wrap{padding:24px 16px 72px}h1{font-size:25px}}
"""

REDIRECT = """<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{app} — {title}</title>
<link rel="canonical" href="/en/{doc}.html">
<meta http-equiv="refresh" content="0;url=/en/{doc}.html">
<link rel="stylesheet" href="/style.css"></head>
<body><div class="wrap"><p>Redirecting to the {title}…
<a href="/en/{doc}.html">Continue</a></p></div>
<script>
// Prefer the reader's own language when we publish it; fall back to English.
var known = {known};
var want = (navigator.language || 'en').slice(0, 2).toLowerCase();
var q = new URLSearchParams(location.search).get('lang');
if (q) want = q.slice(0, 2).toLowerCase();
location.replace('/' + (known.indexOf(want) >= 0 ? want : 'en') + '/{doc}.html');
</script></body></html>
"""


def esc(s):
    return html.escape(s, quote=False)


def render(lang, data, doc_key, other_key):
    doc = data["docs"][doc_key]
    other = data["docs"][other_key]
    rtl = data.get("dir") == "rtl"

    body = []
    for sec in doc["sections"]:
        body.append(f"<h2>{esc(sec['h'])}</h2>")
        for para in sec.get("p", []):
            body.append(f"<p>{esc(para)}</p>")
        if sec.get("ul"):
            body.append("<ul>")
            body += [f"<li>{esc(i)}</li>" for i in sec["ul"]]
            body.append("</ul>")
        # Paragraphs that belong after the list rather than before it.
        for para in sec.get("p2", []):
            body.append(f"<p>{esc(para)}</p>")


    return f"""<!doctype html>
<html lang="{lang}" dir="{'rtl' if rtl else 'ltr'}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{esc(APP_NAME)} — {esc(doc['title'])}</title>
<meta name="description" content="{esc(doc['summary'])}">
<meta name="robots" content="index,follow">
<link rel="alternate" hreflang="x-default" href="/en/{doc_key}.html">
<link rel="stylesheet" href="/style.css">
</head>
<body>
<div class="wrap">
  <header>
    <div class="mark">P</div>
    <div>
      <div class="brand">Pulse<span>Score</span></div>
      <div class="tagline">{esc(data['brand_tagline'])}</div>
    </div>
  </header>

  <nav class="docs">
    <a class="on" href="/{lang}/{doc_key}.html">{esc(doc['title'])}</a>
    <a href="/{lang}/{other_key}.html">{esc(other['title'])}</a>
  </nav>

  <h1>{esc(doc['title'])}</h1>
  <p class="updated">{esc(data['updated_label'])}: {esc(data['updated'])}</p>
  <div class="summary">{esc(doc['summary'])}</div>

  {"".join(body)}

  <div class="langs">
    <a href="/">{esc(data['lang_picker_label'])} →</a>
  </div>
  <footer>© 2026 {esc(APP_NAME)}</footer>
</div>
</body>
</html>
"""


def main():
    if DIST.exists():
        shutil.rmtree(DIST)
    DIST.mkdir(parents=True)

    known = [c for c, _ in LANGS]
    written = 0

    for code, _ in LANGS:
        path = CONTENT / f"{code}.json"
        if not path.exists():
            raise SystemExit(f"missing translation: {path}")
        data = json.loads(path.read_text(encoding="utf-8"))
        data_dir = DIST / code
        data_dir.mkdir(parents=True, exist_ok=True)

        for doc_key, other_key in (("privacy", "terms"), ("terms", "privacy")):
            text = render(code, data, doc_key, other_key)
            text = text.replace("{{EMAIL}}", CONTACT_EMAIL)
            (data_dir / f"{doc_key}.html").write_text(text, encoding="utf-8")
            written += 1

    for doc_key, title in (("privacy", "Privacy Policy"), ("terms", "Terms of Service")):
        (DIST / f"{doc_key}.html").write_text(
            REDIRECT.format(app=APP_NAME, title=title, doc=doc_key,
                            known=json.dumps(known)),
            encoding="utf-8",
        )
        written += 1

    rows = []
    for code, name in LANGS:
        d = json.loads((CONTENT / f"{code}.json").read_text(encoding="utf-8"))
        rows.append(
            f'<tr><th lang="{code}">{esc(name)}</th>'
            f'<td><a href="/{code}/privacy.html" lang="{code}">'
            f'{esc(d["docs"]["privacy"]["title"])}</a></td>'
            f'<td><a href="/{code}/terms.html" lang="{code}">'
            f'{esc(d["docs"]["terms"]["title"])}</a></td></tr>'
        )
    (DIST / "index.html").write_text(f"""<!doctype html>
<html lang="en" dir="ltr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{APP_NAME} — Privacy Policy & Terms of Service</title>
<meta name="description" content="{APP_NAME} privacy policy and terms of service, in 14 languages.">
<link rel="stylesheet" href="/style.css">
</head>
<body>
<div class="wrap">
  <header>
    <div class="mark">P</div>
    <div>
      <div class="brand">Pulse<span>Score</span></div>
      <div class="tagline">Live Football Scores &amp; Stats</div>
    </div>
  </header>
  <h1>Legal</h1>
  <p class="updated">Last updated: 6 September 2026</p>
  <div class="summary">Our privacy policy and terms of service, published in every
  language the app supports. Choose yours below.</div>
  <table class="index">{"".join(rows)}</table>
  <footer>© 2026 {APP_NAME}</footer>
</div>
</body>
</html>
""", encoding="utf-8")
    written += 1

    # One shared stylesheet rather than the same 2.5 KB inlined into 31 pages.
    (DIST / "style.css").write_text(CSS, encoding="utf-8")
    written += 1

    print(f"wrote {written} files to {DIST}")


if __name__ == "__main__":
    main()
