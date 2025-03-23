#!/usr/bin/env node

const { configureCLI } = require('../src/cli');

// Configure and run the CLI
const program = configureCLI();
program.parse(process.argv);