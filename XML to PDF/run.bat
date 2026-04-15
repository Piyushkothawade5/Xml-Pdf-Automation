@echo off
set PYEXE=python
set SCRIPT=D:\CT-PT Projects\XML to PDF\tools\cta_report_automation_with_plot_compressed.py
set XMLDIR=D:\CT-PT Projects\XML to PDF\xml
set OUTDIR=D:\CT-PT Projects\XML to PDF\pdf
set MASTER=D:\CT-PT Projects\XML to PDF\Master.pdf

%PYEXE% "%SCRIPT%" --xml-dir "%XMLDIR%" --out-dir "%OUTDIR%" --master-pdf "%MASTER%" --engine chrome
pause