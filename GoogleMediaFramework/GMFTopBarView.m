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

#import "GMFTopBarView.h"
#import "UILabel+GMFLabels.h"
#import "GMFResources.h"

@implementation GMFTopBarView {
  UIImageView *_backgroundView;
  UILabel *_videoTitle;
  UIImageView *_logoImageView;
  NSMutableArray *_actionButtons;
}

- (id)init {
  self = [super initWithFrame:CGRectZero];
  
  if (self) {
    _backgroundView = [[UIImageView alloc] initWithImage:[GMFResources
                                                          playerTitleBarBackgroundImage]];
    [self addSubview:_backgroundView];

    _videoTitle = [UILabel GMF_clearLabelForPlayerControls];
    [_videoTitle setFont:[UIFont fontWithName:_videoTitle.font.familyName size:16.0]];
    [self addSubview:_videoTitle];
    
    _logoImageView = [[UIImageView alloc] init];
    _logoImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:_logoImageView];
    
    _actionButtons = [[NSMutableArray alloc] init];
  }
  
  [self setupLayoutConstraints];
  return self;
}

- (void)setupLayoutConstraints {
  [_videoTitle setTranslatesAutoresizingMaskIntoConstraints:NO];
  [_logoImageView setTranslatesAutoresizingMaskIntoConstraints:NO];
  [_backgroundView setTranslatesAutoresizingMaskIntoConstraints:NO];
  
  NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(_backgroundView,
                                                                 _videoTitle,
                                                                 _logoImageView);
  NSDictionary *metrics = @{@"space": [NSNumber numberWithInt:4]};
  
  // Lay out the elements next to each other.
  NSArray *constraints = [NSLayoutConstraint
      constraintsWithVisualFormat:@"H:|-space-[_logoImageView]-[_videoTitle]"
                          options:NSLayoutFormatAlignAllCenterY
                          metrics:metrics
                            views:viewsDictionary];
  
  // Make background fill the top bar.
  constraints = [constraints arrayByAddingObjectsFromArray:
                 [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_backgroundView]|"
                                                         options:0
                                                         metrics:nil
                                                           views:viewsDictionary]];
  
  constraints = [constraints arrayByAddingObjectsFromArray:
                 [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_backgroundView]|"
                                                         options:0
                                                         metrics:nil
                                                           views:viewsDictionary]];
  
  // Make the video title take up the full height of the top bar.
  constraints = [constraints arrayByAddingObjectsFromArray:
                 [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_videoTitle]|"
                                                         options:NSLayoutFormatAlignAllCenterX
                                                         metrics:metrics
                                                           views:viewsDictionary]];
  
  // Make the logo at most as wide the height of the bar.
  constraints = [constraints arrayByAddingObject:
                 [NSLayoutConstraint constraintWithItem:_logoImageView
                                              attribute:NSLayoutAttributeWidth
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:_logoImageView.superview
                                              attribute:NSLayoutAttributeHeight
                                             multiplier:1.0f
                                               constant:0.0f]];
  [self addConstraints:constraints];
}

- (void)addActionButtonWithImage:(UIImage *)image
                            name:(NSString *)name
                          target:(id)target
                        selector:(SEL)selector {
  
  // Create the button with the given image, name (used as the accessibility label),
  // and target/selector for UIControlEventTouchUpInside.
  UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
  [button setContentMode:UIViewContentModeScaleAspectFit];
  [button setImage:image forState:UIControlStateNormal];
  [button addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];
  [button setShowsTouchWhenHighlighted:YES];
  [button.imageView setContentMode:UIViewContentModeScaleAspectFit];
  [button setTranslatesAutoresizingMaskIntoConstraints:NO];
  [button setAccessibilityLabel:name];
  
  [self addSubview:button];
  [_actionButtons addObject:button];
  
  // Create the layout constraints.
  NSArray *constraints = [[NSArray alloc] init];
  
  if ([_actionButtons count] == 1) {
    // If this is the first action button, position it in the right of the top bar.
    constraints = [constraints arrayByAddingObject:
                   [NSLayoutConstraint constraintWithItem:button
                                                attribute:NSLayoutAttributeRight
                                                relatedBy:NSLayoutRelationEqual
                                                   toItem:button.superview
                                                attribute:NSLayoutAttributeRight
                                               multiplier:1.0f
                                                 constant:-15.0f]];
  } else {
    // If this is not the first button, position it to the left of the previous button that has
    // been placed.
    UIButton *previousButton = [_actionButtons objectAtIndex:[_actionButtons count] - 2];
    constraints = [constraints arrayByAddingObject:
                   [NSLayoutConstraint constraintWithItem:button
                                                attribute:NSLayoutAttributeRight
                                                relatedBy:NSLayoutRelationEqual
                                                   toItem:previousButton
                                                attribute:NSLayoutAttributeLeft
                                               multiplier:1.0f
                                                 constant:-10.0f]];
  }
  
  // Ensure that the button has the same height as the top bar.
  constraints = [constraints arrayByAddingObject:
                 [NSLayoutConstraint constraintWithItem:button
                                              attribute:NSLayoutAttributeHeight
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:button.superview
                                              attribute:NSLayoutAttributeHeight
                                             multiplier:1.0f
                                               constant:0.0f]];
  
  // Ensure that the button's width is equal to the top bar's height.
  constraints = [constraints arrayByAddingObject:
                 [NSLayoutConstraint constraintWithItem:button
                                              attribute:NSLayoutAttributeWidth
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:button.superview
                                              attribute:NSLayoutAttributeHeight
                                             multiplier:1.0f
                                               constant:0.0f]];
 
  // Ensure that the button is aligned at the bottom of the top bar.
  constraints = [constraints arrayByAddingObject:
                 [NSLayoutConstraint constraintWithItem:button
                                              attribute:NSLayoutAttributeBottom
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:button.superview
                                              attribute:NSLayoutAttributeBottom
                                             multiplier:1.0f
                                               constant:0.0f]];
  [self addConstraints:constraints];
}

- (void)setLogoImage:(UIImage *)logoImage {
  [_logoImageView setImage:logoImage];
}

- (void)setVideoTitle:(NSString *)videoTitle {
  [_videoTitle setText:videoTitle];
}

- (CGFloat)preferredHeight {
  return [[GMFResources playerTitleBarBackgroundImage] size].height;
}

@end
