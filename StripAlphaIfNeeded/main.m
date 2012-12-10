//
//  main.m
//  StripAlphaIfNeeded
//
//  Created by Alexis Gallagher on 2012-12-10.
//  Copyright (c) 2012 Foxtrot Studios. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>

// code adapted from the Image I/O Programming Guide
CGImageRef MyCreateCGImageFromFile (NSString* path)
{
  // Get the URL for the pathname passed to the function.
  NSURL *url = [NSURL fileURLWithPath:path];
  CGImageRef        myImage = NULL;
  CGImageSourceRef  myImageSource;
  CFDictionaryRef   myOptions = NULL;
  CFStringRef       myKeys[2];
  CFTypeRef         myValues[2];
  
  // Set up options if you want them. The options here are for
  // caching the image in a decoded form and for using floating-point
  // values if the image format supports them.
  myKeys[0]   = kCGImageSourceShouldCache;
  myValues[0] = (CFTypeRef)kCFBooleanTrue;
  myKeys[1]   = kCGImageSourceShouldAllowFloat;
  myValues[1] = (CFTypeRef)kCFBooleanTrue;
  // Create the dictionary
  myOptions = CFDictionaryCreate(NULL, (const void **) myKeys,
                                 (const void **) myValues, 2,
                                 &kCFTypeDictionaryKeyCallBacks,
                                 & kCFTypeDictionaryValueCallBacks);
  // Create an image source from the URL.
  myImageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)url, myOptions);
  CFRelease(myOptions);
  // Make sure the image source exists before continuing
  if (myImageSource == NULL){
    fprintf(stderr, "Image source is NULL.");
    return  NULL;
  }
  // Create an image from the first item in the image source.
  myImage = CGImageSourceCreateImageAtIndex(myImageSource,
                                            0,
                                            NULL);
  
  CFRelease(myImageSource);
  // Make sure the image exists before continuing
  if (myImage == NULL){
    fprintf(stderr, "Image not created from image source.");
    return NULL;
  }
  
  return myImage;
}

/**
 Returns bitmap context with premultiplied ARGB components.

 That is, 32 bits per pixel, 8 pixels for Alpha, 8 bits for Alpha*Red, 
 8 bits for Alpha*Green, 8 bits for Alpha*Blue.
 
 code adapted from http://developer.apple.com/library/mac/#qa/qa1509/_index.html
 */
CGContextRef CreateARGBBitmapContext (CGImageRef inImage)
{
  const NSUInteger bitsPerByte = 8; // definitional
  // kCGColorSpaceGenericRGB implies the three components RGB
  // kCGImageAlphaPremultipliedFirst adds the (initial) alpha component A
  const NSUInteger componentsPerPixel = 4;
  const NSUInteger bitsPerComponent = 8; // our choice of color & alpha depth
 
  CGContextRef    context = NULL;
  CGColorSpaceRef colorSpace;
  void *          bitmapData;
  size_t          bitmapByteCount;
  size_t          bitmapBytesPerRow;
  
  // Get image width, height. We'll use the entire image.
  size_t pixelsWide = CGImageGetWidth(inImage);
  size_t pixelsHigh = CGImageGetHeight(inImage);
  
  // Declare the number of bytes per row. Each pixel in the bitmap in this
  // example is represented by 4 bytes; 8 bits each of red, green, blue, and
  // alpha.
  size_t bytesPerPixel = bitsPerComponent * componentsPerPixel / bitsPerByte;
//  NSAssert(bytesPerPixel == 4, @"unexpected measure of bytes per pixel");
  
  bitmapBytesPerRow   = (pixelsWide * bytesPerPixel); 
  bitmapByteCount     = (bitmapBytesPerRow * pixelsHigh);
  
  // Use the generic RGB color space.
  colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
  if (colorSpace == NULL)
  {
    fprintf(stderr, "Error allocating color space\n");
    return NULL;
  }
  
  // Allocate memory for image data. This is the destination in memory
  // where any drawing to the bitmap context will be rendered.
  bitmapData = malloc( bitmapByteCount );
  if (bitmapData == NULL)
  {
    fprintf (stderr, "Memory not allocated!");
    CGColorSpaceRelease( colorSpace );
    return NULL;
  }
  
  // Create the bitmap context. We want pre-multiplied ARGB, 8-bits
  // per component. Regardless of what the source image format is
  // (CMYK, Grayscale, and so on) it will be converted over to the format
  // specified here by CGBitmapContextCreate.
  context = CGBitmapContextCreate (bitmapData,
                                   pixelsWide,
                                   pixelsHigh,
                                   bitsPerComponent,     
                                   bitmapBytesPerRow,
                                   colorSpace,
                                   kCGImageAlphaPremultipliedFirst);
  if (context == NULL)
  {
    free (bitmapData);
    fprintf (stderr, "Context not created!");
  }
  
  // Make sure and release colorspace before returning
  CGColorSpaceRelease( colorSpace );
  
  return context;
}

