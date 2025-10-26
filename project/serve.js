import express from "express";
import chokidar from "chokidar";
import {exec} from "child_process";
import {WebSocketServer} from "ws";
import path from "path";
import fs from "fs";
import {configFolderPath, cssFolderPath, distRoot, docinfoFolderPath, slidesFolderPath} from "./build-settings.js";
import {checkIfFileIsWithinFolder, getFirstFolderFromRelativePath} from "./utils/fs.js";
import {isNullOrEmpty} from "./utils/misc.js";

const PORT = process.env.PORT || 3000;
const args = process.argv.slice(2);
const enableHot = args.includes("--watch") || args.includes("--hot");

const app = express();

// ------------------------------------------------------
// 📂 Dynamic presentation index
// ------------------------------------------------------
function getPresentations() {
  if (!fs.existsSync(distRoot)) return [];
  return fs
    .readdirSync(distRoot)
    .filter((f) => fs.statSync(path.join(distRoot, f)).isDirectory());
}

app.get("/", (req, res) => {
  const presentations = getPresentations();
  const links = presentations
    .map((name) => `<li><a href="/${name}/slides.html">${name}</a></li>`)
    .join("\n");
  res.send(`
    <h2>📑 Available Presentations</h2>
    <ul>${links}</ul>
    <p style="margin-top:1em;font-size:0.9em;color:#666">
      ${enableHot ? "Hot reload enabled 🔥" : "Hot reload disabled ⚙️ (run with --hot)"}<br>
    </p>
  `);
});

// ------------------------------------------------------
// 🚀 Start Express server
// ------------------------------------------------------
const server = app.listen(PORT, () => {
  console.log(`🚀 Server running at http://localhost:${PORT}`);
  if (enableHot) console.log("🔥 Hot reload mode is ON\n");
  else console.log("⚙️  Static serve mode (no rebuilds)\n");
});

// ------------------------------------------------------
// 🔄 WebSocket reload (only if --hot enabled)
// ------------------------------------------------------
let wss = null;
let sockets = new Set();

if (enableHot) {
  wss = new WebSocketServer({server});
  wss.on("connection", (ws) => {
    sockets.add(ws);
    ws.on("close", () => sockets.delete(ws));
  });

  // Inject reload script dynamically into HTML responses
  app.use((req, res, next) => {
    if (req.path.endsWith(".html")) {
      const filePath = path.join(distRoot, req.path);
      const decodedPath = decodeURI(filePath);
      console.log("Patching file %s", decodedPath)
      if (fs.existsSync(decodedPath)) {
        console.log("Found file %s", decodedPath)
        let html = fs.readFileSync(decodedPath, "utf8");
        if (!html.includes("__hot_reload__")) {
          const reloadScript = `
            <script id="__hot_reload__">
            (() => {
              const ws = new WebSocket("ws://" + location.host);
              ws.onmessage = (msg) => {
                if (msg.data === "reload") location.reload();
              };
            })();
            </script>`;
          html = html.replace("</body>", `${reloadScript}\n</body>`);
        }
        res.send(html);
        return;
      }
    }
    next();
  });
}

// ------------------------------------------------------
// 🧱 Express static routes
// ------------------------------------------------------
app.use(express.static(distRoot));
app.use("/reveal.js", express.static("reveal.js"));
app.use("/reveal.js-plugins", express.static("reveal.js-plugins"));

// ------------------------------------------------------
// 🧩 Watchers for slides src folder & rebuild
// ------------------------------------------------------
if (enableHot) {
  let isBuilding = false;
  let rebuildTimer = null;

  function rebuild(filePath, stats) {
    if (isBuilding) return;
    isBuilding = true;

    // console.log(`path=${filePath}`);
    // console.log(`checkIfFileIsWithinFolder(slidesFolderPath, filePath) = ${checkIfFileIsWithinFolder(slidesFolderPath, filePath)}`)
    // console.log(`path.relative(slidesFolderPath, filePath) = ${path.relative(slidesFolderPath, filePath)}`)
    // console.log(`first(path.relative(slidesFolderPath, filePath)) = ${getFirstFolderFromRelativePath(path.relative(slidesFolderPath, filePath))}`)

    let cmd = 'node build.js slides';
    const lectureNameFolder = getFirstFolderFromRelativePath(path.relative(slidesFolderPath, filePath));
    if (checkIfFileIsWithinFolder(slidesFolderPath, filePath) && !isNullOrEmpty(lectureNameFolder)) {
      // a single slide needs to be rebuilt
      const filePath = path.join(slidesFolderPath, lectureNameFolder, 'slides.adoc');
      cmd = `${cmd} ${filePath}`
      console.log(`🔄 Rebuilding presentation ${filePath}`);
    } else {
      console.log("🔄 Rebuilding presentations...");
    }

    exec(cmd, (err, stdout, stderr) => {
      if (err) console.error(stderr);
      else console.log(stdout);

      console.log("✅  Notifying clients...\n");
      sockets.forEach((ws) => ws.send("reload"));
      isBuilding = false;
    });
  }

  const watcher = chokidar.watch([
    slidesFolderPath,
    configFolderPath,
    cssFolderPath,
    path.join(docinfoFolderPath, 'docinfo-footer-*.html')
  ], {
    ignoreInitial: true,
    depth: 2,
  });
  watcher.on("change", (path, stats) => {
    clearTimeout(rebuildTimer);
    rebuildTimer = setTimeout(rebuild, 400, path, stats);
  });
  watcher.on("add", rebuild);
  watcher.on("unlink", rebuild);

  console.log("👀 Watching for slide changes...\n");
} else {
  console.log("👁️  Not watching for changes. Run with `node serve.js --hot` to enable.\n");
}
