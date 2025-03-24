const { program } = require('commander');
const inquirer = require('inquirer');
const chalk = require('chalk');
const ora = require('ora');
const { 
  buildBook, 
  createChapter, 
  checkChapter, 
  getBookInfo, 
  cleanBuild,
  validateConfig
} = require('./index');

/**
 * Configure the Commander.js CLI
 */
function configureCLI() {
  program
    .name('book')
    .description('Book Tools CLI for building books from markdown sources')
    .version('0.1.0');

  // Build command
  program
    .command('build')
    .description('Build the book in various formats')
    .option('--all-languages', 'Build for all configured languages')
    .option('--lang <language>', 'Specify language to build (default: "en")')
    .option('--skip-pdf', 'Skip PDF generation')
    .option('--skip-epub', 'Skip EPUB generation')
    .option('--skip-mobi', 'Skip MOBI generation')
    .option('--skip-html', 'Skip HTML generation')
    .option('--legacy-scripts', 'Use legacy build scripts', true)
    .action(async (options) => {
      const spinner = ora('Building book...').start();
      try {
        const formats = [];
        if (!options.skipPdf) formats.push('pdf');
        if (!options.skipEpub) formats.push('epub');
        if (!options.skipMobi) formats.push('mobi');
        if (!options.skipHtml) formats.push('html');

        // First validate the configuration
        const validation = await validateConfig();
        if (!validation.success) {
          spinner.fail(chalk.red('Configuration validation failed'));
          validation.errors.forEach(error => {
            console.error(chalk.red(`Error: ${error}`));
          });
          return;
        }

        if (validation.warnings.length > 0) {
          spinner.warn(chalk.yellow('Configuration warnings:'));
          validation.warnings.forEach(warning => {
            console.warn(chalk.yellow(`Warning: ${warning}`));
          });
        }

        spinner.text = 'Building book...';
        spinner.start();

        const result = await buildBook({
          allLanguages: options.allLanguages,
          language: options.lang || 'en',
          formats,
          useLegacyScripts: options.legacyScripts
        });

        if (result.success) {
          spinner.succeed(chalk.green('Book built successfully!'));
          console.log(chalk.blue('Formats generated:'), formats.join(', '));
          if (result.files) {
            console.log(chalk.blue('Output files:'));
            Object.entries(result.files).forEach(([key, value]) => {
              if (key !== 'input') {
                console.log(`${key}: ${value}`);
              }
            });
          }
        } else {
          spinner.fail(chalk.red('Failed to build book'));
          if (result.error) {
            console.error(chalk.red(result.error.message));
          }
        }
      } catch (error) {
        spinner.fail(chalk.red('Error building book'));
        console.error(chalk.red(error.message));
      }
    });

  // Interactive command
  program
    .command('interactive')
    .description('Interactive build process')
    .action(async () => {
      try {
        const bookInfo = await getBookInfo();
        
        console.log(chalk.blue('Book information:'));
        console.log(chalk.cyan(`Title: ${bookInfo.title}`));
        console.log(chalk.cyan(`Author: ${bookInfo.author}`));
        console.log(chalk.cyan(`Available languages: ${bookInfo.languages.join(', ')}`));
        
        const answers = await inquirer.prompt([
          {
            type: 'list',
            name: 'language',
            message: 'Which language would you like to build?',
            choices: bookInfo.languages
          },
          {
            type: 'checkbox',
            name: 'formats',
            message: 'Which formats would you like to generate?',
            choices: [
              { name: 'PDF', value: 'pdf', checked: bookInfo.formats?.pdf },
              { name: 'EPUB', value: 'epub', checked: bookInfo.formats?.epub },
              { name: 'MOBI', value: 'mobi', checked: bookInfo.formats?.mobi },
              { name: 'HTML', value: 'html', checked: bookInfo.formats?.html }
            ]
          },
          {
            type: 'confirm',
            name: 'configureSettings',
            message: 'Would you like to configure format-specific settings?',
            default: false
          }
        ]);
        
        let formatSettings = bookInfo.formatSettings || {};
        
        // If user wants to configure format settings
        if (answers.configureSettings) {
          for (const format of answers.formats) {
            console.log(chalk.blue(`\nConfiguring ${format.toUpperCase()} settings:`));
            
            // Get current settings for this format
            const currentSettings = formatSettings[format] || {};
            
            if (format === 'pdf') {
              const pdfAnswers = await inquirer.prompt([
                {
                  type: 'list',
                  name: 'paperSize',
                  message: 'Paper size:',
                  choices: ['letter', 'a4', 'a5', 'b5'],
                  default: currentSettings.paperSize || 'letter'
                },
                {
                  type: 'input',
                  name: 'fontSize',
                  message: 'Font size (e.g., 11pt):',
                  default: currentSettings.fontSize || '11pt'
                },
                {
                  type: 'input',
                  name: 'lineHeight',
                  message: 'Line height (e.g., 1.5):',
                  default: currentSettings.lineHeight || '1.5'
                }
              ]);
              
              formatSettings.pdf = {
                ...currentSettings,
                ...pdfAnswers
              };
            } 
            else if (format === 'epub') {
              const epubAnswers = await inquirer.prompt([
                {
                  type: 'input',
                  name: 'coverImage',
                  message: 'Cover image path:',
                  default: currentSettings.coverImage || 'book/images/cover.png'
                },
                {
                  type: 'input',
                  name: 'tocDepth',
                  message: 'Table of contents depth:',
                  default: currentSettings.tocDepth || 3,
                  validate: input => !isNaN(input) ? true : 'Please enter a number'
                }
              ]);
              
              formatSettings.epub = {
                ...currentSettings,
                ...epubAnswers,
                tocDepth: parseInt(epubAnswers.tocDepth)
              };
            }
            else if (format === 'html') {
              const htmlAnswers = await inquirer.prompt([
                {
                  type: 'confirm',
                  name: 'toc',
                  message: 'Include table of contents?',
                  default: currentSettings.toc !== false
                },
                {
                  type: 'input',
                  name: 'tocDepth',
                  message: 'Table of contents depth:',
                  default: currentSettings.tocDepth || 3,
                  validate: input => !isNaN(input) ? true : 'Please enter a number'
                },
                {
                  type: 'confirm',
                  name: 'selfContained',
                  message: 'Create self-contained HTML?',
                  default: currentSettings.selfContained !== false
                }
              ]);
              
              formatSettings.html = {
                ...currentSettings,
                ...htmlAnswers,
                tocDepth: parseInt(htmlAnswers.tocDepth)
              };
            }
          }
        }
        
        const spinner = ora('Building book...').start();
        
        const result = await buildBook({
          language: answers.language,
          formats: answers.formats,
          formatSettings: answers.configureSettings ? formatSettings : undefined
        });
        
        if (result.success) {
          spinner.succeed(chalk.green('Book built successfully!'));
          console.log(chalk.blue('Formats generated:'), answers.formats.join(', '));
          if (result.files) {
            console.log(chalk.blue('Output files:'));
            Object.entries(result.files).forEach(([key, value]) => {
              if (key !== 'input') {
                console.log(`${key}: ${value}`);
              }
            });
          }
        } else {
          spinner.fail(chalk.red('Failed to build book'));
          if (result.error) {
            console.error(chalk.red(result.error.message));
          }
        }
      } catch (error) {
        console.error(chalk.red(`Error: ${error.message}`));
      }
    });

  // Create chapter command
  program
    .command('create-chapter')
    .description('Create a new chapter')
    .option('-n, --number <number>', 'Chapter number (e.g., "01")')
    .option('-t, --title <title>', 'Chapter title')
    .option('-l, --lang <language>', 'Language code (default: "en")')
    .action(async (options) => {
      try {
        if (!options.number || !options.title) {
          const answers = await inquirer.prompt([
            {
              type: 'input',
              name: 'number',
              message: 'Chapter number (e.g., "01", "02"):',
              validate: input => /^\d{2}$/.test(input) ? true : 'Please enter a two-digit number'
            },
            {
              type: 'input',
              name: 'title',
              message: 'Chapter title:',
              validate: input => input ? true : 'Title is required'
            },
            {
              type: 'input',
              name: 'lang',
              message: 'Language code:',
              default: 'en'
            }
          ]);
          
          options = { ...options, ...answers };
        }
        
        const spinner = ora('Creating chapter...').start();
        
        const result = await createChapter({
          chapterNumber: options.number,
          title: options.title,
          language: options.lang || 'en'
        });
        
        if (result.success) {
          spinner.succeed(chalk.green(`Chapter ${options.number} created successfully!`));
          console.log(chalk.blue('Chapter path:'), result.path);
          console.log(chalk.blue('Files created:'));
          result.files.forEach(file => console.log(`- ${file}`));
        } else {
          spinner.fail(chalk.red('Failed to create chapter'));
          if (result.error) {
            console.error(chalk.red(result.error.message));
          }
        }
      } catch (error) {
        console.error(chalk.red(`Error: ${error.message}`));
      }
    });

  // Check chapter command
  program
    .command('check-chapter')
    .description('Check a chapter structure')
    .option('-n, --number <number>', 'Chapter number (e.g., "01")')
    .option('-l, --lang <language>', 'Language code (default: "en")')
    .action(async (options) => {
      try {
        if (!options.number) {
          const answers = await inquirer.prompt([
            {
              type: 'input',
              name: 'number',
              message: 'Chapter number (e.g., "01", "02"):',
              validate: input => /^\d{2}$/.test(input) ? true : 'Please enter a two-digit number'
            },
            {
              type: 'input',
              name: 'lang',
              message: 'Language code:',
              default: 'en'
            }
          ]);
          
          options = { ...options, ...answers };
        }
        
        const spinner = ora('Checking chapter...').start();
        
        const result = await checkChapter({
          chapterNumber: options.number,
          language: options.lang || 'en'
        });
        
        if (result.success !== false) {
          spinner.succeed(chalk.green(`Chapter ${options.number} structure checked!`));
          console.log(chalk.blue('Has introduction:'), result.hasIntro ? '✅' : '❌');
          console.log(chalk.blue('Has sections:'), result.hasSection ? '✅' : '❌');
          console.log(chalk.blue('Has images directory:'), result.hasImagesDir ? '✅' : '❌');
          
          if (result.markdownFiles && result.markdownFiles.length > 0) {
            console.log(chalk.blue('Markdown files:'));
            result.markdownFiles.forEach(file => {
              console.log(`- ${file.name} (${file.title || 'No title'})`);
            });
          }
          
          if (result.images && result.images.length > 0) {
            console.log(chalk.blue('Images:'));
            result.images.forEach(image => {
              console.log(`- ${image}`);
            });
          }
        } else {
          spinner.fail(chalk.red('Failed to check chapter'));
          if (result.error) {
            console.error(chalk.red(result.error.message));
          }
        }
      } catch (error) {
        console.error(chalk.red(`Error: ${error.message}`));
      }
    });

  // Info command
  program
    .command('info')
    .description('Display book information')
    .option('-v, --verbose', 'Show detailed information', false)
    .action(async (options) => {
      try {
        const spinner = ora('Loading book information...').start();
        
        const info = await getBookInfo();
        
        spinner.succeed(chalk.green('Book information loaded!'));
        console.log(chalk.blue('Title:'), info.title);
        if (info.subtitle) console.log(chalk.blue('Subtitle:'), info.subtitle);
        console.log(chalk.blue('Author:'), info.author);
        console.log(chalk.blue('File prefix:'), info.filePrefix);
        console.log(chalk.blue('Languages:'), info.languages.join(', '));
        
        console.log(chalk.blue('\nAvailable formats:'));
        Object.entries(info.formats || {}).forEach(([format, enabled]) => {
          console.log(`- ${format}: ${enabled ? '✅' : '❌'}`);
        });
        
        // Show format-specific settings if verbose
        if (options.verbose && info.formatSettings) {
          console.log(chalk.blue('\nFormat settings:'));
          
          if (info.formatSettings.pdf) {
            console.log(chalk.cyan('\nPDF settings:'));
            Object.entries(info.formatSettings.pdf).forEach(([key, value]) => {
              console.log(`- ${key}: ${value}`);
            });
          }
          
          if (info.formatSettings.epub) {
            console.log(chalk.cyan('\nEPUB settings:'));
            Object.entries(info.formatSettings.epub).forEach(([key, value]) => {
              console.log(`- ${key}: ${value}`);
            });
          }
          
          if (info.formatSettings.html) {
            console.log(chalk.cyan('\nHTML settings:'));
            Object.entries(info.formatSettings.html).forEach(([key, value]) => {
              console.log(`- ${key}: ${value}`);
            });
          }
        }
        
        if (info.builtFiles && info.builtFiles.length > 0) {
          console.log(chalk.blue('\nBuilt files:'));
          info.builtFiles.forEach(file => {
            console.log(`- ${file}`);
          });
        }
      } catch (error) {
        console.error(chalk.red(`Error: ${error.message}`));
      }
    });

  // Clean command
  program
    .command('clean')
    .description('Clean build artifacts')
    .action(async () => {
      try {
        const spinner = ora('Cleaning build artifacts...').start();
        
        const result = await cleanBuild();
        
        if (result.success) {
          spinner.succeed(chalk.green('Build artifacts cleaned!'));
          console.log(chalk.blue('Files removed:'), result.filesRemoved);
        } else {
          spinner.fail(chalk.red('Failed to clean build artifacts'));
          if (result.error) {
            console.error(chalk.red(result.error.message));
          }
        }
      } catch (error) {
        console.error(chalk.red(`Error: ${error.message}`));
      }
    });

  // Validate command
  program
    .command('validate')
    .description('Validate book configuration')
    .action(async () => {
      try {
        const spinner = ora('Validating configuration...').start();
        
        const result = await validateConfig();
        
        if (result.success) {
          spinner.succeed(chalk.green('Configuration is valid!'));
          
          if (result.warnings.length > 0) {
            console.log(chalk.yellow('\nWarnings:'));
            result.warnings.forEach(warning => {
              console.log(chalk.yellow(`- ${warning}`));
            });
          } else {
            console.log(chalk.green('No warnings or errors found.'));
          }
          
          console.log(chalk.blue('\nCurrent configuration:'));
          console.log(`Title: ${result.config.title}`);
          console.log(`Author: ${result.config.author}`);
          console.log(`Languages: ${result.config.languages.join(', ')}`);
          console.log(`Output formats: ${Object.entries(result.config.formats)
            .filter(([_, enabled]) => enabled)
            .map(([format]) => format)
            .join(', ')}`);
        } else {
          spinner.fail(chalk.red('Configuration validation failed!'));
          
          if (result.errors && result.errors.length > 0) {
            console.log(chalk.red('\nErrors:'));
            result.errors.forEach(error => {
              console.log(chalk.red(`- ${error}`));
            });
          }
          
          if (result.warnings && result.warnings.length > 0) {
            console.log(chalk.yellow('\nWarnings:'));
            result.warnings.forEach(warning => {
              console.log(chalk.yellow(`- ${warning}`));
            });
          }
          
          if (result.error) {
            console.error(chalk.red(`\nError: ${result.error.message}`));
          }
        }
      } catch (error) {
        console.error(chalk.red(`Error: ${error.message}`));
      }
    });

  return program;
}

module.exports = {
  configureCLI
};
