const os = require("os");
const childProcess = require("child_process");
const path = require("path");
const fs = require("fs");
const process = require("process");

const isNpmBuildFromSourceSet = process.env.npm_config_build_from_source;
const platform = process.platform;
const arch = process.arch;

// When the package was published with prebuilt binaries, each platform's
// binary lives in a dedicated optional sub-package.  npm may hoist it to the
// project root's node_modules or keep it nested; resolve() handles both.
const MAIN_PKG_NAME = require(path.join(__dirname, "package.json")).name;
const subPkgName = `${MAIN_PKG_NAME}-${platform}-${arch}`;

let subPkgBinaryPath = null;
try {
  // require.resolve finds the sub-package regardless of hoisting depth.
  const subPkgMain = require.resolve(`${subPkgName}/package.json`, { paths: [__dirname] });
  subPkgBinaryPath = path.join(path.dirname(subPkgMain), "lbugjs.node");
  if (!fs.existsSync(subPkgBinaryPath)) subPkgBinaryPath = null;
} catch (e) {
  // Sub-package not installed (unsupported platform or missing optionalDep).
}

// Fall back to the legacy prebuilt/ directory layout for compatibility with
// tarballs built before the per-platform sub-package migration.
const legacyPrebuiltPath = path.join(
  __dirname,
  "prebuilt",
  `lbugjs-${platform}-${arch}.node`
);

const prebuiltPath = subPkgBinaryPath
  ? subPkgBinaryPath
  : fs.existsSync(legacyPrebuiltPath)
  ? legacyPrebuiltPath
  : null;

// Check if building from source is forced
if (isNpmBuildFromSourceSet) {
  console.log(
    "The NPM_CONFIG_BUILD_FROM_SOURCE environment variable is set. Building from source."
  );
} else if (prebuiltPath) {
  console.log(`Prebuilt binary found at ${prebuiltPath}.`);
  console.log("Copying prebuilt binary to package directory...");
  fs.copyFileSync(prebuiltPath, path.join(__dirname, "lbugjs.node"));
  console.log(
    `Copied ${prebuiltPath} -> ${path.join(__dirname, "lbugjs.node")}.`
  );
  // When the package was built with prebuilt binaries, the JS files are
  // already present in the package root (copied by package.js at publish
  // time).  No further copying is needed.
  console.log("Done!");
  process.exit(0);
} else {
  console.log("Prebuilt binary is not available, building from source...");
}

// Get number of threads
const THREADS = os.cpus().length;
console.log(`Using ${THREADS} threads to build Lbug.`);

// Install dependencies
console.log("Installing dependencies...");
childProcess.execSync("npm install", {
  cwd: path.join(__dirname, "lbug-source", "tools", "nodejs_api"),
  stdio: "inherit",
});

// Build the Lbug source code
console.log("Building Lbug source code...");
const env = { ...process.env };

if (process.platform === "darwin") {
  const archflags = process.env["ARCHFLAGS"]
    ? process.env["ARCHFLAGS"] === "-arch arm64"
      ? "arm64"
      : process.env["ARCHFLAGS"] === "-arch x86_64"
        ? "x86_64"
        : null
    : null;
  if (archflags) {
    console.log(`The ARCHFLAGS is set to '${archflags}'.`);
    env["CMAKE_OSX_ARCHITECTURES"] = archflags;
  } else {
    console.log("The ARCHFLAGS is not set or is invalid and will be ignored.");
  }

  const deploymentTarget = process.env["MACOSX_DEPLOYMENT_TARGET"];
  if (deploymentTarget) {
    console.log(
      `The MACOSX_DEPLOYMENT_TARGET is set to '${deploymentTarget}'.`
    );
    env["CMAKE_OSX_DEPLOYMENT_TARGET"] = deploymentTarget;
  } else {
    console.log("The MACOSX_DEPLOYMENT_TARGET is not set and will be ignored.");
  }
}

if (process.platform === "win32") {
  // The `rc` package conflicts with the rc command (resource compiler) on
  // Windows. This causes the build to fail. This is a workaround which removes
  // all the environment variables added by npm.
  const pathEnv = process.env["Path"];
  const pathSplit = pathEnv.split(";").filter((path) => {
    const pathLower = path.toLowerCase();
    return !pathLower.includes("node_modules");
  });
  env["Path"] = pathSplit.join(";");
  console.log(
    "The PATH environment variable has been modified to remove any 'node_modules' directories."
  );

  for (let key in env) {
    if (
      key.toLowerCase().includes("node" || key.toLowerCase().includes("npm"))
    ) {
      delete env[key];
    }
  }
  console.log(
    "Any environment variables containing 'node' or 'npm' have been removed."
  );
}

childProcess.execSync("make nodejs NUM_THREADS=" + THREADS, {
  env,
  cwd: path.join(__dirname, "lbug-source"),
  stdio: "inherit",
});

// Copy the built files to the package directory
const BUILT_DIR = path.join(
  __dirname,
  "lbug-source",
  "tools",
  "nodejs_api",
  "build"
);
// Get all the js and node files
const files = fs.readdirSync(BUILT_DIR).filter((file) => {
  return file.endsWith(".js") || file.endsWith(".mjs") || file.endsWith(".d.ts") || file.endsWith(".node");
});
console.log("Files to copy: ");
for (const file of files) {
  console.log("  " + file);
}
console.log("Copying built files to package directory...");
for (const file of files) {
  fs.copyFileSync(path.join(BUILT_DIR, file), path.join(__dirname, file));
}

// Clean up
console.log("Cleaning up...");
childProcess.execSync("npm run clean-all", {
  cwd: path.join(__dirname, "lbug-source", "tools", "nodejs_api"),
});
childProcess.execSync("make clean", {
  cwd: path.join(__dirname, "lbug-source"),
});
console.log("Done!");
