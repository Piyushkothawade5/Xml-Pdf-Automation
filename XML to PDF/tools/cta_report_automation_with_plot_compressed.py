#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
CTA Reports: Batch XML -> (XSLT) HTML -> PDF -> Master PDF
+ Matplotlib excitation graph injection per-XML (UCTrms vs ICTrms)

Updated version:
- Uses knee-point values directly from XML (no intersection/interpolation).
- Uses absolute XPath from the document root for knee-points.
- Injects a proper <img> tag into HTML for the excitation graph.
- Makes axes dynamic, shows the 100 µA decade when data < 1 mA,
  and adds headroom so the plot never touches borders.
- Compresses every generated individual PDF and can also compress the merged master PDF.

Compression strategy:
1) Prefer Ghostscript (best compression). If unavailable,
2) Fallback to PyPDF2 content-stream compression.
"""

import argparse
import concurrent.futures as futures
import threading
import shutil
import subprocess
import sys
import tempfile
import base64
import io
import os
import unicodedata
from pathlib import Path
from typing import Optional, Tuple, List
from lxml import etree, html as lxml_html
from PyPDF2 import PdfMerger, PdfReader, PdfWriter
import matplotlib
matplotlib.use('Agg')  # headless
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.ticker import LogLocator, FuncFormatter, NullFormatter
from math import log10, floor
import re

PLOT_LOCK = threading.Lock()
HREF_RE = re.compile(r'href\s*=\s*"([^"]+)"', re.IGNORECASE)
PLACEHOLDER_TEXT = 'Browser does not support graphics object!'

# ---------------------------------
# Utilities (paths, engines, XSLT)
# ---------------------------------

def find_stylesheet_from_pi(xml_tree: etree._ElementTree) -> Optional[str]:
    try:
        pis = xml_tree.xpath("/processing-instruction('xml-stylesheet')")
        for pi in pis:
            text = pi.text or ""
            m = HREF_RE.search(text)
            if m:
                return m.group(1).strip()
    except Exception:
        pass
    return None


def ensure_tool_on_path(tool: str) -> str:
    resolved = shutil.which(tool)
    if not resolved:
        raise FileNotFoundError(
            "Required tool '{}' not found on PATH. Install it or pass its full path.".format(tool)
        )
    return resolved


def locate_chrome(explicit_path: Optional[str]) -> Optional[str]:
    if explicit_path:
        p = Path(explicit_path)
        if p.exists():
            return str(p)

    found = (
        shutil.which("chrome")
        or shutil.which("google-chrome")
        or shutil.which("chromium")
        or shutil.which("chromium-browser")
    )
    if found:
        return found

    candidates = [
        r"C:\Program Files\Google\Chrome\Application\chrome.exe",
        r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
        r"C:\Program Files\Chromium\Application\chrome.exe",
    ]
    for c in candidates:
        if Path(c).exists():
            return c
    return None


def locate_ghostscript(explicit_path: Optional[str]) -> Optional[str]:
    if explicit_path:
        p = Path(explicit_path)
        if p.exists():
            return str(p)

    # Linux / macOS / Windows common executables
    for name in ("gs", "gswin64c", "gswin32c"):
        found = shutil.which(name)
        if found:
            return found

    win_candidates = [
        r"C:\Program Files\gs\gs10.05.1\bin\gswin64c.exe",
        r"C:\Program Files\gs\gs10.04.0\bin\gswin64c.exe",
        r"C:\Program Files\gs\gs10.03.1\bin\gswin64c.exe",
        r"C:\Program Files\gs\gs10.02.1\bin\gswin64c.exe",
        r"C:\Program Files\gs\gs10.01.2\bin\gswin64c.exe",
        r"C:\Program Files\gs\gs10.00.0\bin\gswin64c.exe",
        r"C:\Program Files\gs\gs9.56.1\bin\gswin64c.exe",
    ]
    for c in win_candidates:
        if Path(c).exists():
            return c
    return None


def transform_xml_to_html(xml_path: Path, xsl_path: Path, normalize_unicode: bool = True) -> bytes:
    xml_tree = etree.parse(str(xml_path))
    xsl_tree = etree.parse(str(xsl_path))
    transform = etree.XSLT(xsl_tree)
    result = transform(xml_tree)
    html_bytes = etree.tostring(result, pretty_print=True, method='html', encoding='utf-8')

    if normalize_unicode:
        try:
            text = html_bytes.decode('utf-8', errors='replace')
            text_nfkc = unicodedata.normalize('NFKC', text)
            html_bytes = text_nfkc.encode('utf-8')
        except Exception:
            pass
    return html_bytes


def html_to_pdf_chrome(html_path: Path, pdf_out: Path, chrome_path: str) -> Tuple[bool, str]:
    cmd = [
        chrome_path,
        '--headless',
        '--disable-gpu',
        '--no-sandbox',
        '--print-to-pdf={}'.format(str(pdf_out)),
        str(html_path.as_uri())
    ]
    try:
        res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        if res.returncode != 0 or not pdf_out.exists():
            return False, res.stderr or 'chrome headless failed without stderr.'
        return True, 'ok'
    except Exception as e:
        return False, str(e)


def html_to_pdf_wkhtmltopdf(html_path: Path, pdf_out: Path, wkhtmltopdf_cmd: str) -> Tuple[bool, str]:
    cmd = [
        wkhtmltopdf_cmd,
        '--enable-local-file-access',
        '--encoding', 'utf-8',
        '--quiet',
        str(html_path),
        str(pdf_out)
    ]
    try:
        res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        if res.returncode != 0 or not pdf_out.exists():
            return False, res.stderr or 'wkhtmltopdf failed without stderr.'
        return True, 'ok'
    except Exception as e:
        return False, str(e)


# ---------------------------------
# PDF compression
# ---------------------------------

GS_PRESET_MAP = {
    'screen': '/screen',
    'ebook': '/ebook',
    'printer': '/printer',
    'prepress': '/prepress',
    'default': '/default',
}


def _file_size(path: Path) -> int:
    try:
        return path.stat().st_size
    except Exception:
        return -1


def compress_pdf_ghostscript(pdf_in: Path, pdf_out: Path, gs_cmd: str, preset: str = 'ebook') -> Tuple[bool, str]:
    preset = GS_PRESET_MAP.get((preset or 'ebook').lower(), '/ebook')
    cmd = [
        gs_cmd,
        '-sDEVICE=pdfwrite',
        '-dCompatibilityLevel=1.4',
        f'-dPDFSETTINGS={preset}',
        '-dNOPAUSE',
        '-dQUIET',
        '-dBATCH',
        '-dDetectDuplicateImages=true',
        '-dCompressFonts=true',
        '-dSubsetFonts=true',
        f'-sOutputFile={str(pdf_out)}',
        str(pdf_in),
    ]
    try:
        res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        if res.returncode != 0 or not pdf_out.exists():
            return False, res.stderr or 'Ghostscript compression failed.'
        return True, 'compressed with Ghostscript'
    except Exception as e:
        return False, str(e)


def compress_pdf_pypdf2(pdf_in: Path, pdf_out: Path) -> Tuple[bool, str]:
    """
    Fallback compression: re-write pages and compress page content streams.
    This usually helps with vector/text streams, but is not as aggressive as Ghostscript.
    """
    try:
        reader = PdfReader(str(pdf_in))
        writer = PdfWriter()
        for page in reader.pages:
            try:
                page.compress_content_streams()
            except Exception:
                pass
            writer.add_page(page)

        # Preserve metadata when possible
        try:
            if reader.metadata:
                writer.add_metadata({k: str(v) for k, v in reader.metadata.items() if k and v is not None})
        except Exception:
            pass

        with open(pdf_out, 'wb') as f:
            writer.write(f)
        return True, 'compressed with PyPDF2 fallback'
    except Exception as e:
        return False, str(e)


def compress_pdf_in_place(pdf_path: Path, gs_cmd: Optional[str], preset: str = 'ebook', keep_larger: bool = True) -> Tuple[bool, str]:
    """
    Compress pdf_path into a temporary PDF and replace original if successful.
    If keep_larger=True and the compressed PDF is larger, keep original.
    """
    if not pdf_path.exists():
        return False, f'PDF not found: {pdf_path}'

    original_size = _file_size(pdf_path)
    tmp_out = pdf_path.with_name(pdf_path.stem + '.__compressed__.pdf')
    try:
        ok = False
        msg = ''

        if gs_cmd:
            ok, msg = compress_pdf_ghostscript(pdf_path, tmp_out, gs_cmd, preset=preset)
            if not ok and tmp_out.exists():
                try:
                    tmp_out.unlink()
                except Exception:
                    pass

        if not ok:
            ok, msg = compress_pdf_pypdf2(pdf_path, tmp_out)

        if not ok or not tmp_out.exists():
            return False, f'compression failed: {msg}'

        new_size = _file_size(tmp_out)
        if keep_larger and original_size > 0 and new_size >= original_size:
            try:
                tmp_out.unlink()
            except Exception:
                pass
            return True, f'skipped replacement (compressed file not smaller: {original_size} -> {new_size} bytes)'

        os.replace(str(tmp_out), str(pdf_path))
        final_size = _file_size(pdf_path)
        return True, f'{msg}; size {original_size} -> {final_size} bytes'
    except Exception as e:
        try:
            if tmp_out.exists():
                tmp_out.unlink()
        except Exception:
            pass
        return False, str(e)


# ---------------------------------
# Matplotlib plot (vendor-style)
# ---------------------------------
UNIT_SCALE = {
    '': 1.0,
    'v': 1.0,
    'a': 1.0,
    'mv': 1e-3,
    'ma': 1e-3,
    'uv': 1e-6,
    'ua': 1e-6,
    'µv': 1e-6,
    'µa': 1e-6,
    'μv': 1e-6,
    'μa': 1e-6,
}

NUM_UNIT_RE = re.compile(
    r'^\s*([+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?)\s*([a-zA-Zµμ]*)\s*$'
)


def _clean_token(s: str) -> str:
    t = (s or '').replace('\u00A0', ' ')
    t = t.strip().replace(',', '')
    t = re.sub(r'\s+', ' ', t)
    return t


def _parse_value(s: str, assume_unit: str = '') -> float:
    t = _clean_token(s)
    if not t:
        raise ValueError('Empty token')
    m = NUM_UNIT_RE.match(t)
    if not m:
        raise ValueError("Cannot parse token: '{}' -> '{}'".format(s, t))
    val = float(m.group(1))
    unit = (m.group(2) or '').strip().lower()
    if not unit:
        unit = assume_unit
    scale = UNIT_SCALE.get(unit, 1.0)
    return val * scale


def _floor_125(x: float) -> float:
    n = floor(log10(x))
    base = 10 ** n
    for s in (5, 2, 1):
        if s * base <= x:
            return s * base
    return base


def _ceil_125(x: float) -> float:
    n = floor(log10(x))
    for s in (1, 2, 5):
        val = s * (10 ** n)
        if val >= x:
            return val
    return 10 ** (n + 1)


def _snap_limits_125(xmin: float, xmax: float):
    xmin = max(xmin, 1e-30)
    lo = _floor_125(xmin)
    hi = _ceil_125(max(xmax, xmin * 1.001))
    if not (hi > lo):
        lo /= 10.0
        hi *= 10.0
    return lo, hi


def _mantissa(x: float) -> float:
    if x <= 0:
        return 0.0
    return x / (10 ** floor(log10(x)))


def _x_formatter_factory(mode: str):
    """
    Return (major, minor) tick formatters for log-scale X.
    Modes:
      - 'dense'   -> label 1, 2, 5 per decade
      - 'normal'  -> label 1, 5 per decade
      - 'minimal' -> label only the 1 per decade (default)
    Labels use engineering units: µ (micro), m (milli), plain A >= 1.
    """
    mode = (mode or 'minimal').lower()

    def _si_label(val: float) -> str:
        if val < 1e-3:  # < 1 mA => µA
            n = val * 1e6
            return f"{n:.0f}µ" if n >= 1 else f"{n:.1f}µ"
        elif val < 1:   # 1 mA .. 1 A => mA
            n = val * 1e3
            return f"{n:.0f}m" if n >= 1 else f"{n:.1f}m"
        else:
            return f"{val:.0f}" if val >= 1 else f"{val:.3g}"

    def fmt(x, _pos):
        if x <= 0:
            return ''
        m = _mantissa(x)
        if abs(m - 1.0) < 1e-6:
            return _si_label(x)
        if mode == 'dense' and (abs(m - 2.0) < 1e-6 or abs(m - 5.0) < 1e-6):
            return _si_label(x)
        if mode == 'normal' and abs(m - 5.0) < 1e-6:
            return _si_label(x)
        return ''

    major = FuncFormatter(fmt)
    minor = NullFormatter()
    return major, minor


def _y_formatter():
    def fmt(y, _pos):
        return '' if y <= 0 else '{:.4g}'.format(y)
    return FuncFormatter(fmt)


def _y_minor_formatter_2_5():
    """Label Y-axis minor ticks at mantissas 2 and 5 on log scale."""
    def fmt(y, _pos):
        if y <= 0:
            return ''
        m = _mantissa(y)
        if abs(m - 2.0) < 1e-6 or abs(m - 5.0) < 1e-6:
            return '{:.4g}'.format(y)
        return ''
    return FuncFormatter(fmt)


def build_excitation_plot_png(
    rows: List[tuple],
    kneepoint: Optional[Tuple[float, float]] = None,  # (Vk, Ik) in SI units
    overhang: float = 1.08,
    figsize_px: int = 560,
    title: str = 'Excitation Table:',
    x_label_style: str = 'vendor',   # 'vendor' -> 'I/V', 'classic' -> 'I [A]'
    x_ticks_mode: str = 'minimal',   # dense | normal | minimal
) -> bytes:
    """Build excitation plot PNG. If kneepoint is provided, draw dashed lines."""
    V_vals, I_vals = [], []
    for v_str, i_str in rows:
        try:
            v = _parse_value(v_str, assume_unit='v')
            i = _parse_value(i_str, assume_unit='a')
            if v > 0 and i > 0:
                V_vals.append(float(v))
                I_vals.append(float(i))
        except Exception:
            continue

    if not V_vals or not I_vals:
        raise RuntimeError('No valid V/I rows for plotting.')

    V = np.array(V_vals, float)
    I = np.array(I_vals, float)

    order = np.argsort(I)
    I, V = I[order], V[order]

    xmin_raw, xmax_raw = float(np.min(I)), float(np.max(I))
    ymin_raw, ymax_raw = float(np.min(V)), float(np.max(V))

    Vk = Ik = None
    if kneepoint is not None:
        Vk, Ik = kneepoint
        if Ik is not None and Ik > 0:
            xmin_raw, xmax_raw = min(xmin_raw, Ik), max(xmax_raw, Ik)
        if Vk is not None and Vk > 0:
            ymin_raw, ymax_raw = min(ymin_raw, Vk), max(ymax_raw, Vk)

    x_lo, x_hi = _snap_limits_125(xmin_raw, xmax_raw)
    y_lo, y_hi = _snap_limits_125(ymin_raw, ymax_raw)

    if xmin_raw < 1e-3:
        x_lo = min(x_lo, 1e-4)

    y_hi *= 1.20
    if (Vk is not None) and (Vk > 0) and (Vk >= 0.98 * y_hi):
        y_hi = Vk * 1.08

    Ix_end = min(Ik * overhang, x_hi) if (Ik is not None and Ik > 0) else None
    Vy_end = min(Vk * overhang, y_hi) if (Vk is not None and Vk > 0) else None

    dpi = 100
    size_in = figsize_px / dpi
    fig = plt.figure(figsize=(size_in, size_in), dpi=dpi)
    ax = fig.add_subplot(111)
    ax.set_box_aspect(1)

    CURVE_COLOR = 'dimgray'
    REF_COLOR = '#0d0d7f'
    REF_LW = 1
    REF_DASH = (0, (14, 6))
    AXIS_SPINE_COLOR = '#4e4e4e'
    AXIS_SPINE_LW = 1.0
    GRID_MAJOR_COLOR = '#d2d2d2'
    GRID_MINOR_COLOR = '#d1d1d1'
    GRID_MAJOR_LW = 1.0
    GRID_MINOR_LW = 0.8

    ax.loglog(I, V, '-', color=CURVE_COLOR, linewidth=1)

    if Vk is not None and Vk > 0:
        ax.plot([x_lo, Ix_end if Ix_end else x_hi], [Vk, Vk], color=REF_COLOR, linewidth=REF_LW, linestyle=REF_DASH)
    if Ik is not None and Ik > 0:
        ax.plot([Ik, Ik], [y_lo, Vy_end if Vy_end else y_hi], color=REF_COLOR, linewidth=REF_LW, linestyle=REF_DASH)

    ax.xaxis.set_major_locator(LogLocator(base=10.0))
    ax.xaxis.set_minor_locator(LogLocator(base=10.0, subs=(2, 5), numticks=100))
    x_major_fmt, x_minor_fmt = _x_formatter_factory(x_ticks_mode)
    ax.xaxis.set_major_formatter(x_major_fmt)
    ax.xaxis.set_minor_formatter(x_minor_fmt)

    ax.yaxis.set_major_locator(LogLocator(base=10.0))
    ax.yaxis.set_minor_locator(LogLocator(base=10.0, subs=(2, 5), numticks=100))
    ax.yaxis.set_major_formatter(_y_formatter())
    ax.yaxis.set_minor_formatter(_y_minor_formatter_2_5())

    ax.grid(which='major', color=GRID_MAJOR_COLOR, linestyle='-', linewidth=GRID_MAJOR_LW)
    ax.grid(which='minor', color=GRID_MINOR_COLOR, linestyle='-', linewidth=GRID_MINOR_LW, alpha=0.95)

    for side in ('top', 'right'):
        ax.spines[side].set_visible(False)
    for side in ('bottom', 'left'):
        ax.spines[side].set_visible(True)
        ax.spines[side].set_color(AXIS_SPINE_COLOR)
        ax.spines[side].set_linewidth(AXIS_SPINE_LW)

    ax.set_xlabel('')
    ax.set_ylabel('')
    if (x_label_style or '').lower() == 'classic':
        x_label_text = 'I [A]'
        y_label_text = 'U [V]'
    else:
        x_label_text = 'I/V'
        y_label_text = 'V/V'

    ax.annotate(y_label_text, xy=(0.0, 1.0), xytext=(0.0, 1.02),
                xycoords='axes fraction', textcoords='axes fraction',
                ha='left', va='bottom', fontsize=9, clip_on=False)
    ax.annotate(x_label_text, xy=(1.0, 0.0), xytext=(1.01, -0.035),
                xycoords='axes fraction', textcoords='axes fraction',
                ha='left', va='top', fontsize=9, clip_on=False)

    ax.set_xlim(x_lo, x_hi)
    ax.set_ylim(y_lo, y_hi)
    ax.tick_params(axis='x', labelsize=8, pad=2)
    ax.tick_params(axis='y', labelsize=8, pad=2)

    for lbl in ax.get_yticklabels(minor=False):
        lbl.set_fontsize(8)
        lbl.set_fontweight('bold')
    for lbl in ax.get_yticklabels(minor=True):
        lbl.set_fontsize(8)
        lbl.set_fontweight('bold')
    for lbl in ax.get_xticklabels(minor=False):
        lbl.set_fontsize(8)
        lbl.set_fontweight('bold')
    for lbl in ax.get_xticklabels(minor=True):
        lbl.set_fontsize(8)
        lbl.set_fontweight('bold')

    plt.tight_layout(pad=0.8)
    buf = io.BytesIO()
    fig.savefig(buf, format='png', dpi=dpi)
    plt.close(fig)
    return buf.getvalue()


# ---------------------------------
# Data extractors (XML / HTML)
# ---------------------------------

def extract_excitation_rows_from_html(html_text: str) -> List[tuple]:
    HEADER_PATTERNS_V = (
        r'^\s*v\s*$',
        r'^\s*v\s*\[\s*v\s*\]\s*$',
        r'^\s*(v|u|voltage)\b.*$'
    )
    HEADER_PATTERNS_I = (
        r'^\s*i\s*$',
        r'^\s*i\s*\[\s*a\s*\]\s*$',
        r'^\s*(i|current)\b.*$'
    )

    def _match_any(patterns, text):
        t = (text or '').strip().lower()
        return any(re.match(p, t) for p in patterns)

    doc = lxml_html.fromstring(html_text)
    candidates = []
    for el in doc.xpath('//table'):
        header_cells = el.xpath('.//tr[1]/*')
        headers = [re.sub(r'\s+', ' ', (h.text_content() or '')).strip() for h in header_cells]
        if not headers:
            continue
        v_idx = i_idx = None
        for idx, h in enumerate(headers):
            if v_idx is None and _match_any(HEADER_PATTERNS_V, h):
                v_idx = idx
            if i_idx is None and _match_any(HEADER_PATTERNS_I, h):
                i_idx = idx
        if v_idx is not None and i_idx is not None:
            anc_text = ' '.join(a.text_content().lower() for a in el.iterancestors())
            weight = 0 if ('excitation' in anc_text or 'excitation table' in anc_text) else 1
            candidates.append((weight, el, v_idx, i_idx))

    if not candidates:
        return []

    candidates.sort(key=lambda t: t[0])
    _, table, v_idx, i_idx = candidates[0]
    rows = []
    for tr in table.xpath('.//tr[position()>1]'):
        cells = tr.xpath('./td')
        if len(cells) >= max(v_idx, i_idx) + 1:
            v_txt = cells[v_idx].text_content().strip()
            i_txt = cells[i_idx].text_content().strip()
            if v_txt and i_txt:
                rows.append((v_txt, i_txt))
    return rows


def extract_excitation_rows_from_xml(xml_path: Path, v_field: str = 'UCTrms') -> List[tuple]:
    tree = etree.parse(str(xml_path))
    pts = tree.xpath('/Object/Tests/Cards/Excitation/Measurements/MeasPoints/MeasPoint')
    rows = []
    for mp in pts:
        v_nodes = mp.xpath(f'{v_field}/Val')
        i_nodes = mp.xpath('ICTrms/Val')
        if not v_nodes or not i_nodes:
            continue
        try:
            v = float(v_nodes[0].text)
            i = float(i_nodes[0].text)
            if v > 0 and i > 0:
                rows.append(("{:.12g}V".format(v), "{:.12g}A".format(i)))
        except Exception:
            continue
    return rows


# ---- Robust knee-point helpers ----

def _normalize_standard_name(name: Optional[str]) -> Optional[str]:
    if not name:
        return None
    t = name.strip().upper().replace(' ', '').replace('-', '_')
    mapping = {
        '61869_2': 'IEC_69_2',
        'IEC61869_2': 'IEC_69_2',
        'IEC_61869_2': 'IEC_69_2',
        'IEC69_2': 'IEC_69_2',
        'IEC_69_2': 'IEC_69_2',
        'IEC1': 'IEC_1',
        'IEC_1': 'IEC_1',
        'IEC6': 'IEC_6',
        'IEC_6': 'IEC_6',
        'ANSI30': 'ANSI_30',
        'ANSI_30': 'ANSI_30',
        'ANSI45': 'ANSI_45',
        'ANSI_45': 'ANSI_45',
    }
    return mapping.get(t, t)


def _read_standard_from_xml(xml_path: Path) -> Optional[str]:
    try:
        tree = etree.parse(str(xml_path))
        nodes = tree.xpath('/Object/TestObject/Standard')
        if not nodes:
            return None
        raw = (nodes[0].text or '').strip()
        raw_norm = raw.replace(' ', '').upper()
        if raw_norm in ('61869-2', 'IEC61869-2', 'IEC-61869-2'):
            return 'IEC_69_2'
        return _normalize_standard_name(raw)
    except Exception:
        return None


def get_kneepoint_pair(xml_path: Path, standard: Optional[str] = 'IEC_69_2') -> Optional[Tuple[float, float]]:
    try:
        std = _normalize_standard_name(standard) if standard else None
        if not std:
            std = _read_standard_from_xml(xml_path) or 'IEC_69_2'

        tree = etree.parse(str(xml_path))
        u_nodes = tree.xpath(f'/Object/Tests/Cards/Excitation/Measurements/KneePoints/{std}/U/Val')
        i_nodes = tree.xpath(f'/Object/Tests/Cards/Excitation/Measurements/KneePoints/{std}/I/Val')

        if not u_nodes or not i_nodes:
            u_nodes = tree.xpath('/Object/Tests/Cards/Excitation/Measurements/KneePoints/IEC_69_2/U/Val')
            i_nodes = tree.xpath('/Object/Tests/Cards/Excitation/Measurements/KneePoints/IEC_69_2/I/Val')
        if not u_nodes or not i_nodes:
            return None

        v = float((u_nodes[0].text or '').strip())
        i = float((i_nodes[0].text or '').strip())
        if v > 0 and i > 0:
            return (v, i)
        return None
    except Exception:
        return None


# ---------------------------------
# HTML injection helper (proper <img>)
# ---------------------------------

def inject_plot_into_html(html_text: str, img_png_bytes: bytes, target_section_hint: str = 'excitation') -> str:
    b64 = base64.b64encode(img_png_bytes).decode('ascii')
    img_tag = (
        f'<div class="excitation-plot" style="margin:12px 0; text-align:center;">'
        f'<img src="data:image/png;base64,{b64}" alt="Excitation graph" '
        f'style="max-width:100%; height:auto;"/>'
        f'</div>'
    )

    doc = lxml_html.fromstring(html_text)
    placeholders = doc.xpath(
        "//*[contains(normalize-space(text()), '{}')]".format(PLACEHOLDER_TEXT)
    )

    if not placeholders:
        for el in doc.iter():
            try:
                if PLACEHOLDER_TEXT in (el.text_content() or ''):
                    placeholders.append(el)
            except Exception:
                pass

    if not placeholders:
        return html_text

    chosen = None
    hint = (target_section_hint or '').lower()
    for el in placeholders:
        anc_text = ' '.join(a.text_content().lower() for a in el.iterancestors())
        if hint and hint in anc_text:
            chosen = el
            break
    if chosen is None:
        chosen = placeholders[0]

    repl_html = lxml_html.fragment_fromstring(img_tag)
    parent = chosen.getparent()
    if parent is None:
        return html_text
    parent.replace(chosen, repl_html)

    return lxml_html.tostring(
        doc, encoding='utf-8', pretty_print=True, method='html'
    ).decode('utf-8', errors='replace')


# ---------------------------------
# Per-XML processing
# ---------------------------------

def process_one_xml(
    xml_path: Path,
    out_dir: Path,
    override_xsl: Optional[Path],
    engine: str,
    wkhtmltopdf_cmd: Optional[str],
    chrome_path: Optional[str],
    force: bool,
    tmp_dir: Optional[Path],
    normalize_unicode: bool = True,
    inject_excitation_plot: bool = True,
    excitation_source: str = 'xml',
    excitation_v: str = 'UCTrms',
    vref_source: str = 'xml',
    kneepoint_standard: str = 'IEC_69_2',
    force_kneepoint: Optional[Tuple[float, float]] = None,
    debug_dump_html: bool = False,
    axis_labels: str = 'vendor',
    x_ticks_mode: str = 'minimal',
    compress_pdfs: bool = True,
    gs_cmd: Optional[str] = None,
    compression_preset: str = 'ebook',
) -> Tuple[Path, bool, str]:
    """Build HTML via XSLT, optionally inject plot, convert to PDF, then compress it."""
    try:
        out_dir.mkdir(parents=True, exist_ok=True)
        pdf_out = out_dir / xml_path.with_suffix('.pdf').name
        if pdf_out.exists() and not force:
            return pdf_out, True, 'skipped (exists)'

        xml_tree = etree.parse(str(xml_path))
        xsl_path = override_xsl
        if not xsl_path:
            href = find_stylesheet_from_pi(xml_tree)
            if href:
                cand = (xml_path.parent / href).resolve()
                if cand.exists():
                    xsl_path = cand
                else:
                    alt = Path(href).resolve()
                    if alt.exists():
                        xsl_path = alt
        if not xsl_path or not xsl_path.exists():
            return pdf_out, False, 'XSL not found for {}. Provide --xsl or place XSL next to the XML.'.format(xml_path.name)

        html_bytes = transform_xml_to_html(xml_path, xsl_path, normalize_unicode=normalize_unicode)
        html_text = html_bytes.decode('utf-8', errors='replace')

        if inject_excitation_plot:
            try:
                if excitation_source == 'xml':
                    rows = extract_excitation_rows_from_xml(xml_path, v_field=excitation_v)
                else:
                    rows = extract_excitation_rows_from_html(html_text)

                knee_tuple = None
                if force_kneepoint is not None:
                    knee_tuple = force_kneepoint
                    print(f'[INFO] {xml_path.name}: using forced knee-point Vk={knee_tuple[0]:.6g} V, Ik={knee_tuple[1]:.6g} A')
                elif vref_source == 'xml':
                    knee_tuple = get_kneepoint_pair(xml_path, kneepoint_standard)
                    if knee_tuple:
                        print(f'[INFO] {xml_path.name}: knee-point from XML ({kneepoint_standard}) -> Vk={knee_tuple[0]:.6g} V, Ik={knee_tuple[1]:.6g} A')
                    else:
                        print(f'[WARN] {xml_path.name}: knee-point NOT found for standard {kneepoint_standard}; plotting without dashed lines.')
                else:
                    print(f'[INFO] {xml_path.name}: vref_source=auto -> plotting without dashed lines.')

                if rows:
                    png_bytes = None
                    for attempt in range(2):
                        try:
                            with PLOT_LOCK:
                                png_bytes = build_excitation_plot_png(
                                    rows,
                                    kneepoint=knee_tuple,
                                    title='Excitation Table:',
                                    x_label_style=axis_labels,
                                    x_ticks_mode=x_ticks_mode,
                                )
                            break
                        except Exception as ex:
                            if attempt == 1:
                                print(f'[WARN] {xml_path.name}: plot generation failed after retry: {ex}')
                    if png_bytes:
                        html_text = inject_plot_into_html(
                            html_text,
                            png_bytes,
                            target_section_hint='excitation'
                        )
            except Exception as ex:
                print('[WARN] Plot injection failed for {}: {}'.format(xml_path.name, ex))

        if debug_dump_html:
            debug_path = out_dir / (xml_path.stem + '_DEBUG.html')
            try:
                debug_path.write_text(html_text, encoding='utf-8')
            except Exception:
                pass

        work_dir = tmp_dir or Path(tempfile.mkdtemp(prefix='cta_xml2pdf_'))
        work_dir.mkdir(parents=True, exist_ok=True)
        html_path = work_dir / (xml_path.stem + '.html')
        html_path.write_text(html_text, encoding='utf-8')

        if engine == 'chrome':
            if not chrome_path:
                return pdf_out, False, 'Chrome/Chromium not found. Install or use --engine wkhtmltopdf.'
            ok, msg = html_to_pdf_chrome(html_path, pdf_out, chrome_path)
        else:
            if not wkhtmltopdf_cmd:
                return pdf_out, False, 'wkhtmltopdf not found. Install or use --engine chrome.'
            ok, msg = html_to_pdf_wkhtmltopdf(html_path, pdf_out, wkhtmltopdf_cmd)

        if not ok:
            return pdf_out, False, msg

        if compress_pdfs and pdf_out.exists():
            c_ok, c_msg = compress_pdf_in_place(pdf_out, gs_cmd=gs_cmd, preset=compression_preset)
            if c_ok:
                msg = f'{msg}; {c_msg}'
            else:
                msg = f'{msg}; compression warning: {c_msg}'

        return pdf_out, True, msg
    except Exception as e:
        return Path(''), False, 'Exception: {}'.format(e)


# ---------------------------------
# Merge PDFs
# ---------------------------------

def merge_pdfs(pdf_paths: List[Path], master_pdf_path: Path) -> Tuple[bool, str]:
    try:
        merger = PdfMerger(strict=False)
        for p in pdf_paths:
            if p.exists():
                merger.append(str(p))
        master_pdf_path.parent.mkdir(parents=True, exist_ok=True)
        merger.write(str(master_pdf_path))
        merger.close()
        return True, 'merged'
    except Exception as e:
        return False, str(e)


# ---------------------------------
# CLI
# ---------------------------------

def _parse_forced_kneepoint(text: Optional[str]) -> Optional[Tuple[float, float]]:
    if not text:
        return None
    try:
        parts = [t.strip() for t in text.split(',')]
        if len(parts) != 2:
            raise ValueError
        vk = float(parts[0])
        ik = float(parts[1])
        if vk > 0 and ik > 0:
            return (vk, ik)
    except Exception:
        pass
    raise argparse.ArgumentTypeError("Expected '--force-kneepoint Vk,Ik' e.g., 3.797,0.04609")


def main():
    parser = argparse.ArgumentParser(
        description='CTA XML -> XSLT HTML -> PDF (batch) -> Master PDF (+ Excitation plot with XML knee-point, + PDF compression)'
    )
    parser.add_argument('--xml-dir', required=True, help='Folder containing XML files.')
    parser.add_argument('--out-dir', required=True, help='Folder to write individual PDFs.')
    parser.add_argument('--master-pdf', required=True, help='Output path for merged Master PDF.')
    parser.add_argument('--xsl', help='Optional XSL file to apply to ALL XMLs (override PI).')
    parser.add_argument('--pattern', default='*.xml', help='Glob for XMLs (default: *.xml).')
    parser.add_argument('--engine', choices=['chrome', 'wkhtmltopdf'], default='chrome', help='PDF engine (default: chrome).')
    parser.add_argument('--chrome', help='Full path to Chrome/Chromium (optional).')
    parser.add_argument('--wkhtmltopdf', default='wkhtmltopdf', help='wkhtmltopdf command or full path.')
    parser.add_argument('--workers', type=int, default=4, help='Parallel workers (default: 4).')
    parser.add_argument('--force', action='store_true', help='Rebuild PDFs even if they exist.')
    parser.add_argument('--no-unicode-normalize', action='store_true', help='Disable Unicode NFKC normalization on generated HTML.')

    # Plotting / data-source controls
    parser.add_argument('--no-excitation-plot', action='store_true', help='Disable Excitation plot injection (default: enabled).')
    parser.add_argument('--excitation-source', choices=['xml', 'html'], default='xml', help='Where to read Excitation V/I from (default: xml).')
    parser.add_argument('--excitation-v', choices=['UCTrms', 'UCorerms', 'UCTrect'], default='UCTrms', help='Which voltage field for Y-axis (default: UCTrms).')
    parser.add_argument('--vref-source', choices=['xml', 'auto'], default='xml', help='Use knee-point from XML (default) or omit it (auto).')
    parser.add_argument('--kneepoint-standard', choices=['IEC_69_2', 'IEC_1', 'IEC_6', 'ANSI_30', 'ANSI_45'], default='IEC_69_2', help='Which knee-point standard to use when --vref-source=xml.')
    parser.add_argument('--force-kneepoint', type=_parse_forced_kneepoint, default=None, help='Force a specific knee-point Vk,Ik (e.g., "3.797,0.04609").')
    parser.add_argument('--axis-labels', choices=['vendor', 'classic'], default='vendor', help="'vendor' => X:'I/V', Y:'V/V'; 'classic' => X:'I [A]', Y:'U [V]'.")
    parser.add_argument('--x-ticks', choices=['dense', 'normal', 'minimal'], default='minimal', help='X tick label density on log scale. minimal (default) = label only 1 per decade.')

    # Compression controls
    parser.add_argument('--no-compress-pdf', action='store_true', help='Disable compression for each generated individual PDF.')
    parser.add_argument('--compress-master-pdf', action='store_true', help='Also compress the merged master PDF after merge.')
    parser.add_argument('--gs', help='Full path to Ghostscript executable (optional). If omitted, auto-detect is used.')
    parser.add_argument('--pdf-compression', choices=['screen', 'ebook', 'printer', 'prepress', 'default'], default='ebook', help='Ghostscript PDFSETTINGS preset. ebook = good balance of quality/size (default).')

    # Debug helpers
    parser.add_argument('--debug-dump-html', action='store_true', help='Dump post-injection HTML to out-dir.')
    parser.add_argument('--debug-first-only', action='store_true', help='Process only first XML (quick debug).')

    args = parser.parse_args()

    xml_dir = Path(args.xml_dir).resolve()
    out_dir = Path(args.out_dir).resolve()
    master_pdf = Path(args.master_pdf).resolve()
    override_xsl = Path(args.xsl).resolve() if args.xsl else None

    if not xml_dir.exists():
        print('[ERROR] XML directory not found: {}'.format(xml_dir))
        sys.exit(2)
    if override_xsl and not override_xsl.exists():
        print('[ERROR] XSL not found: {}'.format(override_xsl))
        sys.exit(2)

    chrome_path = None
    wkhtmltopdf_cmd = None
    gs_cmd = locate_ghostscript(args.gs)
    if args.engine == 'chrome':
        chrome_path = locate_chrome(args.chrome)
        if not chrome_path:
            print('[WARN] Chrome/Chromium not found. You can pass --chrome or install Chrome.')
    else:
        try:
            wkhtmltopdf_cmd = ensure_tool_on_path(args.wkhtmltopdf)
        except FileNotFoundError as e:
            print('[WARN] {}'.format(e))

    if gs_cmd:
        print(f'[INFO] Ghostscript detected for PDF compression: {gs_cmd}')
    else:
        print('[WARN] Ghostscript not found. Falling back to PyPDF2 compression (smaller gains).')

    xml_files = sorted(xml_dir.glob(args.pattern))
    if not xml_files:
        print('[INFO] No XML files found.')
        sys.exit(0)

    if args.debug_first_only and xml_files:
        xml_files = [xml_files[0]]

    print('[INFO] Found {} XML files. Engine: {}. Converting with {} workers...'.format(
        len(xml_files), args.engine, args.workers
    ))

    results = []
    tmp_dir = Path(tempfile.mkdtemp(prefix='cta_batch_tmp_'))
    try:
        with futures.ThreadPoolExecutor(max_workers=args.workers) as ex:
            jobs = []
            for x in xml_files:
                jobs.append(
                    ex.submit(
                        process_one_xml,
                        xml_path=x,
                        out_dir=out_dir,
                        override_xsl=override_xsl,
                        engine=args.engine,
                        wkhtmltopdf_cmd=wkhtmltopdf_cmd,
                        chrome_path=chrome_path,
                        force=args.force,
                        tmp_dir=tmp_dir,
                        normalize_unicode=(not args.no_unicode_normalize),
                        inject_excitation_plot=(not args.no_excitation_plot),
                        excitation_source=args.excitation_source,
                        excitation_v=args.excitation_v,
                        vref_source=args.vref_source,
                        kneepoint_standard=args.kneepoint_standard,
                        force_kneepoint=args.force_kneepoint,
                        debug_dump_html=args.debug_dump_html,
                        axis_labels=args.axis_labels,
                        x_ticks_mode=args.x_ticks,
                        compress_pdfs=(not args.no_compress_pdf),
                        gs_cmd=gs_cmd,
                        compression_preset=args.pdf_compression,
                    )
                )
            for j in futures.as_completed(jobs):
                results.append(j.result())
    finally:
        try:
            shutil.rmtree(tmp_dir, ignore_errors=True)
        except Exception:
            pass

    success_pdfs = [p for (p, ok, _) in results if ok and p]
    failures = [(p, msg) for (p, ok, msg) in results if not ok]

    print('[SUMMARY] Converted OK: {}'.format(len(success_pdfs)))
    print('Failed: {}'.format(len(failures)))
    for p, msg in failures:
        print('[FAIL] {}: {}'.format(p, msg))

    if not success_pdfs:
        print('[ERROR] No PDFs to merge. Exiting.')
        sys.exit(1)

    pdf_order = []
    by_name = {p.name: p for p in success_pdfs}
    for x in xml_files:
        name = x.with_suffix('.pdf').name
        if name in by_name:
            pdf_order.append(by_name[name])

    ok, msg = merge_pdfs(pdf_order, master_pdf)
    if ok:
        print('[DONE] Master PDF created: {}'.format(master_pdf))

        if args.compress_master_pdf and master_pdf.exists():
            c_ok, c_msg = compress_pdf_in_place(master_pdf, gs_cmd=gs_cmd, preset=args.pdf_compression)
            if c_ok:
                print(f'[DONE] Master PDF compressed: {c_msg}')
            else:
                print(f'[WARN] Master PDF compression skipped/failed: {c_msg}')

        # Original cleanup behavior preserved
        for x in xml_files:
            try:
                if x.exists():
                    x.unlink()
            except Exception as e:
                print(f'[WARN] could not delete XML {x}: {e}')
        print('[INFO] Individual PDFs and XML files deleted.')
        sys.exit(0)
    else:
        print('[ERROR] Failed to merge PDFs: {}'.format(msg))
        sys.exit(1)


if __name__ == '__main__':
    main()
