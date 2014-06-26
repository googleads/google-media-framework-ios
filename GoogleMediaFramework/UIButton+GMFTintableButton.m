// Copyright 2014 Google Inc. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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

