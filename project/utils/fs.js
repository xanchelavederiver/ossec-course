import fs from "fs";
import fg from "fast-glob"
import {examAdocPath, labsPattern, lectureNotesPattern, slidesPattern} from "../build-settings.js"

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
