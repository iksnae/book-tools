const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');
const { loadConfig, getDefaultConfig } = require('./config');

/**
 * Find the project root directory by looking for book.yaml
 * 
 * @returns {string} - Path to the project root
 * @throws {Error} - If project root could not be found
 */
function findProjectRoot() {
  let currentDir = process.cwd();
  const root = path.parse(currentDir).root;
  
  while (currentDir !== root) {
    if (fs.existsSync(path.join(currentDir, 'book.yaml'))) {
      return currentDir;
    }
    
    currentDir = path.dirname(currentDir);
  }
  
  throw new Error('Could not find project root (book.yaml not found in parent directories)');
}

/**
 * Load book configuration from book.yaml with extended support
 * 
 * @param {string} projectRoot - Path to the project root
 * @returns {Object} - Book configuration
 */
function loadBookConfig(projectRoot) {
  const configPath = path.join(projectRoot, 'book.yaml');
  return loadConfig(configPath);
}

/**
 * Ensure a directory exists, creating it if necessary
 * 
 * @param {string} dirPath - Path to the directory
 */
function ensureDirectoryExists(dirPath) {
  if (!fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true });
  }
}

/**
 * Build file names for a book in a specific language
 * 
 * @param {string} language - Language code
 * @param {string} projectRoot - Path to the project root
 * @returns {Object} - Object with file paths for input and outputs
 */
function buildFileNames(language, projectRoot) {
  const config = loadBookConfig(projectRoot);
  const filePrefix = config.file_prefix || config.filePrefix || 'book';
  
  const buildDir = path.join(projectRoot, 'build', language);
  
  return {
    input: path.join(buildDir, 'book.md'),
    pdf: path.join(buildDir, `${filePrefix}.pdf`),
    epub: path.join(buildDir, `${filePrefix}.epub`),
    mobi: path.join(buildDir, `${filePrefix}.mobi`),
    html: path.join(buildDir, `${filePrefix}.html`),
    docx: path.join(buildDir, `${filePrefix}.docx`)
  };
}

/**
 * Run a script with the provided arguments
 * 
 * @param {string} scriptPath - Path to the script
 * @param {string[]} args - Array of arguments
 * @returns {Promise<Object>} - Result of the script execution
 */
function runScript(scriptPath, args = []) {
  return new Promise((resolve, reject) => {
    const command = `"${scriptPath}" ${args.join(' ')}`;
    
    exec(command, (error, stdout, stderr) => {
      if (error) {
        reject(error);
        return;
      }
      
      resolve({
        success: true,
        stdout,
        stderr
      });
    });
  });
}

/**
 * Run a command with error handling
 * 
 * @param {string} command - Command to run
 * @param {object} options - Options for child_process.exec
 * @returns {Promise<object>} - Result of the command execution
 */
function runCommand(command, options = {}) {
  return new Promise((resolve, reject) => {
    exec(command, options, (error, stdout, stderr) => {
      if (error) {
        // Include the stderr in the error for better diagnostics
        error.stderr = stderr;
        error.stdout = stdout;
        reject(error);
        return;
      }
      
      resolve({
        success: true,
        stdout,
        stderr
      });
    });
  });
}

/**
 * Create pandoc command for converting markdown to a specific format
 * 
 * @param {Object} config - Book configuration
 * @param {string} inputPath - Path to input markdown file
 * @param {string} outputPath - Path to output file
 * @param {string} format - Output format (pdf, epub, html, docx)
 * @param {string} language - Language code
 * @param {string} resourcePaths - Search paths for resources
 * @returns {string} - Pandoc command
 */
function createPandocCommand(config, inputPath, outputPath, format, language, resourcePaths = '') {
  // Get pandoc arguments from config
  const { getPandocArgs } = require('./config');
  const args = getPandocArgs(config, format, language);
  
  // Make sure the output directory exists
  ensureDirectoryExists(path.dirname(outputPath));
  
  // Add input and output files
  const formatArg = format === 'pdf' ? 'latex' : format;
  const command = [
    'pandoc',
    `"${inputPath}"`,
    `-o "${outputPath}"`,
    `-t ${formatArg}`,
    args.join(' ')
  ];
  
  // Add resource paths if provided
  if (resourcePaths) {
    command.push(`--resource-path="${resourcePaths}"`);
  }
  
  // Special handling for EPUB - ensure we explicitly extract media
  if (format === 'epub') {
    const mediaDir = path.join(path.dirname(outputPath), 'media');
    ensureDirectoryExists(mediaDir);
    command.push(`--extract-media="${mediaDir}"`);
  }
  
  // For DOCX, check if reference_doc exists and add error handler if not
  if (format === 'docx') {
    const docxSettings = config.formatSettings?.docx || config.docx || {};
    const referenceDoc = docxSettings.referenceDoc || docxSettings.reference_doc;
    
    // Log warning if reference doc is specified but doesn't exist
    if (referenceDoc && !fs.existsSync(referenceDoc)) {
      console.warn(`Warning: DOCX reference document '${referenceDoc}' not found. Using default styles.`);
    }
  }
  
  return command.join(' ');
}

module.exports = {
  findProjectRoot,
  loadBookConfig,
  ensureDirectoryExists,
  buildFileNames,
  runScript,
  runCommand,
  createPandocCommand
};