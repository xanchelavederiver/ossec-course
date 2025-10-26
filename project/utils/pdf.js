import path from "path";
import fs from "fs";
import {execSync} from "child_process";
import puppeteer from "puppeteer";
import {ensureFolderExists} from "./fs.js";

/**
 * renderRevealPrintPdf(htmlFilePath, outPdfPath, options)
 *
 * Options:
 *   - format: 'A4' | 'Letter' | ... (passed to page.pdf). Default: 'A4'
 *   - landscape: boolean. Default: true
 *   - margin: {top,right,bottom,left} or string. Default: '10mm'
 *   - viewport: {width,height}. Default: {width:1600, height:900}
 *   - waitFor: ms to wait after load for reveal to layout. Default: 500
 *
 * Implementation note:
 * We load the generated Reveal HTML using a file:// URL and append ?print-pdf,
 * so reveal.js's print stylesheet / plugin lays out one slide per printed page.
 */
export async function renderRevealPrintPdf(htmlFilePath, outPdfPath, options = {}) {
  if (!fs.existsSync(htmlFilePath)) throw new Error('HTML file not found: ' + htmlFilePath);
  ensureFolderExists(path.dirname(outPdfPath));

  const {
    format = 'A4',
    landscape = true,
    margin = '10mm',
    viewport = {width: 1600, height: 900},
    waitFor = 500
  } = options;

  // Build file:// URL and append ?print-pdf
  let filePath = htmlFilePath;
  if (process.platform === 'win32') {
    // ensure url has three slashes and forward slashes
    filePath = '/' + filePath.replace(/\\/g, '/');
  }
  const url = `file://${filePath}${filePath.includes('?') ? '&' : '?'}print-pdf`;

  // console.log('[pdfUtils] rendering', url, '->', outPdfPath);
  const browser = await puppeteer.launch({
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });

  try {
    const page = await browser.newPage();
    await page.setViewport(viewport);

    // load and wait for network idle (assets) and reveal initialization
    await page.goto(url, {waitUntil: 'networkidle0'});
    await new Promise(r => setTimeout(r, waitFor))

    await page.pdf({
      path: outPdfPath,
      format,
      landscape,
      margin,
      printBackground: true
    });

    // console.log(`[pdfUtils] PDF written: ${outPdfPath} (format=${format}, landscape=${landscape}, margin=${JSON.stringify(margin)})`);
    return outPdfPath;
  } finally {
    await browser.close();
  }
}

/**
 * convertAdocToPdf(inputAdocPath, outputPdfPath)
 * - uses asciidoctor-pdf to create PDF
 */
export function convertAdocToPdf(inputAdocPath, outputPdfPath, options = []) {
  if (!fs.existsSync(inputAdocPath)) throw new Error('input adoc not found: ' + inputAdocPath);
  ensureFolderExists(path.dirname(outputPdfPath));

  const cmd = [
    "asciidoctor-pdf",
    `"${inputAdocPath}"`,
    '-o', `"${outputPdfPath}"`,
    ...options.map(kv => `-a ${kv}`)
  ].join(" ");
  // console.log('[asciidocUtils] running:', cmd);
  execSync(cmd, {stdio: 'inherit'});
  return outputPdfPath;
}
