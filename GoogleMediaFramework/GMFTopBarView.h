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

#import <UIKit/UIKit.h>

@interface GMFTopBarView : UIView


// Sets the logo image displayed in the left of the top bar.
// The logo's aspect ratio will be preserved, but it will be resized so that it will fit in the bar.
// Default width is the height of the top bar.
- (void)setLogoImage:(UIImage *)logoImage;

// Set the video title displayed in the left of the top bar.
// It is displayed to the right of the logo.
- (void)setVideoTitle:(NSString *)videoTitle;

// Adds an action button to the right of the top bar.
- (void)addActionButtonWithImage:(UIImage *)image
                            name:(NSString *)name
                          target:(id)target
                        selector:(SEL)selector;

- (CGFloat)preferredHeight;

@end
