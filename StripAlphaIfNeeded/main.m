//
//  main.m
//  StripAlphaIfNeeded
//
//  Created by Alexis Gallagher on 2012-12-10.
//  Copyright (c) 2012 Foxtrot Studios. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>

/**
 Creates an uncached CGImage, allowing floating point values
 
 Code adpated from the ImageIO Programming Guide
 */
CGImageRef MyCreateCGImageFromFile (NSString* path)
{
  // Create the options dictionary to allow resolution
  CFDictionaryRef myOptions = CFDictionaryCreate(kCFAllocatorDefault,
                                                 (const void **) (CFStringRef[]){ kCGImageSourceShouldAllowFloat },
                                                 (const void **) (CFTypeRef[])  { (CFTypeRef) kCFBooleanTrue },
                                                 1,
                                                 &kCFTypeDictionaryKeyCallBacks,
                                                 &kCFTypeDictionaryValueCallBacks);
  
  // Create an image source from the URL.
  CGImageSourceRef myImageSource = CGImageSourceCreateWithURL((__bridge CFURLRef) [NSURL fileURLWithPath:path],
                                                              myOptions);
  CFRelease(myOptions);
  
  // Make sure the image source exists before continuing
  if (myImageSource == NULL){
    fprintf(stderr, "Image source is NULL.");
    return  NULL;
  }
  
  // Create an image from the first item in the image source.
  CGImageRef myImage = CGImageSourceCreateImageAtIndex(myImageSource, 0, NULL);
  
  CFRelease(myImageSource);
  
  // Make sure the image exists before continuing
  if (myImage == NULL){
    fprintf(stderr, "Image not created from image source.");
    return NULL;
  }
  
  return myImage;
}

/**
 Returns bitmap context with premultiplied ARGB components, 8 bits each.
 
 That is, 32 bits per pixel: 8 pixels for Alpha, 8 bits for Alpha*Red,
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

/**
 Returns YES if image has and uses an alpha channel, or if there was an error.

 code adapted from http://developer.apple.com/library/mac/#qa/qa1509/_index.html
 */
BOOL UsesAlphaChannel(CGImageRef inImage, BOOL verboseLogging)
{
  BOOL usesAlphaResult = NO; // presumed no
  
  // Get image width, height. We'll use the entire image.
  size_t w = CGImageGetWidth(inImage);
  size_t h = CGImageGetHeight(inImage);
  CGRect rect = CGRectMake(0, 0, w, h);
  
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
  
  // Now we can get a pointer to the image data associated with the bitmap context.
  void *data = CGBitmapContextGetData (cgctx);
  if (data != NULL)
  {
    typedef struct pixel
    {
      UInt8 alpha; // 1 byte for alpha
      UInt8 red;   // 1 byte for red,
      UInt8 green; // etc..
      UInt8 blue;
    } pixel_t;
    
    pixel_t * pixels = data;
    if (verboseLogging) {
      fprintf(stdout, "inspecting {%zu,%zu} rect of pixels with 32 bits per pixel\n", w,h);
    }
    
    for (size_t y= 0; y < h; ++y) {
      if (verboseLogging) {
        fprintf(stdout, "printing row y=%zu\n",y);
      }
      for (size_t x =0; x < w; ++x) {
        if (verboseLogging) {
          fprintf(stdout, "  printing col x=%zu:",x);
        }
        pixel_t p = pixels[y * w + x];
        if (verboseLogging) {
          fprintf(stdout, "  pixel = {%u,%u,%u,%u}",p.alpha,p.red,p.green,p.blue);
          fprintf(stdout,"\n");
        }
        if (p.alpha != 255) {
          if (verboseLogging) {
            fprintf(stdout,"at {%zu,%zu}, found non-translucent ARGB pixel = {%u,%u,%u,%u}\n",x,y,p.alpha,p.red,p.green,p.blue);
          }
          usesAlphaResult = YES;
        }
      }
    }
  }
  
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
    
    BOOL verbose = NO;
    
    NSString * PNGFilepath;
    if (argc != 2 && argc != 3) {
      printf("usage: UsesAlpha /full/path/to/file.png\n");
      exit(1);
    }
    else if (argc==2) {
      verbose = NO;
      PNGFilepath = [NSString stringWithCString:argv[1] encoding:NSUTF8StringEncoding];
    }
    else if (argc==3 &&
             [@"--verbose" isEqualToString:[NSString stringWithCString:argv[1] encoding:NSUTF8StringEncoding]]) {
      verbose = YES;
      PNGFilepath = [NSString stringWithCString:argv[2] encoding:NSUTF8StringEncoding];
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:PNGFilepath]) {
      fprintf(stderr,"No file found at path %s\n",[PNGFilepath cStringUsingEncoding:NSUTF8StringEncoding]);
      exit(1);
    }
    else {
      printf("%s\n",[PNGFilepath cStringUsingEncoding:NSUTF8StringEncoding]);
    }
    
    CGImageRef image = MyCreateCGImageFromFile(PNGFilepath);
    if (!image) {
      fprintf(stderr,"Unable to create image from file %s\n",[PNGFilepath cStringUsingEncoding:NSUTF8StringEncoding]  );
      exit(1);
    }
    
    BOOL const hasAlphaLayer = HasAlpha(image);
    
    if (!hasAlphaLayer) {
      printf("  hasAlpha  = NO\n");
      exit(0);
    } else {
      printf("  hasAlpha  = YES\n");
    }
    
    BOOL const usesAlphaLayer = UsesAlphaChannel(image,verbose);
    if (usesAlphaLayer) {
      printf("  usesAlpha = YES\n");
      exit(0);
    }
    else
    {
      printf("  usesAlpha = NO\n");
      exit(0);
    }
  // TODO? replace these preceding calls to exit with a goto to the end of the autorelease pool
  }
  return 0;
}