CGContextRef CreateAlphaOnlyBitmapContext (CGImageRef inImage)
{
  const NSUInteger bitsPerByte = 8; // definitional
  const NSUInteger componentsPerPixel = 1;   // kCGImageAlphaOnly
  const NSUInteger bitsPerComponent = 8; // our choice of color & alpha depth
  
  CGContextRef    context = NULL;
  void *          bitmapData;
  size_t          bitmapByteCount;
  size_t          bitmapBytesPerRow;
  
  // Get image width, height. We'll use the entire image.
  size_t pixelsWide = CGImageGetWidth(inImage);
  size_t pixelsHigh = CGImageGetHeight(inImage);
  
  // Declare the number of bytes per row. Each pixel in the bitmap in this
  // example is represented by 4 bytes; 8 bits each of red, green, blue, and
  // alpha.
  size_t bytesPerPixel = bitsPerComponent * componentsPerPixel / bitsPerByte;
  
  bitmapBytesPerRow   = (pixelsWide * bytesPerPixel);
  bitmapByteCount     = (bitmapBytesPerRow * pixelsHigh);
  
  // Allocate memory for image data. This is the destination in memory
  // where any drawing to the bitmap context will be rendered.
  bitmapData = malloc( bitmapByteCount );
  if (bitmapData == NULL)
  {
    fprintf (stderr, "Memory not allocated!");
    return NULL;
  }
  
  // Create the alpha-only bitmap context.
  context = CGBitmapContextCreate (bitmapData,
                                   pixelsWide,
                                   pixelsHigh,
                                   bitsPerComponent,
                                   bitmapBytesPerRow,
                                   NULL,
                                   kCGImageAlphaOnly);
  if (context == NULL)
  {
    free (bitmapData);
    fprintf (stderr, "Context not created!");
  }
  
  // populate the bitmap context from the image
  CGContextDrawImage(context, CGRectMake(0, 0, pixelsWide, pixelsHigh),inImage);
  return context;
}

/**
  Returns YES if image has and uses an alpha channel, or if there was an error.
 */
// code adapted from http://developer.apple.com/library/mac/#qa/qa1509/_index.html
BOOL HasAndUsesAlphaChannel(CGImageRef inImage)
{
  CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(inImage);
  if (alphaInfo == kCGImageAlphaNone ||
      alphaInfo == kCGImageAlphaNoneSkipFirst ||
      alphaInfo == kCGImageAlphaNoneSkipLast) {
    // does not even have an alpha channel
    return NO;
  }
  
  BOOL usesAlphaResult = NO; // presumed no

  // Get image width, height. We'll use the entire image.
  size_t w = CGImageGetWidth(inImage);
  size_t h = CGImageGetHeight(inImage);
  CGRect rect = {{0,0},{w,h}};
  
  // Create the bitmap context
  CGContextRef cgctx = CreateARGBBitmapContext(inImage);
  // assert: bytesPerPixel = 4;
  if (cgctx == NULL)
  {
    // error creating context
    fprintf(stderr, "unable to create ARGB bitmap context from image");
    return YES;
  }
  
  // Draw the image to the bitmap context. Once we draw, the memory
  // allocated for the context for rendering will then contain the
  // raw image data in the specified color space.
  CGContextDrawImage(cgctx, rect, inImage);
  
  // Now we can get a pointer to the image data associated with the bitmap
  // context.
  void *data = CGBitmapContextGetData (cgctx);
  if (data != NULL)
  {
    typedef struct pixel
    {
      unsigned char alpha; // 1 byte for alpha
      unsigned char red;   // 1 byte for red,
      unsigned char green; // etc..
      unsigned char blue;
    } pixel_t;

    pixel_t * pixels = data;
//    fprintf(stdout, "inspecting {%zu,%zu} rect of pixels with 32 bits per pixel\n", w,h);

    for (unsigned int y= 0; y < h; ++y) {
//      fprintf(stdout, "printing row y=%u\n",y);
      for (unsigned int x =0; x < w; ++x) {
//        fprintf(stdout, "  printing col x=%u:",x);
        pixel_t p = pixels[y * w + x];
//        fprintf(stdout, "  pixel = {%u,%u,%u,%u}",p.alpha,p.red,p.green,p.blue);
//        fprintf(stdout,"\n");
        if (p.alpha != 255) {
          fprintf(stdout,"at {%u,%u}, found non-translucent ARGB pixel = {%u,%u,%u,%u}\n",x,y,p.alpha,p.red,p.green,p.blue);
          usesAlphaResult = YES;
//          goto finish;
        }
      }
    }

  }
  
finish:;
  
  // When finished, release the context
  CGContextRelease(cgctx);
  // Free image data memory for the context
  if (data)
  {
    free(data);
  }
  
  return usesAlphaResult;
}

// determines if image has an alpha layer
BOOL HasAlpha(CGImageRef image) {
  CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(image);
  if (alphaInfo == kCGImageAlphaNone ||
      alphaInfo == kCGImageAlphaNoneSkipFirst ||
      alphaInfo == kCGImageAlphaNoneSkipLast) {
    return NO;
  }
  else {
    return YES;
  }
}


int main(int argc, const char * argv[])
{
  
  @autoreleasepool {
    
    if (argc != 2) {
      NSLog(@"usage: StripAlphaIfNeeded /full/path/to/file.png");
      exit(1);
    }
    
    NSString * PNGFilepath = [NSString stringWithCString:argv[1] encoding:NSUTF8StringEncoding];
    if (![[NSFileManager defaultManager] fileExistsAtPath:PNGFilepath]) {
      NSLog(@"No file found at path %@",PNGFilepath);
      exit(1);
    }
    
    CGImageRef image = MyCreateCGImageFromFile(PNGFilepath);
    if (!image) {
      NSLog(@"Unable to create CGImageRef from file %@",PNGFilepath);
      exit(1);
    }
    
    NSString * const filename = [PNGFilepath lastPathComponent];
    
    BOOL const hasAlphaLayer = HasAlpha(image);

    if (!hasAlphaLayer) {
      NSLog(@"image %@ : hasAlpha = NO ; usesAlpha = NO",filename);
      exit(0);
    }

    BOOL const usesAlphaLayer = HasAndUsesAlphaChannel(image);
    if (usesAlphaLayer) {
      NSLog(@"image %@ : hasAlpha = YES; usesAlpha = YES",filename);
      exit(0);
    }
    else
    {
      NSLog(@"image %@ : hasAlpha = YES; usesAlpha = NO",filename);
      exit(0);
    }
  }
  return 0;
}

