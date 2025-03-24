/**
 * PDF Generator Module
 * 
 * This module provides functions for generating PDF output
 * from markdown sources using pandoc.
 */

const path = require('path');
const fs = require('fs');
const { runCommand, createPandocCommand } = require('../utils');
const { getResourcePaths } = require('./utils');

/**
 * Generate PDF from markdown
 * 
 * @param {Object} config - Book configuration
 * @param {string} inputPath - Path to input markdown file
 * @param {string} outputPath - Path to output PDF file
 * @param {string} language - Language code
 * @param {Object} options - Additional options
 * @returns {Promise<Object>} - Result of PDF generation
 */
async function generatePDF(config, inputPath, outputPath, language, options = {}) {
  try {
    // Get resource paths for this language
    const projectRoot = path.dirname(path.dirname(path.dirname(inputPath)));
    const resourcePaths = getResourcePaths(projectRoot, language);
    
    // Generate pandoc command
    const command = createPandocCommand(
      config,
      inputPath, 
      outputPath, 
      'pdf', 
      language, 
      resourcePaths
    );
    
    // Execute command
    try {
      const result = await runCommand(command);
      return {
        success: true,
        format: 'pdf',
        outputPath,
        command,
        stdout: result.stdout,
        stderr: result.stderr
      };
    } catch (error) {
      // Try fallback if configured
      if (config.formatSettings?.pdf?.fallback !== false) {
        return await generateFallbackPDF(config, inputPath, outputPath, language);
      }
      throw error;
    }
  } catch (error) {
    return {
      success: false,
      format: 'pdf',
      error,
      errorMessage: error.message
    };
  }
}

/**
 * Generate PDF with fallback settings
 * 
 * @param {Object} config - Book configuration
 * @param {string} inputPath - Path to input markdown file
 * @param {string} outputPath - Path to output PDF file
 * @param {string} language - Language code
 * @returns {Promise<Object>} - Result of fallback PDF generation
 */
async function generateFallbackPDF(config, inputPath, outputPath, language) {
  try {
    console.warn(`Falling back to minimal PDF settings for ${outputPath}`);
    
    // Create a minimal pandoc command
    const fallbackCmd = [
      'pandoc',
      `"${inputPath}"`,
      `-o "${outputPath}"`,
      '-t latex',
      `--metadata=title:"${config.title || 'Untitled'}"`,
      `--metadata=author:"${config.author || 'Unknown Author'}"`,
      `--metadata=lang:"${language}"`,
      '--pdf-engine=xelatex',
      '--variable=papersize:letter',
      '--variable=fontsize:11pt',
      '--table-of-contents'
    ].join(' ');
    
    const result = await runCommand(fallbackCmd);
    
    return {
      success: true,
      format: 'pdf',
      outputPath,
      command: fallbackCmd,
      fallback: true,
      stdout: result.stdout,
      stderr: result.stderr
    };
  } catch (error) {
    return {
      success: false,
      format: 'pdf',
      error,
      errorMessage: `Fallback PDF generation failed: ${error.message}`
    };
  }
}

/**
 * Check if a LaTeX template exists and is valid
 * 
 * @param {string} templatePath - Path to LaTeX template
 * @returns {boolean} - Whether the template is valid
 */
function validateLaTeXTemplate(templatePath) {
  if (!templatePath) return false;
  
  try {
    const stats = fs.statSync(templatePath);
    return stats.isFile() && stats.size > 0;
  } catch (error) {
    return false;
  }
}

module.exports = {
  generatePDF,
  generateFallbackPDF,
  validateLaTeXTemplate
};
