import path from "path";
import fs from "fs";
import fg from "fast-glob"
import {
  examAdocPath,
  labsPattern,
  lectureNotesPattern,
  slidesPattern,
  slidesPdfOptionsFilePath
} from "../build-settings.js"

const ROOT = process.cwd();

export function ensureFolderExists(folderPath) {
  try {
    if (!fs.existsSync(folderPath)) {
      fs.mkdirSync(folderPath, {recursive: true});
    }
  } catch (err) {
    console.error(err);
  }
}

export function recreateFolder(folderPath) {
  if (fs.existsSync(folderPath)) {
    fs.rmSync(folderPath, {recursive: true});
  }
  ensureFolderExists(folderPath);
}

export function checkIfFileIsWithinFolder(folderPath, filePath) {
  const rel = path.relative(folderPath, filePath);
  return rel && !rel.startsWith('..') && !path.isAbsolute(rel);
}

export function getFirstFolderFromRelativePath(relativePath) {
  // check if the path is actually absolute - return null if it is
  if (path.isAbsolute(relativePath)) {
    return ''
  }

  // parse the path to get the first segment
  // N.B. The 'dir' property will contain the directory path up to the filename.
  //      We then split this path and take the first element after removing any leading dots.
  const parsedPath = path.parse(relativePath);
  // const pathParts = parsedPath.dir.split(path.sep).filter(part => part !== '.' && part !== '..');
  const pathParts = parsedPath.dir.split(path.sep).filter(part => part !== '.');

  if (pathParts.length > 0) {
    return pathParts[0];
  } else if (parsedPath.base && !parsedPath.ext) {
    // if it's a single folder name without extension
    return parsedPath.base;
  } else {
    // no folder found or path is just a file
    return '';
  }
}

export function findSlides() {
  return fg.sync([slidesPattern], {cwd: ROOT, absolute: true});
}

export function findLectureNotes() {
  return fg.sync([lectureNotesPattern], {cwd: ROOT, absolute: true});
}

export function findLabs() {
  return fg.sync([labsPattern], {cwd: ROOT, absolute: true});
}

export function findExam() {
  return fs.existsSync(examAdocPath) ? examAdocPath : null;
}

export function readJson(jsonFilePath) {
  const data = fs.readFileSync(jsonFilePath);
  return JSON.parse(data);
}

export function readSlidesPdfOptions() {
  return readJson(slidesPdfOptionsFilePath);
}
