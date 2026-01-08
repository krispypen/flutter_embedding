// A simple check using the PWD environment variable.
// When a package is installed as a dependency, the 'PWD' (Present Working Directory)
// will usually be the 'node_modules/your-package-name' directory, while
// the 'INIT_CWD' (Initial Working Directory) is the main application's root.
// If PWD equals INIT_CWD, it means the user is likely running 'npm install' inside the package itself.

const path = require('path');

const currentDir = process.cwd(); // Equivalent to PWD
const initialCwd = process.env.INIT_CWD;

// Check 1: If INIT_CWD is NOT defined, assume direct install (e.g. older npm/yarn versions or direct use)
if (!initialCwd) {
    console.error("Postinstall script skipped: INIT_CWD not found. Assuming direct install.");
    process.exit(0);
}

// Check 2: If the current working directory IS the initial working directory,
// it means 'npm install' was run inside this package's directory.
// We only want to run the script when this package is a *dependency* of another project.
if (path.resolve(currentDir) === path.resolve(initialCwd)) {
    console.error("Postinstall script skipped: Running 'npm install' inside the package itself.");
    process.exit(0);
}

// --- THIS IS THE CODE THAT RUNS ONLY IN THE MAIN APPLICATION ---

console.error("✅ Running custom script after installing as a dependency...");

// 1. **Add your desired functionality here** (e.g., creating a file, running a setup command, etc.)
// 2. You can access the main application's root via 'initialCwd' if needed.

// copy the flutter directory in the package to the public directory of the main application
const flutterDir = path.join(currentDir, 'public/flutter');
const publicDir = path.join(initialCwd, 'public/flutter');
require('fs').cpSync(flutterDir, publicDir, { recursive: true });

console.error("Script finished successfully.");
process.exit(0);

