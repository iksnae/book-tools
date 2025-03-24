# Verbose Mode

The verbose mode in Book Tools provides detailed output about the build process, helping you understand what's happening and debug issues when they occur.

## Enabling Verbose Mode

You can enable verbose mode in two ways:

### 1. Using the CLI Flag

```bash
# Build with verbose output
book-tools build --verbose

# Or with Docker
book-tools build-docker --verbose
```

### 2. Using Environment Variables

```bash
export VERBOSE=1
book-tools build
```

## What Information Is Shown

When verbose mode is enabled, you'll see detailed information about:

### Build Process
- File processing steps
- Chapter compilation progress
- Template application
- Resource copying
- Format conversion details

### Error Reporting
- Detailed error messages
- Stack traces when available
- File paths and line numbers
- Suggested fixes

### Resource Usage
- Processing time for each step
- Memory usage for large operations
- File sizes and counts

### Dependencies
- Tool versions being used
- Configuration loading
- Template paths
- Resource locations

## Example Output

```
[INFO] Starting build process...
[DEBUG] Loading configuration from book.yaml
[DEBUG] Found 3 chapters in en/
[INFO] Processing chapter 01-introduction...
[DEBUG] - Combining markdown files...
[DEBUG] - Applying templates...
[DEBUG] - Converting to target formats...
[INFO] Processing chapter 02-getting-started...
...
```

## Use Cases

Verbose mode is particularly useful when:

1. **Debugging Issues**
   - Understanding why a build failed
   - Tracking down missing resources
   - Identifying configuration problems

2. **Development**
   - Testing new features
   - Verifying build steps
   - Optimizing build process

3. **CI/CD Integration**
   - Getting detailed logs in pipelines
   - Troubleshooting automated builds
   - Verifying workflow steps

## Performance Impact

Enabling verbose mode may slightly increase build time due to additional logging operations. This impact is usually negligible but might be noticeable with very large books or when building multiple formats. 