# UsesAlpha #

This Cocoa snippet and command line app detects when an image file has an alpha channel which it does not need.

## what's alpha channel?

The alpha channel in an image is the information that represents translucency. If your image is 
totally opaque, then it doesn't need to have an alpha channel. If alpha channel is disabled 
(i.e., turned off), then iOS knows the image is opaque and can use the image more efficiently (as discussed
 in session WWDC2012, Session 238: iOS App Performance: Graphics and Animations, 16m50s).
 
If you not only disable alpha but also remove the alpha channel data, then your image will be smaller.

## so what should I do about it?

In theory, yes, you should take care to remove the alpha channel data from any images that are completely opaque.

But is it *really* worth doing? In practice, unclear. Probably it is useful at runtime but not useful at compile-time. Here's the puzzle. Apple has definitely advised developers to remove unneeded alpha channel data from images in order to make them smaller. However, a little detective work (thanks, [MaxGabriel](https://github.com/MaxGabriel)!) seems to indicate that Xcode always processes images with a (modified) version of pngcrush and that pngcrush has automatically removed unneeded alpha data since 1.4.8. So why is Apple advising us to remove the alpha channel data ourselves if their own tool already removes it? You tell me and we'll both know. Maybe they don't want us to count on the pngcrush behavior. Maybe they're unaware of it. Maybe they're referring to images acquired at runtime.

If you're serious about image optimization at compile-time, you should look into [ImageOptim](http://imageoptim.com), [ImageAlpha](http://pngmini.com), [ImageMagick](http://www.imagemagick.org), and other heavyweight tools. It seems like the code in this repo is only likely to be useful if you need to do some of this work at runtime on the device, or if you cannot install third-party tools onto your build machine because of third-party policies etc.. 

## checking if alpha channel is enabled in an image

How do you check if an image has an alpha channel which is enabled? Check its file info in Preview, or in the Xcode File Inspector. Or from the command line, do

    sips -g hasAlpha moon.png

## removing alpha channel data from an image

To remove an unneeded alpha channel, you can save it without alpha from Preview.app. Or from the command line, you can use imagemagick's convert utility. For instance, to take the file moon.png and remove the alpha channel data, using a black background, and turn off alpha, do as follows:

    convert moon.png  -background black  -alpha remove -alpha off  alpha_remove.png

If the alpha channel is truly not needed, because every pixel is opaque, then the background
color is irrelevant.

## checking if alpha channel is enabled, but superfluous

To check if an image has an enabled alpha channel, but does not actually need it, we need to 
verify that the alpha value of every pixel in the image is 1, which represents no transparency at all.

One way to do this is to extract an image mask based only on the alpha values, and inspect that 
image to see if it has any non-white pixels. From the command line, create the mask as follows:

    convert moon.png -alpha extract alpha_extract.png
  
But now you need to inspect every pixel of the extracted image, so this is not automatic.

What's an automated solution you can apply to multiple files to automatically check for unnecessarily enabled alpha channel in an image?

That's what this command line tool is for. Use it as follows:

    ./UsesAlpha moon.png

Further information:

- Ref for ImageMagick's convert: http://www.imagemagick.org/Usage/masking/#alpha_extract

- Ref for SIPS's hasAlpha property: https://developer.apple.com/library/mac/#documentation/Darwin/Reference/ManPages/man1/sips.1.html
- Ref for pngcrush changelog indicating it removes unneeded alpha channel data: http://pmt.sourceforge.net/pngcrush/changelog.html

- MaxGabriel's excellent investigation into whether this is needed: https://github.com/algal/UsesAlpha/issues/1

