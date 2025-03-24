/**
 * DOCX Generator Module
 * 
 * This module provides functions for generating DOCX output
 * from markdown sources using pandoc.
 */

const path = require('path');
const fs = require('fs');
const { runCommand, createPandocCommand } = require('../utils');
const { getResourcePaths, fileExists, findTemplate, createResult } = require('./utils');

/**
 * Generate DOCX from markdown
 * 
 * @param {Object} config - Book configuration
 * @param {string} inputPath - Path to input markdown file
 * @param {string} outputPath - Path to output DOCX file
 * @param {string} language - Language code
 * @param {Object} options - Additional options
 * @returns {Promise<Object>} - Result of DOCX generation
 */
async function generateDOCX(config, inputPath, outputPath, language, options = {}) {
  try {
    // Get resource paths for this language
    const projectRoot = path.dirname(path.dirname(path.dirname(inputPath)));
    const resourcePaths = getResourcePaths(projectRoot, language);
    
    // Get DOCX-specific settings
    const docxSettings = config.formatSettings?.docx || {};
    
    // Check for reference document
    let hasReferenceDoc = false;
    let referenceDocPath = null;
    
    if (docxSettings.referenceDoc) {
      referenceDocPath = path.isAbsolute(docxSettings.referenceDoc)
        ? docxSettings.referenceDoc
        : path.join(projectRoot, docxSettings.referenceDoc);
      
      hasReferenceDoc = fileExists(referenceDocPath);
    }
    
    // Also check legacy format
    if (!hasReferenceDoc && docxSettings.reference_doc) {
      referenceDocPath = path.isAbsolute(docxSettings.reference_doc)
        ? docxSettings.reference_doc
        : path.join(projectRoot, docxSettings.reference_doc);
      
      hasReferenceDoc = fileExists(referenceDocPath);
    }
    
    // Also check standard location
    if (!hasReferenceDoc) {
      const standardReferenceDoc = path.join(projectRoot, 'templates', 'docx', 'reference.docx');
      if (fileExists(standardReferenceDoc)) {
        referenceDocPath = standardReferenceDoc;
        hasReferenceDoc = true;
      }
    }
    
    // Generate pandoc command
    const command = createPandocCommand(
      config,
      inputPath, 
      outputPath, 
      'docx', 
      language, 
      resourcePaths
    );
    
    // Execute command
    try {
      const result = await runCommand(command);
      return createResult(true, 'docx', {
        outputPath,
        command,
        hasReferenceDoc,
        referenceDocPath,
        stdout: result.stdout,
        stderr: result.stderr
      });
    } catch (error) {
      // Try fallback if configured
      if (docxSettings.fallback !== false) {
        return await generateFallbackDOCX(config, inputPath, outputPath, language);
      }
      throw error;
    }
  } catch (error) {
    return createResult(false, 'docx', {
      error,
      errorMessage: error.message
    });
  }
}

/**
 * Generate DOCX with fallback settings
 * 
 * @param {Object} config - Book configuration
 * @param {string} inputPath - Path to input markdown file
 * @param {string} outputPath - Path to output DOCX file
 * @param {string} language - Language code
 * @returns {Promise<Object>} - Result of fallback DOCX generation
 */
async function generateFallbackDOCX(config, inputPath, outputPath, language) {
  try {
    console.warn(`Falling back to minimal DOCX settings for ${outputPath}`);
    
    // Create a minimal pandoc command
    const fallbackCmd = [
      'pandoc',
      `"${inputPath}"`,
      `-o "${outputPath}"`,
      '-t docx',
      `--metadata=title:"${config.title || 'Untitled'}"`,
      `--metadata=author:"${config.author || 'Unknown Author'}"`,
      `--metadata=lang:"${language}"`,
      '--toc',
      '--toc-depth=2'
    ].join(' ');
    
    const result = await runCommand(fallbackCmd);
    
    return createResult(true, 'docx', {
      outputPath,
      command: fallbackCmd,
      fallback: true,
      stdout: result.stdout,
      stderr: result.stderr
    });
  } catch (error) {
    return createResult(false, 'docx', {
      error,
      errorMessage: `Fallback DOCX generation failed: ${error.message}`
    });
  }
}

/**
 * Create a reference DOCX template
 * 
 * @param {string} outputPath - Path to output reference DOCX
 * @param {Object} options - Template options
 * @returns {Promise<Object>} - Result of template creation
 */
async function createReferenceDOCX(outputPath, options = {}) {
  try {
    // Ensure parent directories exist
    const parentDir = path.dirname(outputPath);
    if (!fs.existsSync(parentDir)) {
      fs.mkdirSync(parentDir, { recursive: true });
    }
    
    // Create a temporary markdown file with basic formatting examples
    const tempMarkdown = path.join(path.dirname(outputPath), 'reference-template.md');
    
    // Write sample content
    const content = [
      `# Reference Document`,
      `## This is a level 2 heading`,
      `### This is a level 3 heading`,
      ``,
      `This is a paragraph with **bold** and *italic* text.`,
      ``,
      `* This is a bullet list`,
      `* With multiple items`,
      `  * And nested items`,
      ``,
      `1. This is a numbered list`,
      `2. With multiple items`,
      `   1. And nested items`,
      ``,
      `> This is a blockquote`,
      ``,
      `\`\`\``,
      `This is a code block`,
      `\`\`\``,
      ``,
      `| Column 1 | Column 2 | Column 3 |`,
      `|----------|----------|----------|`,
      `| Cell 1   | Cell 2   | Cell 3   |`,
      `| Cell 4   | Cell 5   | Cell 6   |`
    ].join('\n');
    
    fs.writeFileSync(tempMarkdown, content);
    
    // Generate DOCX with pandoc
    const command = [
      'pandoc',
      `"${tempMarkdown}"`,
      `-o "${outputPath}"`,
      '-t docx',
      '--metadata=title:"Reference Document"'
    ].join(' ');
    
    const result = await runCommand(command);
    
    // Clean up temp file
    if (fs.existsSync(tempMarkdown)) {
      fs.unlinkSync(tempMarkdown);
    }
    
    return createResult(true, 'docx', {
      outputPath,
      command,
      stdout: result.stdout,
      stderr: result.stderr
    });
  } catch (error) {
    return createResult(false, 'docx', {
      error,
      errorMessage: `Failed to create reference DOCX: ${error.message}`
    });
  }
}

module.exports = {
  generateDOCX,
  generateFallbackDOCX,
  createReferenceDOCX
};
