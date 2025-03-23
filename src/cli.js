const { program } = require('commander');
const inquirer = require('inquirer');
const chalk = require('chalk');
const ora = require('ora');
const { 
  buildBook, 
  createChapter, 
  checkChapter, 
  getBookInfo, 
  cleanBuild 
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
    .action(async (options) => {
      const spinner = ora('Building book...').start();
      try {
        const formats = [];
        if (!options.skipPdf) formats.push('pdf');
        if (!options.skipEpub) formats.push('epub');
        if (!options.skipMobi) formats.push('mobi');
        if (!options.skipHtml) formats.push('html');

        const result = await buildBook({
          allLanguages: options.allLanguages,
          language: options.lang || 'en',
          formats
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
          }
        ]);
        
        const spinner = ora('Building book...').start();
        
        const result = await buildBook({
          language: answers.language,
          formats: answers.formats
        });
        
        if (result.success) {
          spinner.succeed(chalk.green('Book built successfully!'));
          console.log(chalk.blue('Formats generated:'), answers.formats.join(', '));
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

  return program;
}

module.exports = {
  configureCLI
};