//
//  UIButton+GMFTintableButton.m
//  Pods
//
//  Created by hsubrama on 6/26/14.
//
//

#import "UIButton+GMFTintableButton.h"

@implementation UIButton (GMFTintableButton)

- (void)applyTintColor:(UIColor *)color {
  
  if (!color || !self.imageView.image) {
    return;
  }
  
  UIImage *currentImage = self.imageView.image;
  
  UIGraphicsBeginImageContextWithOptions(currentImage.size, NO, currentImage.scale);
  CGContextRef context = UIGraphicsGetCurrentContext();
  
  CGContextTranslateCTM(context, 0, currentImage.size.height);
  CGContextScaleCTM(context, 1.0, -1.0);
  CGContextSetBlendMode(context, kCGBlendModeNormal);
  CGRect imageRectangle = CGRectMake(0, 0, currentImage.size.width, currentImage.size.height);
  CGContextClipToMask(context, imageRectangle, currentImage.CGImage);
  
  [color setFill];
  CGContextFillRect(context, imageRectangle);
  
  UIImage *tintedImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  
  [self setImage:tintedImage forState:UIControlStateNormal];
}


@end

