import 'dotenv/config';
import {execSync} from "child_process";
import path from "path";
import * as fs from "fs";

const slidesRoot = "materials/lectures";
const distRoot = "dist";
const revealjsLocalDir = "reveal.js";

const docinfoDir = "docinfo";
const docinfoDefaultsFile = `${docinfoDir}/docinfo-footer-defaults.html`;
const docinfoMenuFile = `${docinfoDir}/docinfo-footer-menu.html`;
const docinfoChalkboardFile = `${docinfoDir}/docinfo-footer-chalkboard.html`;
const docinfoOutputFile = `${docinfoDir}/docinfo-footer.html`;


// 1. switch on the required reveal.js plugins
class HTMLConcatenator {
    constructor() {
        this.files = [];
    }

    addFile(filePath, order = null) {
        this.files.push({path: filePath, order});
        return this; // for method chaining - fluency
    }

    concatenate(outputPath, options = {}) {
        const {
            separator = '\n',
            addFileComments = true
        } = options;

        const filesToProcess = this.files.sort((a, b) => {
            if (a.order !== null && b.order !== null) return a.order - b.order;
            return 0;
        });

        let combinedContent = '';
        for (const file of filesToProcess) {
            try {
                let content = fs.readFileSync(file.path, 'utf8');
                if (addFileComments) {
                    content = `<!-- File: ${path.basename(file.path)} -->\n${content}\n`;
                }
                combinedContent += content + separator;
                console.log(`✓ Added: ${file.path}`);

            } catch (error) {
                console.error(`✗ Error reading ${file.path}:`, error.message);
            }
        }

        fs.writeFileSync(outputPath, combinedContent);
        console.log(`🎉 Successfully created ${outputPath} with ${filesToProcess.length} files`);
    }
}

const pluginAttrs = [];
const concat = new HTMLConcatenator();
concat.addFile(docinfoDefaultsFile, 1)

// built-in plugins
if (process.env.ENABLE_ZOOM?.toLowerCase() === "true") {
    console.log("→ Zoom plugin enabled");
} else {
    pluginAttrs.push("revealjs_plugin_zoom=disabled");
    console.log("→ Zoom plugin disabled (ENABLE_ZOOM not set)");
}
if (process.env.ENABLE_NOTES?.toLowerCase() === "true") {
    console.log("→ Notes plugin enabled");
} else {
    pluginAttrs.push("revealjs_plugin_notes=disabled");
    console.log("→ Notes plugin disabled (ENABLE_NOTES not set)");
}

// optional third-party plugins (controlled by env vars)
if (process.env.ENABLE_MENU?.toLowerCase() === "true") {
    concat.addFile(docinfoMenuFile, 2)
    console.log("→ Menu plugin enabled");
} else {
    console.log("→ Menu plugin disabled (ENABLE_MENU not set)");
}
if (process.env.ENABLE_CHALKBOARD?.toLowerCase() === "true") {
    concat.addFile(docinfoChalkboardFile, 3)
    console.log("→ Chalkboard plugin enabled");
} else {
    console.log("→ Chalkboard plugin disabled (ENABLE_CHALKBOARD not set)");
}

concat.concatenate(docinfoOutputFile, {
    separator: '\n<hr>\n',
    addFileComments: true
});


// 2. set up reveal.js location
let revealjsDir;
if (process.env.USE_CDN_REVEALJS?.toLowerCase() === "true") {
    revealjsDir = "https://cdn.jsdelivr.net/npm/reveal.js@5";
    console.log("→ Using reveal.js from CDN %s", revealjsDir);
} else {
    // revealjsDir = path.resolve("reveal.js").replace(/\\/g, "/");
    revealjsDir = `/${revealjsLocalDir}`;
    console.log("→ Using local reveal.js (USE_CDN_REVEALJS not set): %s", revealjsDir);
}


// 3. find all the slides.adoc files and build them
function findSlidesAdocFolders(rootDir, baseDir = rootDir, results = []) {
    let hasSlidesAdoc = false;
    const subDirs = [];

    // first, check all items in the current directory
    for (const item of fs.readdirSync(rootDir)) {
        const itemPath = path.join(rootDir, item);
        try {
            if (fs.statSync(itemPath).isDirectory()) {
                subDirs.push(itemPath);
            } else if (item === 'slides.adoc') {
                hasSlidesAdoc = true;
            }
        } catch (err) {
            // handle permission errors or other issues by just logging it
            console.error(`Error accessing ${itemPath}:`, err.message);
        }
    }

    // if "slides.adoc" was found, add the relative path to results
    if (hasSlidesAdoc) {
        const relativePath = path.relative(baseDir, rootDir);
        results.push(relativePath || '.'); // Use '.' for the base directory itself
    }

    // recursively search all subdirectories - just in case there will be "subpresentations" of sorts
    for (const subDir of subDirs) {
        findSlidesAdocFolders(subDir, baseDir, results);
    }

    return results;
}

/// gather slides.adoc files
const presentations = findSlidesAdocFolders(slidesRoot)
console.log(`\n🛠 Building ${presentations.length} presentation(s):`);

// make sure the output folder exists
if (!fs.existsSync(distRoot)) fs.mkdirSync(distRoot);

// build the slides.adoc files
for (const pres of presentations) {
    const adocPath = path.join(slidesRoot, pres, "slides.adoc");
    const outputDir = path.join(distRoot, pres);
    const outputFile = path.join(outputDir, "slides.html");
    if (!fs.existsSync(outputDir)) fs.mkdirSync(outputDir, {recursive: true});

    if (!fs.existsSync(adocPath)) {
        console.warn(`⚠️  No slides.adoc found for ${pres}`);
        continue;
    }

    const cmd = [
        "npx asciidoctor-revealjs",
        `"${adocPath}"`,
        `-o "${outputFile}"`,
        `-a revealjsdir=${revealjsDir}`,
        `-a docinfodir="${path.resolve(docinfoDir).replace(/\\\\/g, "/")}"`,
        `-a docinfo=shared`,
        ...pluginAttrs.map(kv => `-a ${kv}`)
    ].join(" ");
    console.log(` → Building ${pres}/slides.html`);
    // console.log(cmd)
    execSync(cmd, {stdio: "inherit"});
}


// TODO: build (make .pdf files) lecture notes, labs, and exam questions

console.log("\n✅ Build complete.\n");
