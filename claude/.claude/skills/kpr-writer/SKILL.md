---
name: kpr-writer
description: "Write/update KPR (個人目標設定表) Excel files. Triggers: KPR, goal setting, performance review, OKR mapping."
argument-hint: "Optional: focus area or update instruction (e.g., 'update goal 3 completion date')"
---

# KPR Writer (個人目標設定表)

Generate/update 年度員工考績表 spreadsheets. **First:** read `~/.secrets.json` → `kpr` key for paths.

Setup: `bash ~/.claude/skills/kpr-writer/scripts/setup.sh`

## Workflow

1. Read xlsx with openpyxl, inspect `目標設定` sheet
2. Gather evidence: `git log --author --since`, MRs, deployed services
3. Read OKR docs (Confluence .doc = MIME/HTML, extract via `quopri` + regex)
4. Draft goals table → present to user before writing
5. Write xlsx → verify weights

## Rules

- Goal weights (col C) sum to **100%**, sub-item weights (col G) per goal sum to **100%**
- Use real git dates for completed work; lead accomplished work first
- If file open in Excel, save to new path

## xlsx Structure

Row 6 = headers, row 7+ = data. Font: 微軟正黑體 12pt, centered, bordered.

| Col | Field | Merge? |
|-----|-------|--------|
| A | 目標序 | merged per goal |
| B | 目標 | merged per goal |
| C | 比重% | merged, sum=100% |
| D | 預定完成日 | merged |
| E | 工作細項 | one per row |
| F | 衡量指標 | measurable KR |
| G | 細項比重% | sum=100% per goal |
| H | 細項完成日 | one per row |

## Write Pattern

```python
source ~/work/git/venv/bin/activate && python3 << 'PYEOF'
import openpyxl
from openpyxl.styles import Font, Alignment, Border, Side
from copy import copy
from datetime import datetime

wb = openpyxl.load_workbook('<INPUT_PATH>')
ws = wb['目標設定']

# 1. Save template styles from row 7
tmpl = {}
for col in range(1, 9):
    c = ws.cell(row=7, column=col)
    tmpl[col] = {
        'font': copy(c.font), 'alignment': copy(c.alignment),
        'border': copy(c.border), 'fill': copy(c.fill),
        'number_format': c.number_format,
    }

# 2. Unmerge data-region cells (row >= 7)
for mr in [str(r) for r in ws.merged_cells.ranges if r.min_row >= 7]:
    try: ws.unmerge_cells(mr)
    except: pass

# 3. Clear old data rows
for row in range(7, <MAX_ROW+1>):
    for col in range(1, 9):
        ws.cell(row=row, column=col).value = None

# 4. Helpers
def style_cell(row, col):
    c = ws.cell(row=row, column=col)
    t = tmpl[col]
    c.font = copy(t['font']); c.alignment = copy(t['alignment'])
    c.border = copy(t['border']); c.fill = copy(t['fill'])
    c.number_format = t['number_format']

def write_row(row, a=None, b=None, c=None, d=None,
              e=None, f=None, g=None, h=None):
    for col in range(1, 9): style_cell(row, col)
    mapping = {1:a, 2:b, 3:c, 4:d, 5:e, 6:f, 7:g, 8:h}
    for col, val in mapping.items():
        if val is not None:
            ws.cell(row=row, column=col).value = val

# 5. Write goals, then merge A-D per goal span
# write_row(7, 1, 'Goal', 25, datetime(2026,6,30),
#     'Sub-item', 'KR', 50, datetime(2026,3,31))
# ws.merge_cells('A7:A8'); ws.merge_cells('B7:B8')
# ws.merge_cells('C7:C8'); ws.merge_cells('D7:D8')

wb.save('<OUTPUT_PATH>')
PYEOF
```

## OKR Doc Extraction

```python
import re, html, quopri
with open('<DOC_PATH>', 'r', encoding='utf-8') as f:
    content = f.read()
start = content.find('<html')
end = content.find('------=_Part_2', start)
html_part = content[start:end] if end > start else content[start:]
html_decoded = quopri.decodestring(html_part.encode()).decode('utf-8', errors='replace')
text = re.sub(r'<style[^>]*>.*?</style>', '', html_decoded, flags=re.DOTALL)
text = re.sub(r'<[^>]*>', ' ', text)
text = html.unescape(text)
text = re.sub(r' +', ' ', text)
text = re.sub(r'\n\s*\n', '\n', text)
```
