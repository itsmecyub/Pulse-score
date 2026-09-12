#!/usr/bin/env python3
"""Bundle the legal site into two self-contained pages.

`build.py` emits one static page per language, which is the nicer shape but too
large to upload through the deploy tool in one shot. This variant emits the same
content as two pages that carry every translation inline:

    dist_bundle/privacy.html
    dist_bundle/terms.html

English is rendered into the document itself, so the page is complete with
JavaScript disabled; the script only swaps the visible language when the reader
picks another one (or when the app appends ?lang=xx).

    python3 web/legal/build_bundle.py
"""

import json
import html
import pathlib
import shutil

ROOT = pathlib.Path(__file__).parent
CONTENT = ROOT / "content"
DIST = ROOT / "dist_bundle"
CONTACT_EMAIL = "support@pulsescore.app"

from build import LANGS, CSS, esc  # noqa: E402  (same palette and helpers)


def render_body(doc):
    out = []
    for sec in doc["sections"]:
        out.append(f"<h2>{esc(sec['h'])}</h2>")
        for p in sec.get("p", []):
            out.append(f"<p>{esc(p)}</p>")
        if sec.get("ul"):
            out.append("<ul>" + "".join(f"<li>{esc(i)}</li>" for i in sec["ul"]) + "</ul>")
        for p in sec.get("p2", []):
            out.append(f"<p>{esc(p)}</p>")
    return "".join(out)


def main():
    if DIST.exists():
        shutil.rmtree(DIST)
    DIST.mkdir(parents=True)

    data = {c: json.loads((CONTENT / f"{c}.json").read_text(encoding="utf-8"))
            for c, _ in LANGS}

    for doc_key, other_key in (("privacy", "terms"), ("terms", "privacy")):
        payload = {}
        for code, _ in LANGS:
            d = data[code]
            doc = d["docs"][doc_key]
            payload[code] = {
                "dir": d.get("dir", "ltr"),
                "tagline": d["brand_tagline"],
                "updated": f'{d["updated_label"]}: {d["updated"]}',
                "title": doc["title"],
                "other": d["docs"][other_key]["title"],
                "summary": doc["summary"],
                "body": render_body(doc),
                "pick": d["lang_picker_label"],
            }

        en = payload["en"]
        options = "".join(
            f'<option value="{c}">{esc(n)}</option>' for c, n in LANGS)
        blob = json.dumps(payload, ensure_ascii=False, separators=(",", ":"))

        (DIST / f"{doc_key}.html").write_text(f"""<!doctype html>
<html lang="en" dir="ltr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>PulseScore — {esc(en['title'])}</title>
<meta name="description" content="{esc(en['summary'])}">
<style>{CSS}</style>
</head>
<body>
<div class="wrap">
  <header>
    <div class="mark">P</div>
    <div>
      <div class="brand">Pulse<span>Score</span></div>
      <div class="tagline" id="tagline">{esc(en['tagline'])}</div>
    </div>
  </header>
  <nav class="docs">
    <a class="on" id="self" href="/{doc_key}.html">{esc(en['title'])}</a>
    <a id="other" href="/{other_key}.html">{esc(en['other'])}</a>
  </nav>
  <h1 id="title">{esc(en['title'])}</h1>
  <p class="updated" id="updated">{esc(en['updated'])}</p>
  <div class="summary" id="summary">{esc(en['summary'])}</div>
  <div id="body">{en['body']}</div>
  <div class="langs">
    <label class="langs-label" for="lang" id="picklabel">{esc(en['pick'])}</label>
    <select id="lang">{options}</select>
  </div>
  <footer>© 2026 PulseScore</footer>
</div>
<script id="i18n" type="application/json">{blob}</script>
<script>
(function () {{
  var T = JSON.parse(document.getElementById('i18n').textContent);
  var sel = document.getElementById('lang');
  function show(code) {{
    var t = T[code]; if (!t) return;
    document.documentElement.lang = code;
    document.documentElement.dir = t.dir;
    document.title = 'PulseScore \\u2014 ' + t.title;
    document.getElementById('tagline').textContent = t.tagline;
    document.getElementById('self').textContent = t.title;
    document.getElementById('other').textContent = t.other;
    document.getElementById('title').textContent = t.title;
    document.getElementById('updated').textContent = t.updated;
    document.getElementById('summary').textContent = t.summary;
    document.getElementById('body').innerHTML = t.body;
    document.getElementById('picklabel').textContent = t.pick;
    sel.value = code;
    try {{ localStorage.setItem('ps_lang', code); }} catch (e) {{}}
  }}
  var q = new URLSearchParams(location.search).get('lang');
  var stored = null;
  try {{ stored = localStorage.getItem('ps_lang'); }} catch (e) {{}}
  var want = (q || stored || navigator.language || 'en').slice(0, 2).toLowerCase();
  if (T[want] && want !== 'en') show(want); else sel.value = 'en';
  sel.addEventListener('change', function () {{
    show(sel.value);
    // Keep the language in the URL so the page can be shared or reloaded.
    history.replaceState(null, '', location.pathname + '?lang=' + sel.value);
  }});
}})();
</script>
</body>
</html>
""", encoding="utf-8")

    (DIST / "index.html").write_text("""<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>PulseScore — Legal</title>
<meta http-equiv="refresh" content="0;url=/privacy.html">
</head><body><p><a href="/privacy.html">Privacy Policy</a> ·
<a href="/terms.html">Terms of Service</a></p></body></html>
""", encoding="utf-8")

    total = sum(len(p.read_text(encoding="utf-8")) for p in DIST.rglob("*") if p.is_file())
    print(f"wrote {len(list(DIST.rglob('*')))} files, {total} bytes")


if __name__ == "__main__":
    main()
