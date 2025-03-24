const path = require('path');
const fs = require('fs');
const { 
  findProjectRoot, 
  loadBookConfig, 
  ensureDirectoryExists,
  buildFileNames,
  runCommand,
  createPandocCommand
} = require('./utils');

/**
 * Build a book in the specified format(s) with extended configuration support
 * 
 * @param {Object} options - Build options
 * @param {boolean} [options.allLanguages=false] - Whether to build for all languages
 * @param {string} [options.language='en'] - Language to build for
 * @param {Array<string>} [options.formats=['pdf']] - Formats to build
 * @returns {Promise<Object>} - Build result
 */
async function buildBook(options = {}) {
  try {
    const projectRoot = findProjectRoot();
    const config = loadBookConfig(projectRoot);
    
    const languages = options.allLanguages 
      ? config.languages 
      : [options.language || 'en'];
    
    const formats = options.formats || ['pdf'];
    
    const results = [];
    
    for (const language of languages) {
      const fileNames = buildFileNames(language, projectRoot);
      
      // Ensure build directory exists
      const buildDir = path.dirname(fileNames.input);
      ensureDirectoryExists(buildDir);
      
      const buildResult = {
        success: true,
        language,
        formats,
        files: {
          input: fileNames.input
        }
      };
      
      // Combine markdown files
      await combineMarkdownFiles(projectRoot, language, fileNames.input);
      
      // Build each requested format
      for (const format of formats) {
        if (fileNames[format]) {
          try {
            await buildFormat(config, fileNames.input, fileNames[format], format, language, projectRoot);
            buildResult.files[format] = fileNames[format];
          } catch (formatError) {
            console.error(`Error building ${format}: ${formatError.message}`);
            if (formatError.stderr) {
              console.error(`Error details: ${formatError.stderr}`);
            }
          }
        }
      }
      
      results.push(buildResult);
    }
    
    // Return the first result for simplicity if only building one language
    return languages.length === 1 ? results[0] : { success: true, results };
  } catch (error) {
    return {
      success: false,
      error
    };
  }
}

/**
 * Combine markdown files for a specific language
 * 
 * @param {string} projectRoot - Path to project root
 * @param {string} language - Language code
 * @param {string} outputPath - Path to combined markdown file
 * @returns {Promise<boolean>} - Success status
 */
async function combineMarkdownFiles(projectRoot, language, outputPath) {
  // This is a placeholder for the actual implementation
  // It would scan directories, combine files, etc.
  
  // For now, we'll create a sample markdown file if none exists
  const languageDir = path.join(projectRoot, 'book', language);
  
  if (!fs.existsSync(languageDir)) {
    console.warn(`Language directory ${languageDir} not found, creating sample.`);
    ensureDirectoryExists(languageDir);
    
    // Create a sample chapter
    const sampleChapterDir = path.join(languageDir, 'chapter-01');
    ensureDirectoryExists(sampleChapterDir);
    
    // Create a sample markdown file
    const sampleFile = path.join(sampleChapterDir, '01-sample.md');
    if (!fs.existsSync(sampleFile)) {
      fs.writeFileSync(sampleFile, '# Sample Chapter\n\nThis is a sample chapter created automatically.');
    }
  }
  
  // Find all markdown files in the language directory
  const markdownFiles = findMarkdownFiles(languageDir);
  
  if (markdownFiles.length === 0) {
    throw new Error(`No markdown files found in ${languageDir}`);
  }
  
  // Combine files
  const combinedContent = markdownFiles.map(file => fs.readFileSync(file, 'utf-8')).join('\n\n');
  
  // Write to output file
  ensureDirectoryExists(path.dirname(outputPath));
  fs.writeFileSync(outputPath, combinedContent);
  
  return true;
}

/**
 * Find all markdown files in a directory recursively
 * 
 * @param {string} dir - Directory to search
 * @returns {Array<string>} - List of markdown file paths
 */
