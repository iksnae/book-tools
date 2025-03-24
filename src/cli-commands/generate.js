/**
 * Generate command module
 * 
 * This module implements the `book generate` command to create
 * a specific output format from markdown sources.
 */

const path = require('path');
const ora = require('ora');
const chalk = require('chalk');
const { 
  findProjectRoot, 
  loadBookConfig, 
  buildFileNames 
} = require('../utils');
const { generateFormat } = require('../formats');

/**
 * Configure the generate command
 * 
 * @param {Object} program - Commander program instance
 */
function configureGenerateCommand(program) {
  program
    .command('generate <format>')
    .description('Generate a specific format from markdown sources')
    .option('-l, --lang <language>', 'Specify language to generate', 'en')
    .option('-i, --input <file>', 'Input markdown file')
    .option('-o, --output <file>', 'Output file path')
    .option('-v, --verbose', 'Show verbose output')
    .action(async (format, options) => {
      try {
        const spinner = ora(`Generating ${format.toUpperCase()}...`).start();
        
        // Get project config
        const projectRoot = findProjectRoot();
        const config = loadBookConfig(projectRoot);
        
        // Validate format
        const validFormats = ['pdf', 'epub', 'html', 'mobi', 'docx'];
        if (!validFormats.includes(format.toLowerCase())) {
          spinner.fail(chalk.red(`Unsupported format: ${format}`));
          console.error(chalk.red(`Supported formats: ${validFormats.join(', ')}`));
          return;
        }
        
        // Determine input and output paths
        let inputPath, outputPath;
        
        if (options.input) {
          inputPath = path.isAbsolute(options.input)
            ? options.input
            : path.join(process.cwd(), options.input);
        } else {
          const fileNames = buildFileNames(options.lang, projectRoot);
          inputPath = fileNames.input;
        }
        
        if (options.output) {
          outputPath = path.isAbsolute(options.output)
            ? options.output
            : path.join(process.cwd(), options.output);
        } else {
          const fileNames = buildFileNames(options.lang, projectRoot);
          outputPath = fileNames[format];
        }
        
        // Generate the format
        const result = await generateFormat(
          config, 
          inputPath, 
          outputPath, 
          format, 
          options.lang, 
          { verbose: options.verbose }
        );
        
        if (result.success) {
          spinner.succeed(chalk.green(`${format.toUpperCase()} generated successfully!`));
          console.log(chalk.blue('Output file:'), result.outputPath);
          
          // Show additional information if available
          if (result.hasOwnProperty('hasReferenceDoc') && result.hasReferenceDoc) {
            console.log(chalk.blue('Used reference doc:'), result.referenceDocPath);
          }
          
          if (result.fallback) {
            console.log(chalk.yellow('Note:'), 'Used fallback settings for generation');
          }
          
          // Show command if verbose
          if (options.verbose) {
            console.log(chalk.blue('Command:'), result.command);
            if (result.stderr) {
              console.log(chalk.yellow('Warnings:'), result.stderr);
            }
          }
        } else {
          spinner.fail(chalk.red(`Failed to generate ${format.toUpperCase()}`));
          if (result.errorMessage) {
            console.error(chalk.red(result.errorMessage));
          }
        }
      } catch (error) {
        console.error(chalk.red(`Error: ${error.message}`));
      }
    });
}

module.exports = {
  configureGenerateCommand
};
