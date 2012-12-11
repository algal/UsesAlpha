This command line app detects when an image file has an alpha channel it does not need.

## what's alpha channel?

The alpha channel in an image is the information that represents translucency. If your image is 
totally opaque, then it doesn't need to have an alpha channel. If alpha channel is disabled 
(i.e., turned off), then iOS knows the image is opaque and can use it more efficiently (as discussed
 in session WWDC2012, Session 238: iOS App Performance: Graphics and Animations, 16m50s).
 
If you not only disable alpha, but remove the alpha channel data, then your image will be smaller.

## checking if alpha channel is enabled in an image

How do you check if an image has an alpha channel which is enabled? Check its file info in Preview,
or in the Xcode File Inspector. Or from the command line, do

    sips -g hasAlpha moon.png

## removing alpha channel from an image

To remove an unneeded alpha channel, you can save it without alpha from Preview.app. Or from the
command line, you can use imagemagick's convert utility. For instance, to take the file moon.png 
and remove the alpha channel data, using a black background, and turn off alpha, do as follows:

    convert moon.png  -background black  -alpha remove -alpha off  alpha_remove.png

If the alpha channel is truly not needed, because every pixel is opaque, then the background
color is irrelevant.

## checking if alpha channel is enabled, but superfluous

To check if an image has an enabled alpha channel, but does not actually need it, we need to 
verify that the alpha value of every pixel in the image is 1, which represents no transparency at 
all.

One way to do this is to extract an image mask based only on the alpha values, and inspect that 
image to see if it has any non-white pixels. From the command line, create the mask as follows:

    convert moon.png -alpha extract alpha_extract.png
  
But now you need to inspect every pixel of the extracted image, so this is not automatic.

What's an automated solution you can apply to multiple files to automatically check for unnecessarily
enabled alpha channel in an image?

That's what this command line tool is for. Use it as follows:

    ./UsesAlpha moon.png


Ref for ImageMagick's convert: http://www.imagemagick.org/Usage/masking/#alpha_extract
Ref for SIPS's hasAlpha property: https://developer.apple.com/library/mac/#documentation/Darwin/Reference/ManPages/man1/sips.1.html

