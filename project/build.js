#!/usr/bin/env node
import 'dotenv/config';
import path from "path";
import {
  ensureFolderExists,
  findExam,
  findLabs,
  findLectureNotes,
  findSlides,
  readSlidesPdfOptions,
  recreateFolder
} from "./utils/fs.js";
import {runWithConcurrency} from "./utils/exec.js";
import {convertAdocToPdf, renderRevealPrintPdf} from "./utils/pdf.js";
import {buildSlides} from "./build-slides.js"
import {distRoot, examLinksPdfFileName, examPdfFileName, publicRoot} from "./build-settings.js";

// region Commands execution

async function cmdSlides(argPath) {
  // 1. gather slides.adoc files
  let slides;
  if (argPath) {
    const slidesFilePath = path.isAbsolute(argPath) ? argPath : path.join(process.cwd(), argPath);
    slides = [slidesFilePath];
    console.log("ℹ️ Building a single slides HTML:", slidesFilePath);
    ensureFolderExists(distRoot);
  } else {
    slides = findSlides()
    if (!slides.length) {
      console.log("⚠️ Found 0 slides.adoc files - nothing to build");
      return;
    }
    recreateFolder(distRoot);
  }

  // 2. build the slides
  let useCDN = false;
  if (process.env.USE_CDN_REVEALJS?.toLowerCase() === "true") {
    useCDN = true;
    console.log("Forcing CDN links usage for reveal.js (USE_CDN_REVEALJS is set)");
  }
  await buildSlides(slides, distRoot, useCDN);
}

async function cmdPublish(target) {
  // 1. publish the slides (both HTML with CDN links and PDF files) and lecture notes
  if (['lectures', 'all'].includes(target)) {
    console.log("ℹ️ Publishing slides HTML files");
    const slides = findSlides();
    if (!slides.length) {
      console.log('⚠️ Found 0 slides.adoc files - nothing to publish.');
    } else {
      const lecturesOutputFolderPath = path.join(publicRoot, 'lectures')
      recreateFolder(lecturesOutputFolderPath);

      // i. build HTML files
      const outputHTMLFiles = await buildSlides(slides, lecturesOutputFolderPath, true);

      // ii. render the built HTML files
      console.log("\nℹ️ Publishing slides PDF files:");
      for (const htmlFilePath of outputHTMLFiles) {
        const outputPdfFilePath = path.join(path.dirname(htmlFilePath), "slides.pdf");
        const pdfOptions = readSlidesPdfOptions();
        console.log(` → Publishing slide PDF ${outputPdfFilePath}`);
        // console.log(` → cmd: renderRevealPrintPdf(${htmlFilePath}, ${outputPdfFilePath}, pdfOptions)`)
        await renderRevealPrintPdf(htmlFilePath, outputPdfFilePath, pdfOptions);
      }

      // iii. gather and build lecture notes
      const lectureNotes = findLectureNotes();
      if (lectureNotes.length) {
        console.log("\nℹ️ Publishing lecture notes PDF files:");
        for (const lnFilePath of lectureNotes) {
          const outputFolderPath = path.join(lecturesOutputFolderPath, path.basename(path.dirname(lnFilePath)));
          const outputPdfFilePath = path.join(outputFolderPath, "lecture-notes.pdf");
          console.log(` → Publishing lecture notes PDF ${outputPdfFilePath}`);
          await convertAdocToPdf(lnFilePath, outputPdfFilePath);
        }
      }
    }
  }

  // 2. publish the labs' manuals
  if (['labs', 'all'].includes(target)) {
    console.log("\nℹ️ Publishing labs PDF files:");
    const labs = findLabs();
    if (!labs.length) {
      console.log('⚠️  No labs found - nothing to publish.');
    } else {
      const labsOutputFolderPath = path.join(publicRoot, 'labs')
      recreateFolder(labsOutputFolderPath);

      // create a task for each lab
      const tasks = labs.map(lab => async () => {
        // TODO: export additional lab files

        const pdfFileName = path.basename(lab, path.extname(lab));
        const outputFolderName = path.basename(path.dirname(lab));
        const outputFolderPath = path.join(labsOutputFolderPath, outputFolderName)
        ensureFolderExists(outputFolderPath);

        const outputPdfFilePath = path.join(outputFolderPath, `${pdfFileName}.pdf`);
        console.log(` → Publishing lab ${outputPdfFilePath}`);
        await convertAdocToPdf(lab, outputPdfFilePath);
        return outputPdfFilePath;
      });

      const CONCURRENCY = parseInt(process.env.BUILD_CONCURRENCY || '3', 10) || 3;
      await runWithConcurrency(tasks, CONCURRENCY);
    }
  }

  // 3. publish the exam sheets
  if (['exam', 'all'].includes(target)) {
    console.log("\nℹ️ Publishing exam PDF files:");
    const exam = findExam();
    if (!exam) {
      console.log('⚠️  Exam file exam.adoc not found - nothing to publish.');
    } else {
      const outputFolderPath = path.join(publicRoot, 'exam')
      recreateFolder(outputFolderPath);

      let outputPdfFilePath = path.join(outputFolderPath, examPdfFileName);
      console.log(` → Publishing exam PDF ${outputPdfFilePath}`);
      await convertAdocToPdf(exam, outputPdfFilePath);

      outputPdfFilePath = path.join(outputFolderPath, examLinksPdfFileName);
      console.log(` → Publishing exam PDF ${outputPdfFilePath}`);
      await convertAdocToPdf(exam, outputPdfFilePath, ['exam-links']);
    }
  }

  console.log("\n✅  Publishing complete.");
}

// endregion Commands execution


// region Main
// cmd args parsing
function usageAndExit() {
  console.log("Usage: node build.js <command> [args]");
  console.log("Commands:");
  console.log("  slides  [<path-to-presentation>/slides.adoc]   build slides for local serving");
  console.log("  publish [exam|labs|lectures|all]                 build & publish slides (HTMLs and PDFs) along with the lecture notes, labs, and the exam sheet");
  process.exit(1);
}

const argv = process.argv.slice(2);
if (!argv.length) usageAndExit();

// execute the given cmd
(async () => {
  const cmd = argv[0];
  if (cmd === "slides") {
    await cmdSlides(argv[1]);
  } else if (cmd === "publish") {
    let target = argv[1];
    if (!target) {
      target = "all";
    }
    if (!target || !["exam", "labs", "lectures", "all"].includes(target)) {
      console.error("Error: publish requires one of: \"exam\" | \"labs\" | \"lectures\" | \"all\"");
      process.exit(2);
    }
    await cmdPublish(target);
  } else {
    usageAndExit();
  }
})().catch(err => {
  console.error('[build] error:', err);
  process.exit(1);
});

// endregion Main
