/**
 * Format building integration module
 * 
 * This module integrates the format generators with the main API
 * and provides backward compatibility with legacy scripts.
 */

const path = require('path');
const fs = require('fs');
const { runCommand } = require('./utils');
const { generateFormat } = require('./formats');

/**
 * Build a specific format using appropriate tools
 * 
 * @param {Object} config - Book configuration
 * @param {string} inputPath - Input markdown file path
 * @param {string} outputPath - Output file path
 * @param {string} format - Format to build (pdf, epub, html, mobi, docx)
 * @param {string} language - Language code
 * @param {string} projectRoot - Path to project root
 * @returns {Promise<boolean>} - Success status
 */
async function buildFormat(config, inputPath, outputPath, format, language, projectRoot) {
  // Use new format generators
  try {
    const result = await generateFormat(config, inputPath, outputPath, format, language, {
      projectRoot
    });
    
    if (result.success) {
      // Log warnings if present
      if (result.stderr) {
        console.warn(`Warnings during ${format} generation: ${result.stderr}`);
      }
      
      return true;
    } else {
      throw new Error(result.errorMessage || `Unknown error generating ${format}`);
    }
  } catch (error) {
    // Try legacy scripts as fallback if available
    return await tryLegacyScripts(config, inputPath, outputPath, format, language, projectRoot, error);
  }
}

/**
 * Try legacy script for format generation
 * 
 * @param {Object} config - Book configuration
 * @param {string} inputPath - Input markdown file path
 * @param {string} outputPath - Output file path
 * @param {string} format - Format to build (pdf, epub, html, mobi, docx)
 * @param {string} language - Language code
 * @param {string} projectRoot - Path to project root
 * @param {Error} originalError - Original error from modern generator
 * @returns {Promise<boolean>} - Success status
 */
async function tryLegacyScripts(config, inputPath, outputPath, format, language, projectRoot, originalError) {
  // Define paths to legacy scripts
  const scriptPaths = {
    pdf: path.join(__dirname, 'scripts', 'generate-pdf.sh'),
    epub: path.join(__dirname, 'scripts', 'generate-epub.sh'),
    html: path.join(__dirname, 'scripts', 'generate-html.sh'),
    mobi: path.join(__dirname, 'scripts', 'generate-mobi.sh'),
    docx: path.join(__dirname, 'scripts', 'generate-docx.sh')
  };
  
  // Check if legacy script exists for this format
  if (format in scriptPaths && fs.existsSync(scriptPaths[format])) {
    try {
      console.warn(`Trying legacy script for ${format} generation after error: ${originalError.message}`);
      
      // Build command to run legacy script
      const command = `${scriptPaths[format]} --input="${inputPath}" --output="${outputPath}" --lang="${language}"`;
      
      // Run legacy script
      await runCommand(command);
      console.warn(`Legacy script for ${format} generation succeeded`);
      return true;
    } catch (legacyError) {
      throw new Error(`Both modern and legacy ${format} generation failed: ${legacyError.message}`);
    }
  } else {
    // If no legacy script exists, propagate the original error
    throw originalError;
  }
}

module.exports = {
  buildFormat
};
