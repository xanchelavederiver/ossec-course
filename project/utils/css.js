import path from "path";
import fs from "fs";


// Recursively finds all CSS files in a directory
async function findCSSFiles(folderPath, cssFiles) {
  try {
    const items = await fs.promises.readdir(folderPath);

    for (const item of items) {
      const fullPath = path.join(folderPath, item);
      const stat = await fs.promises.stat(fullPath);

      if (stat.isDirectory()) {
        // Recursively search subdirectories
        await findCSSFiles(fullPath, cssFiles);
      } else if (path.extname(item).toLowerCase() === '.css') {
        cssFiles.push(fullPath);
        console.log(` → Found CSS file: ${fullPath}`);
      }
    }
  } catch (error) {
    console.error(` ⚠️ Error reading directory ${folderPath}:`, error.message);
  }

  return cssFiles;
}

// Merges all CSS files content
async function mergeCSSFiles(cssFiles) {
  let mergedCSS = `/* Merged CSS from ${cssFiles.length} files */\n\n`;

  for (const filePath of cssFiles) {
    try {
      const content = await fs.promises.readFile(filePath, 'utf8');
      const relativePath = path.relative(process.cwd(), filePath);

      mergedCSS += `/* === ${relativePath} === */\n`;
      mergedCSS += content + '\n\n';
      console.log(` ✓ Merged: ${relativePath}`);
    } catch (error) {
      console.error(` ⚠️ Error reading ${filePath}:`, error.message);
    }
  }

  return mergedCSS;
}

// Inject the merged CSS into HTML file
async function injectCSSIntoHTML(htmlFilePath, cssContent, outputPath = null) {
  try {
    let htmlContent = await fs.promises.readFile(htmlFilePath, 'utf8');

    // Create style tag with merged CSS
    const styleTag = `\n<!-- Injected merged CSS -->\n<style>\n${cssContent}\n</style>\n`;

    // Insert before closing </head> tag, or at the end if no head tag
    if (htmlContent.includes('</head>')) {
      htmlContent = htmlContent.replace('</head>', styleTag + '</head>');
    } else if (htmlContent.includes('</body>')) {
      htmlContent = htmlContent.replace('</body>', styleTag + '</body>');
    } else {
      // Append to the end if no proper structure
      htmlContent += styleTag;
    }

    const finalOutputPath = outputPath || htmlFilePath;
    await fs.promises.writeFile(finalOutputPath, htmlContent, 'utf8');

    console.log(` 🎉 Successfully injected CSS into: ${finalOutputPath}`);
    return finalOutputPath;
  } catch (error) {
    console.error(` ⚠️ Error processing HTML file ${htmlFilePath}:`, error.message);
    throw error;
  }
}

export class CSSMerger {
  constructor() {
    this.cssFiles = [];
    this.mergedCSS = null;
  }

  async findAndMergeCSSFiles(rootFolder) {
    console.log('\n🔍 Scanning for CSS files...');
    await findCSSFiles(rootFolder, this.cssFiles);
    if (this.cssFiles.length === 0) {
      console.log('No CSS files found!');
      return;
    }

    console.log(`📦 Merging ${this.cssFiles.length} CSS files...`);
    this.mergedCSS = await mergeCSSFiles(this.cssFiles);
  }

  async process(htmlFilePath, outputHTMLPath = null) {
    await injectCSSIntoHTML(htmlFilePath, this.mergedCSS, outputHTMLPath);
    return {
      cssFilesCount: this.cssFiles.length,
      outputPath: outputHTMLPath || htmlFilePath
    };
  }
}
