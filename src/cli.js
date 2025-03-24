const { program } = require('commander');
const inquirer = require('inquirer');
const chalk = require('chalk');
const ora = require('ora');
const { 
  buildBook, 
  buildBookWithRecovery,
  createChapter, 
  checkChapter, 
  getBookInfo, 
  cleanBuild,
  validate
} = require('./index');

/**
 * Configure the Commander.js CLI
 */
function configureCLI() {
  program
    .name('book')
    .description('Book Tools CLI for building books from markdown sources')
    .version('0.2.0');

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
    .option('--skip-docx', 'Skip DOCX generation')
    .option('--with-recovery', 'Enable enhanced error recovery')
    .option('--verbose', 'Show verbose output')
    .action(async (options) => {
      const spinner = ora('Building book...').start();
      try {
        const formats = [];
        if (!options.skipPdf) formats.push('pdf');
        if (!options.skipEpub) formats.push('epub');
        if (!options.skipMobi) formats.push('mobi');
        if (!options.skipHtml) formats.push('html');
        if (!options.skipDocx) formats.push('docx');

        const buildOptions = {
          allLanguages: options.allLanguages,
          language: options.lang || 'en',
          formats,
          verbose: options.verbose
        };

        // Use enhanced error recovery if requested
        const result = options.withRecovery
          ? await buildBookWithRecovery(buildOptions)
          : await buildBook(buildOptions);

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
          
          // If emergency files were created, log them
          if (result.emergencyFiles) {
            console.log(chalk.yellow('Emergency output files created:'));
            Object.entries(result.emergencyFiles).forEach(([key, value]) => {
              console.log(`${key}: ${value}`);
            });
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
              { name: 'HTML', value: 'html', checked: bookInfo.formats?.html },
              { name: 'DOCX', value: 'docx', checked: bookInfo.formats?.docx }
            ]
          },
          {
            type: 'confirm',
            name: 'withRecovery',
            message: 'Enable enhanced error recovery?',
            default: true
          },
          {
            type: 'confirm',
            name: 'verbose',
            message: 'Show verbose output?',
            default: false
          }
        ]);
        
        const spinner = ora('Building book...').start();
        
        const buildOptions = {
          language: answers.language,
          formats: answers.formats,
          verbose: answers.verbose
        };
        
        const result = answers.withRecovery
          ? await buildBookWithRecovery(buildOptions)
          : await buildBook(buildOptions);
        
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
          
          // If emergency files were created, log them
          if (result.emergencyFiles) {
            console.log(chalk.yellow('Emergency output files created:'));
            Object.entries(result.emergencyFiles).forEach(([key, value]) => {
              console.log(`${key}: ${value}`);
            });
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
    .action(async () => {
      try {
        const spinner = ora('Loading book information...').start();
        
        const info = await getBookInfo();
        
        spinner.succeed(chalk.green('Book information loaded!'));
        console.log(chalk.blue('Title:'), info.title);
        if (info.subtitle) console.log(chalk.blue('Subtitle:'), info.subtitle);
        console.log(chalk.blue('Author:'), info.author);
        console.log(chalk.blue('File prefix:'), info.filePrefix);
        console.log(chalk.blue('Languages:'), info.languages.join(', '));
        
        console.log(chalk.blue('Available formats:'));
        Object.entries(info.formats || {}).forEach(([format, enabled]) => {
          console.log(`- ${format}: ${enabled ? '✅' : '❌'}`);
        });
        
        // Display format-specific settings if present
        if (info.formatSettings) {
          console.log(chalk.blue('\nFormat Settings:'));
          
          // Show PDF settings
          if (info.formatSettings.pdf) {
            console.log(chalk.cyan('PDF Settings:'));
            Object.entries(info.formatSettings.pdf).forEach(([key, value]) => {
              console.log(`  - ${key}: ${value}`);
            });
          }
          
          // Show EPUB settings
          if (info.formatSettings.epub) {
            console.log(chalk.cyan('EPUB Settings:'));
            Object.entries(info.formatSettings.epub).forEach(([key, value]) => {
              console.log(`  - ${key}: ${value}`);
            });
          }
          
          // Show HTML settings
          if (info.formatSettings.html) {
            console.log(chalk.cyan('HTML Settings:'));
            Object.entries(info.formatSettings.html).forEach(([key, value]) => {
              console.log(`  - ${key}: ${value}`);
            });
          }
          
          // Show DOCX settings
          if (info.formatSettings.docx) {
            console.log(chalk.cyan('DOCX Settings:'));
            Object.entries(info.formatSettings.docx).forEach(([key, value]) => {
              console.log(`  - ${key}: ${value}`);
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
    .description('Check configuration and dependencies')
    .option('-c, --config <path>', 'Path to configuration file (default: "book.yaml")')
    .option('-f, --fix', 'Attempt to fix common issues')
    .option('--verbose', 'Show detailed validation information')
    .action(async (options) => {
      try {
        const spinner = ora('Validating project setup...').start();
        
        const validateOptions = {
          configPath: options.config || 'book.yaml',
          fix: options.fix || false,
          verbose: options.verbose || false
        };
        
        const result = await validate(validateOptions);
        
        if (result.valid) {
          spinner.succeed(chalk.green('Project configuration is valid!'));
        } else {
          spinner.warn(chalk.yellow('Project configuration has issues'));
        }
        
        // Display summary of validation
        console.log(chalk.blue('\nValidation Summary:'));
        
        // Configuration status
        console.log(chalk.cyan('Configuration:'), 
          result.config.valid ? chalk.green('✅ Valid') : chalk.yellow('⚠️ Has issues'));
        
        // Dependencies status
        const depStatus = result.dependencies.issues.some(i => i.type === 'error') 
          ? chalk.red('❌ Missing required dependencies')
          : (result.dependencies.issues.length > 0 
            ? chalk.yellow('⚠️ Some optional dependencies missing') 
            : chalk.green('✅ All dependencies installed'));
        console.log(chalk.cyan('Dependencies:'), depStatus);
        
        // Directory structure status
        console.log(chalk.cyan('Directory Structure:'), 
          result.structure.valid ? chalk.green('✅ Valid') : chalk.yellow('⚠️ Has issues'));
        
        // List all issues
        if (result.allIssues.length > 0) {
          console.log(chalk.blue('\nIssues found:'));
          
          // Group issues by type
          const errors = result.allIssues.filter(i => i.type === 'error');
          const warnings = result.allIssues.filter(i => i.type === 'warning');
          
          if (errors.length > 0) {
            console.log(chalk.red('\nErrors:'));
            errors.forEach(issue => {
              console.log(chalk.red(`  - ${issue.message}`));
            });
          }
          
          if (warnings.length > 0) {
            console.log(chalk.yellow('\nWarnings:'));
            warnings.forEach(issue => {
              console.log(chalk.yellow(`  - ${issue.message}`));
            });
          }
        }
        
        // Display detailed information if verbose
        if (options.verbose) {
          // Show dependencies
          console.log(chalk.blue('\nDetailed Dependencies:'));
          Object.entries(result.dependencies.dependencies).forEach(([name, installed]) => {
            console.log(`  - ${name}: ${installed ? chalk.green('✅ Installed') : chalk.yellow('⚠️ Not found')}`);
          });
          
          // Show directory structure
          console.log(chalk.blue('\nDirectory Structure:'));
          Object.entries(result.structure.directories).forEach(([dir, exists]) => {
            console.log(`  - ${dir}: ${exists ? chalk.green('✅ Exists') : chalk.yellow('⚠️ Not found')}`);
          });
        }
        
        // Provide recommendations
        if (!result.valid) {
          console.log(chalk.blue('\nRecommendations:'));
          
          if (result.dependencies.issues.some(i => i.type === 'error')) {
            console.log(chalk.cyan('- Install missing dependencies:'));
            result.dependencies.issues
              .filter(i => i.type === 'error')
              .forEach(issue => {
                console.log(`  ${issue.message}`);
              });
          }
          
          if (!result.config.valid) {
            console.log(chalk.cyan('- Fix configuration issues:'));
            result.config.issues
              .filter(i => i.type === 'error')
              .forEach(issue => {
                console.log(`  ${issue.message}`);
              });
          }
          
          if (!result.structure.valid) {
            console.log(chalk.cyan('- Create missing directories:'));
            Object.entries(result.structure.directories)
              .filter(([_, exists]) => !exists)
              .forEach(([dir]) => {
                console.log(`  ${dir}`);
              });
          }
          
          // Suggest init command if major issues
          if (result.allIssues.filter(i => i.type === 'error').length > 3) {
            console.log(chalk.cyan('\nTip: You can use the `book init` command to create a new project with the correct structure'));
          }
        }
      } catch (error) {
        console.error(chalk.red(`Error: ${error.message}`));
      }
    });

  // GitHub Actions integration command
  program
    .command('github-action')
    .description('Run as GitHub Action')
    .option('--all-languages', 'Build for all configured languages')
    .option('--create-release', 'Create GitHub release')
    .option('--no-recovery', 'Disable enhanced error recovery')
    .action(async (options) => {
      try {
        console.log(chalk.blue('Running as GitHub Action'));
        
        // Set CI environment variable for downstream scripts
        process.env.CI = 'true';
        
        const spinner = ora('Building book...').start();
        
        const buildOptions = {
          allLanguages: options.allLanguages,
          formats: ['pdf', 'epub', 'mobi', 'html', 'docx'],
          // True by default unless --no-recovery is specified
          withRecovery: options.recovery !== false
        };
        
        // Use recovery mode by default in GitHub Actions
        const result = buildOptions.withRecovery
          ? await buildBookWithRecovery(buildOptions)
          : await buildBook(buildOptions);
        
        if (result.success) {
          spinner.succeed(chalk.green('Book built successfully!'));
          
          if (options.createRelease) {
            console.log(chalk.blue('Creating GitHub Release...'));
            // TODO: Implement GitHub release creation
          }
          
          // List all generated files for the GitHub Action output
          if (result.files) {
            console.log(chalk.blue('Generated files:'));
            Object.entries(result.files).forEach(([key, value]) => {
              if (key !== 'input') {
                console.log(`${key}=${value}`);
              }
            });
          }
        } else {
          spinner.fail(chalk.red('Failed to build book'));
          if (result.error) {
            console.error(chalk.red(result.error.message));
          }
          process.exit(1);
        }
      } catch (error) {
        console.error(chalk.red(`Error: ${error.message}`));
        process.exit(1);
      }
    });

  // Initialize project command
  program
    .command('init')
    .description('Initialize a new book project with standard structure')
    .option('-t, --template <template>', 'Template to use (basic, academic, technical)', 'basic')
    .option('-n, --name <name>', 'Book name')
    .option('-a, --author <author>', 'Author name')
    .option('-l, --languages <languages>', 'Comma-separated list of language codes', 'en')
    .action(async (options) => {
      try {
        console.log(chalk.blue('This command will be implemented in the next version'));
        console.log(chalk.blue('For now, you can use the validate command to check your existing setup'));
        
        // TODO: Implement project initialization
      } catch (error) {
        console.error(chalk.red(`Error: ${error.message}`));
      }
    });

  // Generate command
  program
    .command('generate <format>')
    .description('Generate a specific format with customized settings')
    .option('-l, --lang <language>', 'Language to build for (default: "en")')
    .option('-i, --input <path>', 'Custom input path')
    .option('-o, --output <path>', 'Custom output path')
    .option('-t, --template <path>', 'Custom template path')
    .option('-c, --config <path>', 'Custom config path')
    .action(async (format, options) => {
      try {
        console.log(chalk.blue('This command will be implemented in the next version'));
        console.log(chalk.blue('For now, you can use the build command with format-specific options'));
        
        // TODO: Implement format-specific generation
      } catch (error) {
        console.error(chalk.red(`Error: ${error.message}`));
      }
    });

  // Watch command
  program
    .command('watch')
    .description('Watch for changes and rebuild')
    .option('-l, --lang <language>', 'Language to watch and build (default: "en")')
    .option('-f, --formats <formats>', 'Comma-separated formats to build', 'html')
    .action(async (options) => {
      try {
        console.log(chalk.blue('This command will be implemented in the next version'));
        console.log(chalk.blue('For now, you can use the build command manually'));
        
        // TODO: Implement watch functionality
      } catch (error) {
        console.error(chalk.red(`Error: ${error.message}`));
      }
    });

  // Serve command
  program
    .command('serve')
    .description('Serve built HTML and provide live preview')
    .option('-p, --port <port>', 'Port to serve on', '8080')
    .option('-l, --lang <language>', 'Language to serve (default: "en")')
    .action(async (options) => {
      try {
        console.log(chalk.blue('This command will be implemented in the next version'));
        console.log(chalk.blue('For now, you can use a local web server to preview your HTML output'));
        
        // TODO: Implement serve functionality
      } catch (error) {
        console.error(chalk.red(`Error: ${error.message}`));
      }
    });

  return program;
}

module.exports = {
  configureCLI
};
