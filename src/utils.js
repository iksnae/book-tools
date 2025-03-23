const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');
const yaml = require('yaml');

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
 * Load book configuration from book.yaml
 * 
 * @param {string} projectRoot - Path to the project root
 * @returns {Object} - Book configuration
 */
function loadConfig(projectRoot) {
  const configPath = path.join(projectRoot, 'book.yaml');
  
  if (fs.existsSync(configPath)) {
    try {
      const configContent = fs.readFileSync(configPath, 'utf-8');
      return yaml.parse(configContent);
    } catch (error) {
      console.error(`Error reading config: ${error.message}`);
    }
  }
  
  // Return default configuration
  return {
    title: 'Untitled Book',
    subtitle: '',
    author: 'Unknown Author',
    filePrefix: 'book',
    languages: ['en']
  };
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
  const config = loadConfig(projectRoot);
  const filePrefix = config.filePrefix || 'book';
  
  const buildDir = path.join(projectRoot, 'build', language);
  
  return {
    input: path.join(buildDir, 'book.md'),
    pdf: path.join(buildDir, `${filePrefix}.pdf`),
    epub: path.join(buildDir, `${filePrefix}.epub`),
    mobi: path.join(buildDir, `${filePrefix}.mobi`),
    html: path.join(buildDir, `${filePrefix}.html`)
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

module.exports = {
  findProjectRoot,
  loadConfig,
  ensureDirectoryExists,
  buildFileNames,
  runScript
};