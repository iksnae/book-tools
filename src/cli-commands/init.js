/**
 * Init command module
 * 
 * This module implements the `book init` command to initialize
 * a new book project with the specified template.
 */

const path = require('path');
const fs = require('fs');
const ora = require('ora');
const chalk = require('chalk');
const inquirer = require('inquirer');
const { ensureDirectoryExists } = require('../utils');

/**
 * Configure the init command
 * 
 * @param {Object} program - Commander program instance
 */
function configureInitCommand(program) {
  program
    .command('init [template]')
    .description('Initialize a new book project')
    .option('-p, --path <path>', 'Path to create project', './')
    .option('-n, --name <name>', 'Name of the book')
    .option('-a, --author <author>', 'Author of the book')
    .option('-l, --languages <languages>', 'Comma-separated list of language codes', 'en')
    .option('-y, --yes', 'Skip confirmation prompts')
    .action(async (template, options) => {
      try {
        const spinner = ora('Initializing project...').start();
        
        // Use default template if none specified
        const templateName = template || 'standard';
        
        // If interactive mode (no --yes flag), prompt for missing details
        if (!options.yes) {
          spinner.stop();
          
          const answers = await inquirer.prompt([
            {
              type: 'input',
              name: 'name',
              message: 'Book title:',
              default: options.name || 'My Book',
              when: !options.name
            },
            {
              type: 'input',
              name: 'author',
              message: 'Author name:',
              default: options.author || process.env.USER || 'Author',
              when: !options.author
            },
            {
              type: 'input',
              name: 'languages',
              message: 'Language codes (comma-separated):',
              default: options.languages || 'en',
              when: !options.languages
            },
            {
              type: 'confirm',
              name: 'confirm',
              message: `Initialize project with template '${templateName}'?`,
              default: true
            }
          ]);
          
          // Update options with answers
          options.name = options.name || answers.name;
          options.author = options.author || answers.author;
          options.languages = options.languages || answers.languages;
          
          // Exit if not confirmed
          if (!answers.confirm) {
            console.log(chalk.yellow('Project initialization cancelled.'));
            return;
          }
          
          spinner.start();
        }
        
        // Create project
        const result = await initProject(templateName, options);
        
        if (result.success) {
          spinner.succeed(chalk.green(`Project initialized with ${templateName} template!`));
          console.log(chalk.blue('Project path:'), result.projectPath);
          console.log(chalk.blue('Created files:'));
          result.files.forEach(file => console.log(`- ${file}`));
          
          // Print next steps
          console.log(chalk.green('\nNext steps:'));
          if (options.path !== './') {
            console.log(`1. cd ${options.path}`);
          }
          console.log('2. Add your content to the book/ directory');
          console.log('3. Run `book build` to generate your book');
        } else {
          spinner.fail(chalk.red('Failed to initialize project'));
          if (result.error) {
            console.error(chalk.red(result.error.message));
          }
        }
      } catch (error) {
        console.error(chalk.red(`Error: ${error.message}`));
      }
    });
}

/**
 * Initialize a new book project with the specified template
 * 
 * @param {string} templateName - Template name
 * @param {Object} options - Project options
 * @returns {Promise<Object>} - Result object
 */
async function initProject(templateName, options) {
  try {
    // Resolve project path
    const projectPath = path.resolve(options.path);
    
    // Create base directories
    ensureDirectoryExists(projectPath);
    ensureDirectoryExists(path.join(projectPath, 'book'));
    ensureDirectoryExists(path.join(projectPath, 'templates'));
    ensureDirectoryExists(path.join(projectPath, 'build'));
    
    // Create language directories
    const languages = options.languages.split(',').map(lang => lang.trim());
    languages.forEach(lang => {
      ensureDirectoryExists(path.join(projectPath, 'book', lang));
      ensureDirectoryExists(path.join(projectPath, 'book', lang, 'chapter-01'));
      ensureDirectoryExists(path.join(projectPath, 'book', lang, 'images'));
    });
    
    // Create template subdirectories
    ensureDirectoryExists(path.join(projectPath, 'templates', 'pdf'));
    ensureDirectoryExists(path.join(projectPath, 'templates', 'epub'));
    ensureDirectoryExists(path.join(projectPath, 'templates', 'html'));
    ensureDirectoryExists(path.join(projectPath, 'templates', 'docx'));
    
    // Create configuration file (book.yaml)
    const bookYaml = createBookConfig(options);
    fs.writeFileSync(path.join(projectPath, 'book.yaml'), bookYaml);
    
    // Create sample content
    const sampleMarkdown = createSampleContent(options);
    languages.forEach(lang => {
      fs.writeFileSync(
        path.join(projectPath, 'book', lang, 'chapter-01', '01-introduction.md'),
        sampleMarkdown
      );
    });
    
    // Create GitHub Actions workflow
    const workflowDir = path.join(projectPath, '.github', 'workflows');
    ensureDirectoryExists(workflowDir);
    
    // Add placeholder for GitHub workflow
    // This will be implemented in a future PR
    
    // Create list of created files
    const createdFiles = [
      'book.yaml',
      'book/',
      'templates/',
      'build/',
      '.github/workflows/'
    ];
    
    return {
      success: true,
      projectPath,
      templateName,
      files: createdFiles
    };
  } catch (error) {
    return {
      success: false,
      error
    };
  }
}

/**
 * Create book.yaml configuration content
 * 
 * @param {Object} options - Project options
 * @returns {string} - YAML configuration content
 */
function createBookConfig(options) {
  // Convert book title to file prefix
  const filePrefix = options.name
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '');
  
  // Parse languages
  const languages = options.languages.split(',').map(lang => lang.trim());
  
  return `# Book Configuration File
title: "${options.name}"
author: "${options.author}"
filePrefix: "${filePrefix}"

# Languages
languages:
${languages.map(lang => `  - "${lang}"`).join('\n')}

# Output formats
formats:
  pdf: true
  epub: true
  mobi: true
  html: true
  docx: true

# Format-specific settings
formatSettings:
  pdf:
    paperSize: "letter"
    marginTop: "1in"
    marginBottom: "1in"
    marginLeft: "1in"
    marginRight: "1in"
    fontSize: "11pt"
    lineHeight: "1.5"
    template: "templates/pdf/default.latex"

  epub:
    coverImage: "book/images/cover.png"
    css: "templates/epub/style.css"
    tocDepth: 3

  html:
    template: "templates/html/default.html"
    css: "templates/html/style.css"
    toc: true
    tocDepth: 3
    sectionDivs: true
    selfContained: true

  docx:
    referenceDoc: "templates/docx/reference.docx"
    toc: true
    tocDepth: 3

# Output settings
output:
  filePrefix: "${filePrefix}"
  directory: "build"
  structure:
    languageSpecific: true
    combineMarkdown: true
`;
}

/**
 * Create sample markdown content
 * 
 * @param {Object} options - Project options
 * @returns {string} - Sample markdown content
 */
function createSampleContent(options) {
  return `# Introduction to ${options.name}

## Welcome to Your Book

This is a sample chapter. Replace this content with your own.

### Getting Started

1. Add your content to the \`book/\` directory
2. Run \`book build\` to generate your book
3. Find the output in the \`build/\` directory

### Next Steps

- Add more chapters
- Customize the templates in \`templates/\`
- Configure settings in \`book.yaml\`

> This is a blockquote. Replace it with your own inspiring quote.

---

*Build with book-tools*
`;
}

module.exports = {
  configureInitCommand
};
