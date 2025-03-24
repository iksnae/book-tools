/**
 * MOBI Generator Module
 * 
 * This module provides functions for generating MOBI output
 * from markdown or EPUB sources using calibre or kindlegen.
 */

const path = require('path');
const fs = require('fs');
const { runCommand } = require('../utils');
const { fileExists, createResult } = require('./utils');
const { generateEPUB } = require('./epub');

/**
 * Generate MOBI from markdown
 * 
 * @param {Object} config - Book configuration
 * @param {string} inputPath - Path to input markdown file
 * @param {string} outputPath - Path to output MOBI file
 * @param {string} language - Language code
 * @param {Object} options - Additional options
 * @returns {Promise<Object>} - Result of MOBI generation
 */
async function generateMOBI(config, inputPath, outputPath, language, options = {}) {
  try {
    // MOBI requires EPUB first
    const epubPath = options.epubPath || outputPath.replace(/\.mobi$/, '.epub');
    
    // Generate EPUB if it doesn't exist
    if (!fileExists(epubPath)) {
      const epubResult = await generateEPUB(config, inputPath, epubPath, language);
      if (!epubResult.success) {
        throw new Error(`Failed to generate EPUB for MOBI conversion: ${epubResult.errorMessage || 'unknown error'}`);
      }
    }
    
    // Try multiple conversion tools for MOBI
    try {
      // First try kindlegen if available
      return await generateMOBIWithKindlegen(epubPath, outputPath, config);
    } catch (kindlegenError) {
      console.warn(`Kindlegen failed or not available: ${kindlegenError.message}`);
      
      // Fallback to calibre
      try {
        return await generateMOBIWithCalibre(epubPath, outputPath, config);
      } catch (calibreError) {
        // If both fail, try pandoc directly (least preferred option)
        console.warn(`Calibre failed or not available: ${calibreError.message}`);
        return await generateMOBIWithPandoc(inputPath, outputPath, language, config);
      }
    }
  } catch (error) {
    return createResult(false, 'mobi', {
      error,
      errorMessage: error.message
    });
  }
}

/**
 * Generate MOBI using kindlegen
 * 
 * @param {string} epubPath - Path to input EPUB file
 * @param {string} outputPath - Path to output MOBI file
 * @param {Object} config - Book configuration
 * @returns {Promise<Object>} - Result of MOBI generation
 */
async function generateMOBIWithKindlegen(epubPath, outputPath, config) {
  // Kindlegen outputs to the same directory as input, so we need to move the file later
  const outputDir = path.dirname(epubPath);
  const outputName = path.basename(outputPath);
  
  const command = `kindlegen "${epubPath}" -o "${outputName}"`;
  
  try {
    const result = await runCommand(command);
    
    // Kindlegen outputs to the same directory as the input EPUB
    const kindlegenOutput = path.join(outputDir, outputName);
    
    // Move file to desired output location if needed
    if (kindlegenOutput !== outputPath && fs.existsSync(kindlegenOutput)) {
      fs.renameSync(kindlegenOutput, outputPath);
    }
    
    return createResult(true, 'mobi', {
      outputPath,
      generator: 'kindlegen',
      command,
      stdout: result.stdout,
      stderr: result.stderr
    });
  } catch (error) {
    throw new Error(`Kindlegen conversion failed: ${error.message}`);
  }
}

/**
 * Generate MOBI using Calibre's ebook-convert
 * 
 * @param {string} epubPath - Path to input EPUB file
 * @param {string} outputPath - Path to output MOBI file
 * @param {Object} config - Book configuration
 * @returns {Promise<Object>} - Result of MOBI generation
 */
async function generateMOBIWithCalibre(epubPath, outputPath, config) {
  const command = `ebook-convert "${epubPath}" "${outputPath}"`;
  
  try {
    const result = await runCommand(command);
    
    return createResult(true, 'mobi', {
      outputPath,
      generator: 'calibre',
      command,
      stdout: result.stdout,
      stderr: result.stderr
    });
  } catch (error) {
    throw new Error(`Calibre conversion failed: ${error.message}`);
  }
}

/**
 * Generate MOBI directly with pandoc as a last resort
 * 
 * @param {string} inputPath - Path to input markdown file
 * @param {string} outputPath - Path to output MOBI file
 * @param {string} language - Language code
 * @param {Object} config - Book configuration
 * @returns {Promise<Object>} - Result of MOBI generation
 */
async function generateMOBIWithPandoc(inputPath, outputPath, language, config) {
  console.warn('Falling back to direct pandoc MOBI generation (limited features)');
  
  const command = [
    'pandoc',
    `"${inputPath}"`,
    `-o "${outputPath}"`,
    '-t epub3',
    `--metadata=title:"${config.title || 'Untitled'}"`,
    `--metadata=author:"${config.author || 'Unknown Author'}"`,
    `--metadata=lang:"${language}"`,
    '--toc',
    '--toc-depth=2'
  ].join(' ');
  
  try {
    const result = await runCommand(command);
    
    return createResult(true, 'mobi', {
      outputPath,
      generator: 'pandoc',
      command,
      fallback: true,
      stdout: result.stdout,
      stderr: result.stderr
    });
  } catch (error) {
    return createResult(false, 'mobi', {
      error,
      errorMessage: `Pandoc MOBI generation failed: ${error.message}`
    });
  }
}

module.exports = {
  generateMOBI,
  generateMOBIWithKindlegen,
  generateMOBIWithCalibre,
  generateMOBIWithPandoc
};
