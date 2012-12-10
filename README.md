This command line app detects when an image file has an alpha channel and does not use it.

To simply check if a file has an alpha channel, do

  sips -g hasAlpha moon.png

To remove an unneeded alpha channels, you can use imagemagick's convert utility. For
instance, to take the file moon.png and remove the alpha channel, using a black background, do as
follows:

  convert moon.png  -background black  -alpha remove  alpha_remove.png

If the alpha channel is truly not needed, because every pixel is opaque, then the background
color is irrelevant.

To observe which pixels are using alpha, extract a mask based on the alpha values:

  convert moon.png -alpha extract alpha_extract.png
  
http://www.imagemagick.org/Usage/masking/#alpha_extract


