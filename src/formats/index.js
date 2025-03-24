/**
 * Format Generators Module
 * 
 * This module provides a unified API for generating different output formats 
 * from markdown sources. It supports PDF, EPUB, MOBI, HTML, and DOCX formats.
 */

const path = require('path');
const { ensureDirectoryExists } = require('../utils');

// Import format-specific generators
const pdfGenerator = require('./pdf');
const epubGenerator = require('./epub');
const htmlGenerator = require('./html');
const docxGenerator = require('./docx');
const mobiGenerator = require('./mobi');

/**
 * Generate a specific format from markdown sources
 * 
 * @param {Object} config - Book configuration
 * @param {string} inputPath - Path to input markdown file
 * @param {string} outputPath - Path to output file
 * @param {string} format - Output format (pdf, epub, html, mobi, docx)
 * @param {string} language - Language code
 * @param {Object} options - Additional options
 * @returns {Promise<Object>} - Result of format generation
 */
async function generateFormat(config, inputPath, outputPath, format, language, options = {}) {
  // Ensure output directory exists
  ensureDirectoryExists(path.dirname(outputPath));
  
  // Generate the requested format
  switch (format.toLowerCase()) {
    case 'pdf':
      return await pdfGenerator.generatePDF(config, inputPath, outputPath, language, options);
    case 'epub':
      return await epubGenerator.generateEPUB(config, inputPath, outputPath, language, options);
    case 'html':
      return await htmlGenerator.generateHTML(config, inputPath, outputPath, language, options);
    case 'docx':
      return await docxGenerator.generateDOCX(config, inputPath, outputPath, language, options);
    case 'mobi':
      return await mobiGenerator.generateMOBI(config, inputPath, outputPath, language, options);
    default:
      throw new Error(`Unsupported format: ${format}`);
  }
}

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

module.exports = {
  generateFormat,
  getResourcePaths,
  // Export format-specific generators for direct access
  ...pdfGenerator,
  ...epubGenerator,
  ...htmlGenerator,
  ...docxGenerator,
  ...mobiGenerator
};
