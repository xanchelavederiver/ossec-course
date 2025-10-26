import path from "path";
import fs from "fs";

export class DocInfoHTMLConcatenator {
  constructor() {
    this.files = [];
  }

  addFile(filePath, prefix, order = null) {
    this.files.push({path: filePath, prefix: prefix, order});
    return this; // for method chaining ("fluency")
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
        if (file.prefix !== null) {
          content = `${file.prefix}\n${content}`
        }
        if (addFileComments) {
          content = `<!-- File: ${path.basename(file.path)} -->\n${content}`;
        }
        combinedContent += content + separator;
        console.log(`   ✓ Added: ${file.path}`);

      } catch (error) {
        console.error(`   ✗ Error reading ${file.path}:`, error.message);
      }
    }

    fs.writeFileSync(outputPath, combinedContent);
    return filesToProcess.length;
  }
}
