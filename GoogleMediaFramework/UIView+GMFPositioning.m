// Copyright 2013 Google Inc. All rights reserved.
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

#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

#import "UIView+GMFPositioning.h"

@implementation UIView (GMFPositioningAdditions)

// TODO(tensafefrogs): Revisit these helper methods. Some may be unnecessary or could be made more
// specific or useful for the video player UI.
- (void)GMF_setSize:(CGSize)size {
  CGRect frame = [self frame];
  [self setFrame:CGRectMake(CGRectGetMinX(frame),
                            CGRectGetMinY(frame),
                            size.width,
                            size.height)];
}

- (CGFloat)GMF_visibleWidth {
  return [self isHidden] ? 0 : CGRectGetWidth(self.frame);
}

- (void)GMF_setOrigin:(CGPoint)origin {
  CGRect frame = [self frame];
  [self setFrame:CGRectMake(origin.x,
                            origin.y,
                            CGRectGetWidth(frame),
                            CGRectGetHeight(frame))];
}

- (CGPoint)GMF_origin {
  return [self frame].origin;
}

- (void)GMF_alignCenterLeftToCenterLeftOfView:(UIView *)view
                                     paddingX:(CGFloat)paddingX {
  CGRect rect = [self convertRect:view.bounds fromView:view];
  [self GMF_setPixelAlignedFrame:CGRectMake(
      CGRectGetMinX(rect) + paddingX,
      CGRectGetMinY(rect) + (CGRectGetHeight(rect) - CGRectGetHeight(self.frame)) / 2,
      CGRectGetWidth(self.frame),
      CGRectGetHeight(self.frame))];
}

- (void)GMF_setPixelAlignedFrame:(CGRect)frameRect {
  self.frame = [UIView GMF_pixelAlignedRect:frameRect];
}

- (void)GMF_setPixelAlignedOrigin:(CGPoint)origin {
  [self GMF_setOrigin:[UIView GMF_pixelAlignedPoint:origin]];
}

// Utilities for keeping things aligned to whole pixel values to prevent image distortion.
+ (CGFloat)GMF_pixelAlignedValue:(CGFloat)value {
  CGFloat screenScale = [[UIScreen mainScreen] scale];
  return floorf(value * screenScale) / screenScale;
}

+ (CGPoint)GMF_pixelAlignedPoint:(CGPoint)point {
  return CGPointMake([self GMF_pixelAlignedValue:point.x],
                     [self GMF_pixelAlignedValue:point.y]);
}

+ (CGSize)GMF_pixelAlignedSize:(CGSize)size {
  return CGSizeMake([self GMF_pixelAlignedValue:size.width],
                    [self GMF_pixelAlignedValue:size.height]);
}

+ (CGRect)GMF_pixelAlignedRect:(CGRect)rect {
  return CGRectMake([self GMF_pixelAlignedValue:rect.origin.x],
                    [self GMF_pixelAlignedValue:rect.origin.y],
                    [self GMF_pixelAlignedValue:rect.size.width],
                    [self GMF_pixelAlignedValue:rect.size.height]);
}

@end