function findMarkdownFiles(dir) {
  let results = [];
  
  if (!fs.existsSync(dir)) {
    return results;
  }
  
  const list = fs.readdirSync(dir);
  
  for (const file of list) {
    const filePath = path.join(dir, file);
    const stat = fs.statSync(filePath);
    
    if (stat.isDirectory() && file !== 'images') {
      // Recursively search subdirectories, but skip images directories
      results = results.concat(findMarkdownFiles(filePath));
    } else if (file.endsWith('.md')) {
      results.push(filePath);
    }
  }
  
  // Sort by directory/filename
  return results.sort();
}

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
  // Define resource paths
  const resourcePaths = [
    '.', 
    'book', 
    `book/${language}`, 
    'build', 
    `book/${language}/images`, 
    'book/images', 
    'build/images', 
    `build/${language}/images`
  ].join(':');
  
  // For PDF, EPUB, HTML, and DOCX, use pandoc
  if (format === 'pdf' || format === 'epub' || format === 'html' || format === 'docx') {
    const command = createPandocCommand(config, inputPath, outputPath, format, language, resourcePaths);
    
    try {
      const result = await runCommand(command);
      if (result.stderr) {
        console.warn(`Warnings during ${format} generation: ${result.stderr}`);
      }
      return true;
    } catch (error) {
      // Try with fallback settings if there's an error
      if (config.formatSettings?.[format]?.fallback !== false) {
        console.warn(`Error in ${format} generation, trying with fallback settings`);
        try {
          // Create a minimal pandoc command without custom settings
          const formatType = format === 'pdf' ? 'latex' : format;
          const fallbackCmd = `pandoc "${inputPath}" -o "${outputPath}" -t ${formatType} --metadata=title:"${config.title}" --metadata=author:"${config.author}" --metadata=lang:"${language}"`;
          await runCommand(fallbackCmd);
          console.warn(`Fallback ${format} generation succeeded`);
          return true;
        } catch (fallbackError) {
          throw new Error(`Both primary and fallback ${format} generation failed: ${fallbackError.message}`);
        }
      } else {
        throw error;
      }
    }
  } else if (format === 'mobi') {
    // For MOBI, we need EPUB first
    const epubPath = outputPath.replace(/\.mobi$/, '.epub');
    
    if (!fs.existsSync(epubPath)) {
      // Generate EPUB first
      await buildFormat(config, inputPath, epubPath, 'epub', language, projectRoot);
    }
    
    // Then convert EPUB to MOBI
    try {
      // First try kindlegen if available
      try {
        const kindlegenCmd = `kindlegen "${epubPath}" -o "${path.basename(outputPath)}"`;
        await runCommand(kindlegenCmd);
        return true;
      } catch (kindleGenError) {
        // If kindlegen fails, try calibre
        console.warn('Kindlegen failed or not available, trying calibre');
        const calibreCmd = `ebook-convert "${epubPath}" "${outputPath}"`;
        await runCommand(calibreCmd);
        return true;
      }
    } catch (error) {
      throw new Error(`MOBI conversion failed: ${error.message}`);
    }
  } else {
    throw new Error(`Unsupported format: ${format}`);
  }
}

/**
 * Create a new chapter
 * 
 * @param {Object} options - Chapter options
 * @param {string} options.chapterNumber - Chapter number (e.g., "01")
 * @param {string} options.title - Chapter title
 * @param {string} [options.language='en'] - Language code
 * @returns {Promise<Object>} - Result object
 */
async function createChapter(options) {
  try {
    const projectRoot = findProjectRoot();
    const language = options.language || 'en';
    const chapterNumber = options.chapterNumber;
    const title = options.title;
    
    // Create chapter directory
    const chapterDir = path.join(projectRoot, 'book', language, `chapter-${chapterNumber}`);
    ensureDirectoryExists(chapterDir);
    
    // Create introduction file
    const introFile = path.join(chapterDir, '00-introduction.md');
    fs.writeFileSync(introFile, `# ${title}\n\nIntroduction to the chapter.\n`);
    
    // Create images directory
    const imagesDir = path.join(chapterDir, 'images');
    ensureDirectoryExists(imagesDir);
    
    // Create README in images directory
    const imagesReadme = path.join(imagesDir, 'README.md');
    fs.writeFileSync(imagesReadme, `# Images for Chapter ${chapterNumber}\n\nPlace chapter images in this directory.\n`);
    
    return {
      success: true,
      chapterNumber,
      chapterTitle: title,
      language,
      path: chapterDir,
      files: [
        introFile,
        imagesReadme
      ]
    };
  } catch (error) {
    return {
      success: false,
      error
    };
  }
}

/**
 * Check the structure of a chapter
 * 
 * @param {Object} options - Chapter options
 * @param {string} options.chapterNumber - Chapter number (e.g., "01")
 * @param {string} [options.language='en'] - Language code
 * @returns {Promise<Object>} - Result with chapter information
 */
