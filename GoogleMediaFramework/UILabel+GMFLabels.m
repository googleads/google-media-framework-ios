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

#import "UILabel+GMFLabels.h"

@implementation UILabel (GMFLabelsAdditions)

+ (UILabel *)GMF_clearLabelForPlayerControls {
  UILabel *label = [[UILabel alloc] init];
  label.backgroundColor = [UIColor clearColor];
  
  UIFont *labelFont = [UIFont fontWithName:@"Helvetica" size:12.0];
  [label GMF_setFont:labelFont andColor:[UIColor whiteColor]];
  return label;
}

- (void)GMF_setFont:(UIFont *)font andColor:(UIColor *)color {
  [self setFont:font];
  if (color) {
    [self setTextColor:color];
  }
}

@end

