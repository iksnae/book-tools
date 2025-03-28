# HTML Customization

This document explains how to customize the HTML output of your book, including adding cover images for social media sharing and improving mobile responsiveness.

## Cover Images for Social Media Sharing

Book Tools now supports Open Graph metadata for social media sharing. When someone shares a link to your HTML book on social media platforms like Twitter, Facebook, or LinkedIn, the platform will display a preview with your book cover and description.

### How to Add a Cover Image

1. Add a cover image to one of these locations:
   - **Language-specific covers (recommended):**
     - `book/{language}/images/cover.png` or `book/{language}/images/cover.jpg`
     - `resources/{language}/images/cover.png` or `resources/{language}/images/cover.jpg`
   - Fallback covers:
     - `book/images/cover.png` or `book/images/cover.jpg`
     - `resources/images/cover.png` or `resources/images/cover.jpg`

2. The build system will automatically detect your cover image and add it to the Open Graph metadata.

3. **For multilingual books**: Create separate cover images for each language to ensure the text on the cover matches the language. The system will prioritize language-specific covers over general ones.

### Cover Image Recommendations

For best results across social media platforms:

- Use a PNG or JPG image
- Recommended dimensions: 1200 × 630 pixels
- Keep important content (like book title) in the center
- Use high contrast to ensure readability
- File size should be under 1MB
- For multilingual books, create distinct cover images with text in the appropriate language

## Responsive Design for Mobile Devices

The HTML output is now responsive and optimized for mobile devices:

- Images are sized appropriately for different screen sizes
- Font sizes adjust for readability on smaller screens
- Tables have horizontal scrolling on narrow screens
- Dark mode support based on system preferences

### Custom Styling

You can customize the HTML styling by editing:

- `resources/css/html.css` for global styles
- `resources/templates/html/default.html` for template structure

## Enhanced Image Styling Options

Book Tools now provides multiple ways to control how images appear in your HTML book. Use these HTML classes to customize image display for different needs:

### Basic Images

By default, all images are responsive with proper scaling for different screen sizes.

```html
<!-- Standard responsive image -->
<img src="path/to/image.jpg" alt="Image description">
```

### Images with Captions

```html
<!-- Image with caption -->
<figure>
  <img src="path/to/image.jpg" alt="Image description">
  <figcaption>This is a caption for the image</figcaption>
</figure>
```

### Controlling Image Size and Layout

```html
<!-- Container for better control of medium-sized images -->
<div class="medium-image">
  <img src="path/to/image.jpg" alt="Image description">
</div>

<!-- Full-width image that extends beyond content width -->
<div class="full-width-image">
  <img src="path/to/image.jpg" alt="Image description">
</div>

<!-- For very large images that need scrolling -->
<div class="large-image">
  <img src="path/to/image.jpg" alt="Image description">
</div>

<!-- Small inline image (within text) -->
<span>Text with an <img class="inline-image" src="icon.png" alt="small icon"> inside it.</span>
```

### Image Galleries

For displaying multiple images in a grid layout:

```html
<div class="image-gallery">
  <figure>
    <img src="image1.jpg" alt="First image">
    <figcaption>First image caption</figcaption>
  </figure>
  <figure>
    <img src="image2.jpg" alt="Second image">
    <figcaption>Second image caption</figcaption>
  </figure>
  <figure>
    <img src="image3.jpg" alt="Third image">
    <figcaption>Third image caption</figcaption>
  </figure>
</div>
```

## Customizing Meta Information

To add custom metadata for your book, edit your `book.yaml` file:

```yaml
title: "Your Book Title"
author: "Your Name"
description: "A compelling description of your book used in social media previews"
keywords: ["keyword1", "keyword2"]
language: en
```

This metadata will be used for both the document itself and for Open Graph/social media sharing.

## Multilingual Support

For books with multiple languages, you can configure language-specific settings in your `book.yaml`:

### Language-specific URLs

Add a base URL for canonical links and improve SEO for multilingual books:

```yaml
html:
  base_url: "https://yourdomain.com/books/your-book"  # Base URL for canonical links
```

This will generate proper canonical URLs like `https://yourdomain.com/books/your-book/en/book.html` for each language version.

### Language-specific Cover Images

For multilingual books, it's best to have different cover images for each language:

```yaml
social:
  language_covers:
    en: "book/en/images/cover.png"  # English cover
    es: "book/es/images/cover.png"  # Spanish cover
    fr: "book/fr/images/cover.png"  # French cover
```

The system will prioritize:
1. Language-specific covers from book.yaml
2. Language-specific covers from your file structure
3. Fallback to the default cover image 