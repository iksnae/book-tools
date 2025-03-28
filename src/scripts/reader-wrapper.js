/**
 * Reader wrapper script for enhancing HTML output with an ebook-like reader experience
 * 
 * This script processes the HTML output from Pandoc and wraps it in a template
 * that provides an enhanced reading experience with customizable text size,
 * font family, themes, and other options.
 */

const fs = require('fs');
const path = require('path');

/**
 * Process HTML output and wrap it in the reader template
 * 
 * @param {string} htmlPath - Path to the HTML file
 * @param {Object} options - Processing options
 * @returns {Promise<boolean>} - Success status
 */
async function wrapHtmlInReader(htmlPath, options = {}) {
  try {
    // Read the HTML content
    const htmlContent = fs.readFileSync(htmlPath, 'utf8');
    
    // Extract title from HTML
    let title = 'Untitled Book';
    const titleMatch = htmlContent.match(/<title>(.*?)<\/title>/i);
    if (titleMatch && titleMatch[1]) {
      title = titleMatch[1];
    }
    
    // Extract body content
    let bodyContent = htmlContent;
    const bodyMatch = htmlContent.match(/<body[^>]*>([\s\S]*?)<\/body>/i);
    if (bodyMatch && bodyMatch[1]) {
      bodyContent = bodyMatch[1];
    }
    
    // Read the reader template
    const projectRoot = options.projectRoot || process.cwd();
    const templatePath = path.join(projectRoot, 'templates', 'html', 'reader', 'reader-template.html');
    const template = fs.readFileSync(templatePath, 'utf8');
    
    // Replace placeholders in template
    let processedHTML = template.replace(/\${BOOK_TITLE}/g, title);
    processedHTML = processedHTML.replace(/\${BOOK_CONTENT}/g, bodyContent);
    
    // Write the processed HTML back to the original file
    fs.writeFileSync(htmlPath, processedHTML);
    
    // Copy reader assets (CSS and JS) to the output directory
    const outputDir = path.dirname(htmlPath);
    const cssPath = path.join(projectRoot, 'templates', 'html', 'reader', 'reader.css');
    const jsPath = path.join(projectRoot, 'templates', 'html', 'reader', 'reader.js');
    
    fs.copyFileSync(cssPath, path.join(outputDir, 'reader.css'));
    fs.copyFileSync(jsPath, path.join(outputDir, 'reader.js'));
    
    console.log(`Enhanced reader experience applied to ${htmlPath}`);
    return true;
  } catch (error) {
    console.error(`Error applying reader template: ${error.message}`);
    return false;
  }
}

/**
 * Check if directory exists, create it if it doesn't
 * 
 * @param {string} dirPath - Path to check/create
 */
function ensureDirectoryExists(dirPath) {
  if (!fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true });
  }
}

/**
 * Create reader templates and assets if they don't exist
 * 
 * @param {string} projectRoot - Path to project root
 */
function ensureReaderFiles(projectRoot) {
  const readerDir = path.join(projectRoot, 'templates', 'html', 'reader');
  ensureDirectoryExists(readerDir);
  
  // Check if reader template files exist, return status
  return fs.existsSync(path.join(readerDir, 'reader-template.html')) &&
         fs.existsSync(path.join(readerDir, 'reader.css')) &&
         fs.existsSync(path.join(readerDir, 'reader.js'));
}

/**
 * Returns whether a file exists
 * 
 * @param {string} filePath - Path to check
 * @returns {boolean} - Whether the file exists
 */
function fileExists(filePath) {
  return fs.existsSync(filePath);
}

module.exports = {
  wrapHtmlInReader,
  ensureReaderFiles,
  fileExists
};