async function checkChapter(options) {
  try {
    const projectRoot = findProjectRoot();
    const language = options.language || 'en';
    const chapterNumber = options.chapterNumber;
    
    const chapterDir = path.join(projectRoot, 'book', language, `chapter-${chapterNumber}`);
    
    if (!fs.existsSync(chapterDir)) {
      return {
        success: false,
        error: new Error(`Chapter directory not found: ${chapterDir}`)
      };
    }
    
    // Check for introduction file
    const introFile = path.join(chapterDir, '00-introduction.md');
    const hasIntro = fs.existsSync(introFile);
    
    // Check for any section files
    const files = fs.readdirSync(chapterDir);
    const sectionFiles = files.filter(file => 
      file.match(/^\d{2}-.*\.md$/) && !file.startsWith('00-')
    );
    const hasSection = sectionFiles.length > 0;
    
    // Check for images directory
    const imagesDir = path.join(chapterDir, 'images');
    const hasImagesDir = fs.existsSync(imagesDir);
    
    // Get all markdown files
    const markdownFiles = files
      .filter(file => file.endsWith('.md'))
      .map(file => {
        const filePath = path.join(chapterDir, file);
        let title = '';
        
        try {
          const content = fs.readFileSync(filePath, 'utf-8');
          const titleMatch = content.match(/^#\s+(.+)$/m);
          if (titleMatch) {
            title = titleMatch[1].trim();
          }
        } catch (e) {
          // Ignore errors
        }
        
        return {
          name: file,
          title
        };
      });
    
    // Get images if the directory exists
    let images = [];
    if (hasImagesDir) {
      try {
        images = fs.readdirSync(imagesDir)
          .filter(file => !file.endsWith('.md'));
      } catch (e) {
        // Ignore errors
      }
    }
    
    return {
      success: true,
      language,
      chapterNumber,
      hasIntro,
      hasSection,
      hasImagesDir,
      markdownFiles,
      images
    };
  } catch (error) {
    return {
      success: false,
      error
    };
  }
}

/**
 * Get book information with extended configuration
 * 
 * @returns {Promise<Object>} - Book information
 */
async function getBookInfo() {
  try {
    const projectRoot = findProjectRoot();
    const config = loadBookConfig(projectRoot);
    
    // Look for built files
    const builtFiles = [];
    
    // Check the build directory for each language
    for (const language of config.languages || ['en']) {
      const buildDir = path.join(projectRoot, 'build', language);
      
      if (fs.existsSync(buildDir)) {
        try {
          const files = fs.readdirSync(buildDir);
          
          files.forEach(file => {
            if (file !== 'book.md' && !file.endsWith('.tmp')) {
              builtFiles.push(path.join(buildDir, file));
            }
          });
        } catch (e) {
          // Ignore errors
        }
      }
    }
    
    return {
      ...config,
      builtFiles
    };
  } catch (error) {
    return {
      title: 'Unknown',
      error
    };
  }
}

/**
 * Clean build artifacts
 * 
 * @returns {Promise<Object>} - Result of cleaning
 */
async function cleanBuild() {
  try {
    const projectRoot = findProjectRoot();
    const config = loadBookConfig(projectRoot);
    
    let filesRemoved = 0;
    
    // Remove files from build directory for each language
    for (const language of config.languages || ['en']) {
      const buildDir = path.join(projectRoot, 'build', language);
      
      if (fs.existsSync(buildDir)) {
        try {
          const files = fs.readdirSync(buildDir);
          
          for (const file of files) {
            const filePath = path.join(buildDir, file);
            fs.unlinkSync(filePath);
            filesRemoved++;
          }
        } catch (e) {
          // Ignore errors
        }
      }
    }
    
    return {
      success: true,
      filesRemoved
    };
  } catch (error) {
    return {
      success: false,
      error
    };
  }
}

/**
 * Build book with improved error handling and recovery
 * 
 * @param {Object} options - Build options
 * @returns {Promise<Object>} - Build result
 */
async function buildBookWithRecovery(options = {}) {
  try {
    // First try the normal build
    return await buildBook(options);
  } catch (primaryError) {
    console.warn(`Primary build attempt failed: ${primaryError.message}`);
    console.warn('Attempting recovery build...');
    
    try {
      // Try again with minimal settings
      const recoveryOptions = {
        ...options,
        recovery: true // Flag to indicate recovery mode
      };
      
      return await buildBook(recoveryOptions);
    } catch (recoveryError) {
      console.error(`Recovery build also failed: ${recoveryError.message}`);
      
      // Create emergency minimal output
      return {
        success: false,
        error: primaryError,
        recoveryError,
        emergencyFiles: await createEmergencyOutput(options)
      };
    }
  }
}

/**
 * Create emergency minimal output files
 * 
 * @param {Object} options - Build options
 * @returns {Promise<Object>} - Emergency files created
 */
async function createEmergencyOutput(options) {
  const projectRoot = findProjectRoot();
  const language = options.language || 'en';
  const fileNames = buildFileNames(language, projectRoot);
  
  // Create a minimal emergency output
  // This ensures the build process completes with at least some output
  const emergencyFiles = {};
  
  try {
    // Create minimal HTML file
    const htmlContent = `<!DOCTYPE html>
<html>
<head>
  <title>Emergency Output</title>
</head>
<body>
  <h1>Emergency Output</h1>
  <p>The build process encountered errors. This is an emergency output.</p>
</body>
</html>`;
    
    fs.writeFileSync(fileNames.html, htmlContent);
    emergencyFiles.html = fileNames.html;

    // Create a minimal DOCX file with emergency content if docx is requested
    if (options.formats?.includes('docx')) {
      try {
        const fallbackDocxCmd = `pandoc -o "${fileNames.docx}" -t docx --metadata=title:"Emergency Output" --metadata=author:"Book Tools" << EOF
# Emergency Output

The build process encountered errors. This is an emergency output.
EOF`;
        await runCommand(fallbackDocxCmd, { shell: true });
        emergencyFiles.docx = fileNames.docx;
      } catch (e) {
        // Ignore errors in emergency output generation
      }
    }
  } catch (e) {
    // Ignore errors during emergency output
  }
  
  return emergencyFiles;
}

module.exports = {
  buildBook,
  buildBookWithRecovery,
  createChapter,
  checkChapter,
  getBookInfo,
  cleanBuild
};
