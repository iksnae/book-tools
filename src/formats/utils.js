/**
 * Format Generator Utilities
 * 
 * Shared utility functions for format generators.
 */

const path = require('path');
const fs = require('fs');

/**
 * Get resource paths for a specific language
 * 
 * @param {string} projectRoot - Path to project root
 * @param {string} language - Language code
 * @returns {string} - Colon-separated list of resource paths
 */
function getResourcePaths(projectRoot, language) {
  return [
    '.', 
    'book', 
    `book/${language}`, 
    'build', 
    `book/${language}/images`, 
    'book/images', 
    'build/images', 
    `build/${language}/images`
  ].map(p => path.join(projectRoot, p))
   .join(':');
}

/**
 * Check if a path exists and is a file
 * 
 * @param {string} filePath - Path to check
 * @returns {boolean} - Whether the path exists and is a file
 */
function fileExists(filePath) {
  try {
    return fs.existsSync(filePath) && fs.statSync(filePath).isFile();
  } catch (error) {
    return false;
  }
}

/**
 * Check if a directory exists
 * 
 * @param {string} dirPath - Path to check
 * @returns {boolean} - Whether the path exists and is a directory
 */
function directoryExists(dirPath) {
  try {
    return fs.existsSync(dirPath) && fs.statSync(dirPath).isDirectory();
  } catch (error) {
    return false;
  }
}

/**
 * Find a template file in standard locations
 * 
 * @param {string} templateName - Template name
 * @param {string} format - Format (pdf, epub, html, docx)
 * @param {string} projectRoot - Path to project root
 * @returns {string|null} - Path to template file or null if not found
 */
function findTemplate(templateName, format, projectRoot) {
  // Check directly if it's an absolute path
  if (path.isAbsolute(templateName) && fileExists(templateName)) {
    return templateName;
  }
  
  // List of standard locations to check
  const locations = [
    // User-defined template in project
    templateName,
    path.join(projectRoot, templateName),
    path.join(projectRoot, 'templates', format, templateName),
    
    // Default templates in project
    path.join(projectRoot, 'templates', format, 'default.template'),
    path.join(projectRoot, 'templates', format, `default.${format}`),
    
    // Package templates
    path.join(__dirname, '..', '..', 'templates', format, templateName),
    path.join(__dirname, '..', '..', 'templates', format, 'default.template'),
    path.join(__dirname, '..', '..', 'templates', format, `default.${format}`)
  ];
  
  // Return the first valid template location
  for (const loc of locations) {
    if (fileExists(loc)) {
      return loc;
    }
  }
  
  // No template found
  return null;
}

/**
 * Create a standardized result object
 * 
 * @param {boolean} success - Whether the operation was successful
 * @param {string} format - Format (pdf, epub, html, docx, mobi)
 * @param {Object} data - Additional data
 * @returns {Object} - Result object
 */
function createResult(success, format, data = {}) {
  return {
    success,
    format,
    timestamp: new Date().toISOString(),
    ...data
  };
}

module.exports = {
  getResourcePaths,
  fileExists,
  directoryExists,
  findTemplate,
  createResult
};
