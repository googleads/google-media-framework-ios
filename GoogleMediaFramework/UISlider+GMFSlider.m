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

#import "UISlider+GMFSlider.h"

@implementation UISlider (GMFSlider)

// Modify UISlider so that when the bar is tapped, the thumb jumps to the tapped location.
- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
  [super beginTrackingWithTouch:touch withEvent:event];
  
  // We do the math to compute where the center of the thumb should be placed.
  CGPoint touchedPoint = [touch locationInView:self];
  float barWidth = self.maximumValue - self.minimumValue;
  float effectiveBarWidth = self.frame.size.width - self.currentThumbImage.size.width;
  float effectiveXPosition = touchedPoint.x - self.currentThumbImage.size.width / 2;
  float newValue = self.minimumValue + barWidth * (effectiveXPosition / effectiveBarWidth);

  [self setValue:newValue animated:YES];

  return YES;
}
@end
