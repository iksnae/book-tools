const { configureCLI } = require('../src/cli');

// Manual mocks to avoid issues with Jest auto-mocking
const mockBuildBook = jest.fn().mockResolvedValue({ success: true });
const mockCreateChapter = jest.fn().mockResolvedValue({ 
  success: true, 
  chapterNumber: '01',
  chapterTitle: 'Test Chapter',
  language: 'en',
  path: '/project-root/book/en/chapter-01',
  files: [
    '/project-root/book/en/chapter-01/00-introduction.md',
    '/project-root/book/en/chapter-01/01-section.md',
    '/project-root/book/en/chapter-01/images/README.md'
  ]
});
const mockCheckChapter = jest.fn().mockResolvedValue({
  language: 'en',
  chapterNumber: '01',
  hasIntro: true,
  hasSection: true,
  hasImagesDir: true,
  markdownFiles: [
    { name: '00-introduction.md', title: 'Introduction' },
    { name: '01-section.md', title: 'First Section' }
  ],
  images: []
});
const mockGetBookInfo = jest.fn().mockResolvedValue({
  title: 'Test Book',
  subtitle: 'Test Subtitle',
  author: 'Test Author',
  filePrefix: 'test-book',
  languages: ['en', 'es'],
  formats: {
    pdf: true,
    epub: true,
    mobi: true,
    html: true
  },
  builtFiles: []
});
const mockCleanBuild = jest.fn().mockResolvedValue({
  success: true,
  filesRemoved: 5
});

// Mock modules before requiring them
jest.mock('../src/index', () => ({
  buildBook: mockBuildBook,
  createChapter: mockCreateChapter,
  checkChapter: mockCheckChapter,
  getBookInfo: mockGetBookInfo,
  cleanBuild: mockCleanBuild
}));

jest.mock('inquirer', () => ({
  prompt: jest.fn().mockResolvedValue({
    language: 'en',
    formats: ['pdf', 'epub']
  })
}));

jest.mock('chalk', () => ({
  blue: jest.fn(text => text),
  green: jest.fn(text => text),
  red: jest.fn(text => text),
  cyan: jest.fn(text => text),
  yellow: jest.fn(text => text)
}));

jest.mock('ora', () => {
  return jest.fn().mockReturnValue({
    start: jest.fn().mockReturnThis(),
    stop: jest.fn().mockReturnThis(),
    succeed: jest.fn().mockReturnThis(),
    fail: jest.fn().mockReturnThis(),
    info: jest.fn().mockReturnThis(),
    warn: jest.fn().mockReturnThis()
  });
});

// Simple mock for Commander to avoid complex interactions
jest.mock('commander', () => {
  const mockCommand = {
    name: jest.fn().mockReturnValue('test-command'),
    description: jest.fn().mockReturnThis(),
    option: jest.fn().mockReturnThis(),
    action: jest.fn().mockReturnThis(),
    addCommand: jest.fn().mockReturnThis(),
    parse: jest.fn(),
    error: jest.fn()
  };
  
  return {
    program: {
      name: jest.fn().mockReturnThis(),
      version: jest.fn().mockReturnThis(),
      description: jest.fn().mockReturnThis(),
      command: jest.fn().mockReturnValue(mockCommand),
      commands: [mockCommand],
      parse: jest.fn(),
      error: jest.fn()
    }
  };
});

describe('CLI Module', () => {
  let consoleLogSpy;
  
  beforeEach(() => {
    consoleLogSpy = jest.spyOn(console, 'log').mockImplementation(() => {});
  });
  
  afterEach(() => {
    consoleLogSpy.mockRestore();
    jest.clearAllMocks();
  });

  test('configureCLI should register commands without errors', () => {
    expect(() => configureCLI()).not.toThrow();
  });
  
  test('configureCLI should return a configured program object', () => {
    const result = configureCLI();
    expect(result).toBeDefined();
  });
});