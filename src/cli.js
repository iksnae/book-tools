const { program } = require('commander');
const inquirer = require('inquirer');
const chalk = require('chalk');
const ora = require('ora');
const path = require('path');

const bookTools = require('./index');
const { buildBook, createChapter, checkChapter, getBookInfo, cleanBuild } = bookTools;
const { findProjectRoot, loadConfig } = require('./utils');

// Set up the CLI
function configureCLI() {
  program
    .name('book')
    .description('CLI tool for the book template system')
    .version('0.1.0');

  // Build command
  program
    .command('build')
    .description('Build the book in specified formats')
    .option('--all-languages', 'Build all configured languages')
    .option('--lang <language>', 'Build specific language')
    .option('--skip-pdf', 'Skip PDF generation')
    .option('--skip-epub', 'Skip EPUB generation')
    .option('--skip-mobi', 'Skip MOBI generation')
    .option('--skip-html', 'Skip HTML generation')
    .action((options) => {
      console.log(chalk.blue('📚 Building book...'));
      
      const spinner = ora('Building book...').start();
      buildBook(options)
        .then(() => {
          spinner.succeed(chalk.green('Book built successfully!'));
        })
        .catch((error) => {
          spinner.fail(chalk.red('Build failed'));
          console.error(error);
        });
    });

  // Interactive build command
  program
    .command('interactive')
    .description('Build the book with interactive prompts')
    .action(async () => {
      console.log(chalk.blue('📚 Interactive Book Builder'));
      
      try {
        const config = loadConfig();
        console.log(chalk.cyan(`Book Title: ${config.title}`));
        console.log(chalk.cyan(`Author: ${config.author}`));
        
        // Get the languages
        const languages = config.languages || ['en'];
        
        // Prompt the user for options
        const answers = await inquirer.prompt([
          {
            type: 'list',
            name: 'language',
            message: 'Which language would you like to build?',
            choices: [
              { name: 'All languages', value: 'all' },
              ...languages.map(lang => ({ name: lang, value: lang }))
            ],
            default: 'en'
          },
          {
            type: 'checkbox',
            name: 'formats',
            message: 'Which formats would you like to build?',
            choices: [
              { name: 'PDF', value: 'pdf', checked: true },
              { name: 'EPUB', value: 'epub', checked: true },
              { name: 'MOBI', value: 'mobi', checked: true },
              { name: 'HTML', value: 'html', checked: true }
            ]
          }
        ]);
        
        // Convert answers to options
        const options = {
          allLanguages: answers.language === 'all',
          lang: answers.language !== 'all' ? answers.language : undefined,
          skipPdf: !answers.formats.includes('pdf'),
          skipEpub: !answers.formats.includes('epub'),
          skipMobi: !answers.formats.includes('mobi'),
          skipHtml: !answers.formats.includes('html')
        };
        
        const spinner = ora('Building book...').start();
        
        try {
          await buildBook(options);
          spinner.succeed(chalk.green('Book built successfully!'));
        } catch (error) {
          spinner.fail(chalk.red('Build failed'));
          console.error(error);
        }
      } catch (error) {
        console.error(chalk.red('Error:'), error.message);
      }
    });

  // New command to create a chapter
  program
    .command('create-chapter')
    .description('Create a new chapter directory structure')
    .option('-n, --number <number>', 'Chapter number (e.g., 04)')
    .option('-t, --title <title>', 'Chapter title')
    .option('-l, --lang <language>', 'Language code', 'en')
    .action(async (options) => {
      console.log(chalk.blue('📚 Creating New Chapter'));
      
      // If number or title not provided, prompt for them
      const answers = await inquirer.prompt([
        {
          type: 'input',
          name: 'number',
          message: 'Chapter number (e.g., 04):',
          default: options.number || '',
          validate: input => /^\d{2}$/.test(input) ? true : 'Please enter a two-digit number (e.g., 04)',
          when: !options.number || !/^\d{2}$/.test(options.number)
        },
        {
          type: 'input',
          name: 'title',
          message: 'Chapter title:',
          default: options.title || '',
          validate: input => input.trim() ? true : 'Please enter a chapter title',
          when: !options.title
        },
        {
          type: 'input',
          name: 'lang',
          message: 'Language code:',
          default: options.lang || 'en',
          when: !options.lang
        }
      ]);
      
      const chapterNumber = answers.number || options.number;
      const chapterTitle = answers.title || options.title;
      const language = answers.lang || options.lang;
      
      const spinner = ora('Creating chapter structure...').start();
      
      try {
        const result = await createChapter({ number: chapterNumber, title: chapterTitle, lang: language });
        spinner.succeed(chalk.green(`Chapter ${chapterNumber}: "${chapterTitle}" created successfully`));
        console.log(chalk.cyan('\nCreated files:'));
        result.files.forEach(file => console.log(`  - ${file}`));
      } catch (error) {
        spinner.fail(chalk.red('Failed to create chapter structure'));
        console.error(error);
      }
    });

  // Check-chapter command
  program
    .command('check-chapter')
    .description('Check the structure of a specific chapter')
    .option('-n, --number <number>', 'Chapter number (e.g., 04)', '')
    .option('-l, --lang <language>', 'Language code', 'en')
    .action(async (options) => {
      console.log(chalk.blue('📚 Checking Chapter Structure'));
      
      try {
        const result = await checkChapter(options);
        
        if (options.number) {
          console.log(chalk.cyan(`\nStructure of chapter-${options.number} in ${options.lang}:`));
          
          // Display the structure
          const markFiles = (exists) => exists ? chalk.green('✅') : chalk.red('❌');
          
          console.log(`${markFiles(result.hasIntro)} Introduction file (00-introduction.md)`);
          console.log(`${markFiles(result.hasSection)} Section file(s)`);
          console.log(`${markFiles(result.hasImagesDir)} Images directory`);
          
          // List all markdown files
          console.log(chalk.cyan('\nMarkdown files:'));
          result.markdownFiles.forEach(file => {
            console.log(`  ${file.name}: ${file.title}`);
          });
          
          // Check images directory if it exists
          if (result.hasImagesDir) {
            console.log(chalk.cyan('\nImages:'));
            if (result.images.length === 0) {
              console.log(chalk.yellow('  No images found.'));
            } else {
              result.images.forEach(image => {
                console.log(`  ${image.name} (${image.size} MB)`);
              });
            }
          }
        } else {
          console.log(chalk.cyan(`\nAvailable chapters in ${options.lang}:`));
          
          if (result.chapters.length === 0) {
            console.log(chalk.yellow('No chapters found.'));
          } else {
            result.chapters.forEach(chapter => {
              console.log(chalk.green(`  ${chapter.name}: ${chapter.sectionCount} section(s)`));
            });
          }
        }
      } catch (error) {
        console.error(chalk.red('Error:'), error.message);
      }
    });

  // Info command to show book details
  program
    .command('info')
    .description('Display information about the current book')
    .action(async () => {
      try {
        const info = await getBookInfo();
        
        console.log(chalk.blue('📚 Book Information'));
        console.log(chalk.cyan(`Title: ${info.title || 'Not set'}`));
        console.log(chalk.cyan(`Subtitle: ${info.subtitle || 'Not set'}`));
        console.log(chalk.cyan(`Author: ${info.author || 'Not set'}`));
        console.log(chalk.cyan(`File Prefix: ${info.filePrefix || 'Not set'}`));
        console.log(chalk.cyan(`Languages: ${(info.languages || ['en']).join(', ')}`));
        
        // Show output formats
        console.log(chalk.cyan(`Output Formats:`));
        console.log(`  PDF: ${info.formats.pdf ? 'Enabled' : 'Disabled'}`);
        console.log(`  EPUB: ${info.formats.epub ? 'Enabled' : 'Disabled'}`);
        console.log(`  MOBI: ${info.formats.mobi ? 'Enabled' : 'Disabled'}`);
        console.log(`  HTML: ${info.formats.html ? 'Enabled' : 'Disabled'}`);
        
        // Show built files
        if (info.builtFiles.length > 0) {
          console.log(chalk.cyan('\nBuilt Files:'));
          info.builtFiles.forEach(file => {
            console.log(`  ${file.name} (${file.size} MB)`);
          });
        } else {
          console.log(chalk.yellow('\nNo built files found.'));
        }
      } catch (error) {
        console.error(chalk.red('Error:'), error.message);
      }
    });

  // Clean command
  program
    .command('clean')
    .description('Clean build artifacts')
    .action(async () => {
      const spinner = ora('Cleaning build artifacts...').start();
      
      try {
        const result = await cleanBuild();
        
        if (result.success) {
          spinner.succeed(chalk.green('Build artifacts cleaned successfully'));
          if (result.filesRemoved > 0) {
            console.log(chalk.cyan(`Removed ${result.filesRemoved} files`));
          }
        } else {
          spinner.info(chalk.yellow('No build directory found'));
        }
      } catch (error) {
        spinner.fail(chalk.red('Failed to clean build artifacts'));
        console.error(error);
      }
    });
}

// Export the run function
function run() {
  configureCLI();
  program.parse(process.argv);
  
  // If no command is provided, show help
  if (!process.argv.slice(2).length) {
    program.outputHelp();
  }
}

module.exports = {
  run,
  configureCLI
};