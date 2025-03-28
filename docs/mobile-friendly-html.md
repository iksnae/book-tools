# Mobile-Friendly HTML Output

This feature enhances the HTML output from Book Tools to be more mobile-friendly, particularly for handling large images (like 1024x1024 images) on smaller screens.

## Features

- Viewport meta tag for proper scaling on mobile devices
- Responsive image handling with automatic scaling to fit screen width
- Appropriate padding for images on different device sizes
- Media queries to adjust layout for different screen widths
- Better table handling with horizontal scrolling on small screens

## Configuration

Mobile-friendly HTML is enabled by default. You can configure it in your `book.yaml` file:

```yaml
html:
  responsive: true  # Set to false to disable responsive features
  # Other HTML settings...
```

## How It Works

When responsive HTML is enabled (the default), Book Tools will:

1. Use the responsive HTML template (`templates/html/responsive.html`) if available
2. Use the responsive CSS stylesheet (`templates/html/responsive.css`) if available
3. Fall back to the default templates with basic responsive features if the specialized files aren't found

## Custom Styling

You can customize the responsive styling by:

1. Editing the `templates/html/responsive.css` file directly
2. Specifying your own CSS file in the configuration:

```yaml
html:
  css: path/to/your/custom.css
  responsive: false  # Use this to bypass the responsive template and just use your CSS
```

## Technical Details

### Responsive Image Handling

Images are styled with:

```css
img {
  max-width: 100%;
  height: auto;
  display: block;
  margin: 0 auto;
  padding: 10px;
  box-sizing: border-box;
}
```

This ensures that:
- Images never exceed the width of their container
- Images maintain their aspect ratio
- Images are centered with appropriate padding

### Viewport Configuration

The HTML templates include:

```html
<meta name="viewport" content="width=device-width, initial-scale=1.0">
```

This tells mobile browsers to:
- Set the viewport width to the device width
- Set the initial zoom level to 1.0 (no zooming)

### Media Queries

The CSS includes media queries for different screen sizes:

```css
@media only screen and (max-width: 768px) {
  /* Tablet styles */
}

@media only screen and (max-width: 480px) {
  /* Mobile phone styles */
}
```

## Troubleshooting

### Images Still Too Large

If images are still too large or not scaling properly:

1. Verify that the responsive feature is enabled in your configuration
2. Check that the HTML output includes the viewport meta tag
3. Ensure the CSS is properly loading in the generated HTML file

### Text Size Issues

If text is too small on mobile devices:

1. Add custom font sizing in your CSS for smaller screens
2. Use relative units (em, rem) instead of pixels for font sizes

### Layout Problems

If you encounter layout issues with specific content types, you may need to add additional CSS rules for those elements.