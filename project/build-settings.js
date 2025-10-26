import path from "path";

const ROOT = process.cwd();

// project structure
export const slidesPattern = path.posix.join('materials', 'lectures', '**', 'slides.adoc');
export const lectureNotesPattern = path.posix.join('materials', 'lectures', '**', 'lecture-notes.adoc');
export const labsPattern = path.posix.join('materials', 'labs', '**', '*.adoc');
export const examAdocPath = path.join(ROOT, 'materials', 'exam', 'exam.adoc');

export const slidesPdfOptionsFilePath = path.join(ROOT, 'config', 'pdf', 'slides.json');

export const cssFolderPath = path.join(ROOT, 'css');

export const distRoot = path.join(ROOT, "dist");
export const publicRoot = path.join(ROOT, "..", "public");

// reveal.js location
export const revealjsLocalDir = "reveal.js";
export const revealjsPluginsLocalDir = "reveal.js-plugins";
export const revealjsCDN = "https://cdn.jsdelivr.net/npm/reveal.js@5";

// reveal.js plugins setup
export const docinfoDir = "docinfo";
export const docinfoOutputFile = `${docinfoDir}/docinfo-footer.html`;
export const docinfoDefaultsFile = `${docinfoDir}/docinfo-footer-defaults.html`;

export const docinfoMenuFile = `${docinfoDir}/docinfo-footer-menu.html`;
export const docinfoMenuJsCDN = "https://cdn.jsdelivr.net/npm/reveal.js-menu@2.1.0/menu.js";
export const docinfoMenuCssCDN = "https://cdn.jsdelivr.net/npm/reveal.js-menu@2.1.0/menu.css";

export const docinfoChalkboardFile = `${docinfoDir}/docinfo-footer-chalkboard.html`;
export const docinfoChalkboardJsCDN = "https://cdn.jsdelivr.net/npm/reveal.js-plugins@latest/chalkboard/plugin.js";
export const docinfoChalkboardCssCDN = "https://cdn.jsdelivr.net/npm/reveal.js-plugins@latest/chalkboard/style.css";

// output (PDF) file names
export const examPdfFileName = 'Вопросы.pdf';
export const examLinksPdfFileName = 'Вопросы-ссылки.pdf';
