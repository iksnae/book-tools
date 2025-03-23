const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const YAML = require('yaml');

/**
 * Find the project root (where book.yaml is located)
 * @returns {string} Path to the project root
 */
function findProjectRoot() {
  // Start from the current directory
  let currentDir = process.cwd();
  
  // Keep going up until we find book.yaml or hit the root
  while (currentDir !== '/') {
    if (fs.existsSync(path.join(currentDir, 'book.yaml'))) {
      return currentDir;
    }
    currentDir = path.dirname(currentDir);
  }
  
  // If we reach here, we didn't find the project root
  throw new Error('Could not find project root (book.yaml file). Make sure you\'re running this command within a book project.');
}

/**
 * Run a command in the project root
 * @param {string} command - The command to run
 * @param {boolean} silent - Whether to suppress output
 * @returns {string|null} Command output if silent is true, empty string otherwise
 */
function runCommand(command, silent = false) {
  const projectRoot = findProjectRoot();
  
  try {
    const output = execSync(command, { 
      cwd: projectRoot,
      stdio: silent ? 'pipe' : 'inherit'
    });
    
    return silent ? output.toString() : '';
  } catch (error) {
    if (silent) {
      return null;
    } else {
      throw new Error(`Error executing command: ${command}\n${error.toString()}`);
    }
  }
}

/**
 * Load the book.yaml config
 * @returns {Object} Parsed configuration
 */
function loadConfig() {
  const projectRoot = findProjectRoot();
  const configPath = path.join(projectRoot, 'book.yaml');
  
  try {
    if (fs.existsSync(configPath)) {
      const yamlContent = fs.readFileSync(configPath, 'utf8');
      return YAML.parse(yamlContent);
    } else {
      console.warn('Warning: book.yaml not found, using default configuration.');
      return {
        title: "My Book",
        subtitle: "A Book Built with the Template System",
        author: "Author Name",
        file_prefix: "my-book",
        languages: ["en"]
      };
    }
  } catch (error) {
    throw new Error(`Error parsing book.yaml: ${error.message}`);
  }
}

/**
 * Check if a directory exists, create it if it doesn't
 * @param {string} dirPath - Path to directory
 * @returns {boolean} True if directory exists or was created
 */
function ensureDirectoryExists(dirPath) {
  if (!fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true });
  }
  return true;
}

/**
 * Get the language codes configured in the project
 * @returns {string[]} Array of language codes
 */
function getLanguages() {
  const config = loadConfig();
  return config.languages || ['en'];
}

/**
 * Build file paths for a specific language
 * @param {string} language - Language code
 * @returns {Object} Object with file paths
 */
function buildFileNames(language) {
  const config = loadConfig();
  const filePrefix = config.file_prefix || 'book';
  
  if (language === 'en') {
    return {
      pdf: `${filePrefix}.pdf`,
      epub: `${filePrefix}.epub`,
      mobi: `${filePrefix}.mobi`,
      html: `${filePrefix}.html`,
      markdown: `${filePrefix}.md`
    };
  } else {
    return {
      pdf: `${filePrefix}-${language}.pdf`,
      epub: `${filePrefix}-${language}.epub`,
      mobi: `${filePrefix}-${language}.mobi`,
      html: `${filePrefix}-${language}.html`,
      markdown: `${filePrefix}-${language}.md`
    };
  }
}

module.exports = {
  findProjectRoot,
  runCommand,
  loadConfig,
  ensureDirectoryExists,
  getLanguages,
  buildFileNames
};