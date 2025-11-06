import path from "path";
import fs from "fs";
import {execSync} from "child_process";

import {
  cssFolderPath,
  docinfoChalkboardCssCDN,
  docinfoChalkboardFile,
  docinfoChalkboardJsCDN,
  docinfoDefaultsFile,
  docinfoDir,
  docinfoMenuCssCDN,
  docinfoMenuFile,
  docinfoMenuJsCDN,
  docinfoOutputFile,
  revealjsCDN,
  revealjsLocalDir,
  revealjsPluginsLocalDir,
} from "./build-settings.js";
import {DocInfoHTMLConcatenator} from "./utils/docinfo.js";
import {CSSMerger} from "./utils/css.js";
import {copyAllNotHiddenFolders, ensureFolderExists} from "./utils/fs.js";

function setupPlugins(useCDN = false) {
  const pluginAttrs = [];
  const concat = new DocInfoHTMLConcatenator();

  console.log("⚙️ Setting up the plugins:");

  // built-in plugins
  if (process.env.ENABLE_HIGHLIGHT?.toLowerCase() === "true") {
    console.log(" → Highlight plugin enabled");
  } else {
    pluginAttrs.push("revealjs_plugin_highlight=disabled");
    console.log(" → Highlight plugin disabled (ENABLE_HIGHLIGHT not set)");
  }
  if (process.env.ENABLE_MARKDOWN?.toLowerCase() === "true") {
    console.log(" → Markdown plugin enabled");
  } else {
    pluginAttrs.push("revealjs_plugin_markdown=disabled");
    console.log(" → Markdown plugin disabled (ENABLE_MARKDOWN not set)");
  }
  if (process.env.ENABLE_MATH?.toLowerCase() === "true") {
    console.log(" → Math plugin enabled");
  } else {
    pluginAttrs.push("revealjs_plugin_math=disabled");
    console.log(" → Math plugin disabled (ENABLE_MATH not set)");
  }
  if (process.env.ENABLE_NOTES?.toLowerCase() === "true") {
    console.log(" → Notes plugin enabled");
  } else {
    pluginAttrs.push("revealjs_plugin_notes=disabled");
    console.log(" → Notes plugin disabled (ENABLE_NOTES not set)");
  }
  if (process.env.ENABLE_SEARCH?.toLowerCase() === "true") {
    console.log(" → Search plugin enabled");
  } else {
    pluginAttrs.push("revealjs_plugin_search=disabled");
    console.log(" → Search plugin disabled (ENABLE_SEARCH not set)");
  }
  if (process.env.ENABLE_ZOOM?.toLowerCase() === "true") {
    console.log(" → Zoom plugin enabled");
  } else {
    pluginAttrs.push("revealjs_plugin_zoom=disabled");
    console.log(" → Zoom plugin disabled (ENABLE_ZOOM not set)");
  }

  // third-party plugins
  let prefix
  concat.addFile(docinfoDefaultsFile, null, 1)
  if (process.env.ENABLE_MENU?.toLowerCase() === "true") {
    if (useCDN) {
      prefix = `<script src="${docinfoMenuJsCDN}"></script>\n<link href="${docinfoMenuCssCDN}" rel="stylesheet">`
    } else {
      prefix = `<script src="/${revealjsPluginsLocalDir}/menu/menu.js"></script>\n<link href="/${revealjsPluginsLocalDir}/menu/menu.css" rel="stylesheet">`
    }
    concat.addFile(docinfoMenuFile, prefix, 2)
    console.log(" → Menu plugin enabled");
  } else {
    console.log(" → Menu plugin disabled (ENABLE_MENU not set)");
  }

  if (process.env.ENABLE_CHALKBOARD?.toLowerCase() === "true") {
    if (useCDN) {
      prefix = `<script src="${docinfoChalkboardJsCDN}"></script>\n<link href="${docinfoChalkboardCssCDN}" rel="stylesheet">`
    } else {
      prefix = `<script src="/${revealjsPluginsLocalDir}/chalkboard/plugin.js"></script>\n<link href="/${revealjsPluginsLocalDir}/chalkboard/style.css" rel="stylesheet">`
    }
    concat.addFile(docinfoChalkboardFile, prefix, 3)
    console.log(" → Chalkboard plugin enabled");
  } else {
    console.log(" → Chalkboard plugin disabled (ENABLE_CHALKBOARD not set)");
  }

  // TODO: add the rest of the plugins

  // merge the selected third-party docinfo files
  console.log(" → Merging docinfo HTML files");
  const nDocInfoFiles = concat.concatenate(docinfoOutputFile, {
    separator: '\n<hr>\n\n',
    addFileComments: true
  });
  console.log(`   🎉 Successfully created ${docinfoOutputFile} with ${nDocInfoFiles} files`);

  return pluginAttrs
}

export async function buildSlides(slides, outputDir, useCDN = false) {
  // 1. switch on the required reveal.js plugins
  const pluginAttrs = setupPlugins(useCDN)

  // 2. set up reveal.js location
  console.log("\n⚙️ Setting up reveal.js location:");
  let revealjsDir = revealjsCDN;
  if (useCDN) {
    console.log(" → Using reveal.js from CDN: %s", revealjsDir);
  } else {
    revealjsDir = `/${revealjsLocalDir}`;
    console.log(" → Using local reveal.js: %s", revealjsDir);
  }

  // 3. gather and merge CSS files
  const merger = new CSSMerger();
  await merger.findAndMergeCSSFiles(cssFolderPath);

  // 4. build the gathered slides
  // make sure the output folder exists
  ensureFolderExists(outputDir);

  // build the slides.adoc files
  let outputHTMLFiles = []
  console.log(`\n🛠 Building ${slides.length} presentation(s):`);
  for (const adocPath of slides) {
    const adocFolderPath = path.dirname(adocPath);
    const adocFolderName = path.basename(adocFolderPath);

    if (!fs.existsSync(adocPath)) {
      console.log(` ⚠️  No slides.adoc found in ${adocFolderPath}`);
      continue;
    }

    const outputSlidesDir = path.join(outputDir, adocFolderName);
    const outputFilePath = path.join(outputSlidesDir, "slides.html");
    ensureFolderExists(outputSlidesDir);

    copyAllNotHiddenFolders(adocFolderPath, outputSlidesDir);

    const cmd = [
      "npx asciidoctor-revealjs",
      `"${adocPath}"`,
      `-o "${outputFilePath}"`,
      `-a revealjsdir=${revealjsDir}`,
      `-a docinfodir="${path.resolve(docinfoDir).replace(/\\\\/g, "/")}"`,
      `-a docinfo=shared`,
      ...pluginAttrs.map(kv => `-a ${kv}`)
    ].join(" ");
    console.log(` → Building ${outputFilePath}`);
    // console.log(` → cmd: ${cmd}`)
    execSync(cmd, {stdio: "inherit"});

    await merger.process(outputFilePath);

    outputHTMLFiles.push(outputFilePath);
  }

  console.log("\n✅  Build complete.");
  return outputHTMLFiles;
}
