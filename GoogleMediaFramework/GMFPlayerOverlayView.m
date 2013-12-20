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

#import "GMFPlayerOverlayView.h"

@implementation GMFPlayerOverlayView {
  UIActivityIndicatorView *_spinner;
}

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    _spinner = [[UIActivityIndicatorView alloc]
        initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [_spinner setUserInteractionEnabled:NO];
    [_spinner setIsAccessibilityElement:NO];
    [_spinner sizeToFit];
    [self addSubview:_spinner];

    // Player control bar
    _playerControlsView = [[GMFPlayerControlsView alloc] init];
    [self setSeekbarTrackColorDefault];
    [self addSubview:_playerControlsView];

    [self setupLayoutConstraints];
  }
  return self;
}

- (void)setupLayoutConstraints {
  //[self setTranslatesAutoresizingMaskIntoConstraints:NO];
  [_spinner setTranslatesAutoresizingMaskIntoConstraints:NO];
  [_playerControlsView setTranslatesAutoresizingMaskIntoConstraints:NO];

  NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(_spinner, _playerControlsView);

  // Align spinner to the center X and Y.
  NSArray *constraints =
     [NSLayoutConstraint constraintsWithVisualFormat:@"|[_spinner]|"
                                             options:NSLayoutFormatAlignAllCenterX
                                             metrics:nil
                                               views:viewsDictionary];
  // Technically this works with just the Y alignment, but xcode will complain about missing
  // constraints, so we add the X as well.
  constraints = [constraints arrayByAddingObject:
      [NSLayoutConstraint constraintWithItem:_spinner
                                   attribute:NSLayoutAttributeCenterY
                                   relatedBy:NSLayoutRelationEqual
                                      toItem:_spinner.superview
                                   attribute:NSLayoutAttributeCenterY
                                  multiplier:1.0f
                                    constant:0]];
  constraints = [constraints arrayByAddingObject:
      [NSLayoutConstraint constraintWithItem:_spinner
                                   attribute:NSLayoutAttributeCenterX
                                   relatedBy:NSLayoutRelationEqual
                                      toItem:_spinner.superview
                                   attribute:NSLayoutAttributeCenterX
                                  multiplier:1.0f
                                    constant:0]];


  // Align controlbar to the center bottom.
  NSDictionary *metrics = @{
      @"controlsHeight": @([_playerControlsView preferredHeight])
  };
  constraints = [constraints arrayByAddingObjectsFromArray:
      [NSLayoutConstraint constraintsWithVisualFormat:@"V:[_playerControlsView(controlsHeight)]|"
                                              options:NSLayoutFormatAlignAllBottom
                                              metrics:metrics
                                                views:viewsDictionary]];
  constraints = [constraints arrayByAddingObjectsFromArray:
      [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_playerControlsView]|"
                                              options:NSLayoutFormatAlignAllBottom
                                              metrics:nil
                                                views:viewsDictionary]];

  [self addConstraints:constraints];
}

- (void)setDelegate:(id<GMFPlayerControlsViewDelegate>)delegate {
  [_playerControlsView setDelegate:delegate];
}

- (void)showSpinner {
  [_spinner startAnimating];
  [_spinner setHidden:NO];
}

- (void)hideSpinner {
  [_spinner stopAnimating];
  [_spinner setHidden:YES];
}

- (void)setPlayerBarVisible:(BOOL)visible {
  [_playerControlsView setAlpha:visible ? 1 : 0];

  [self setNeedsLayout];
  [self layoutIfNeeded];
}

- (void)showPlayButton {
  [_playerControlsView showPlayButton];
}

- (void)showPauseButton {
  [_playerControlsView showPauseButton];
}

- (void)showReplayButton {
  [_playerControlsView showReplayButton];
}

- (void)setTotalTime:(NSTimeInterval)totalTime {
  [_playerControlsView setTotalTime:totalTime];
  [_playerControlsView updateScrubberAndTime];
}

- (void)setDownloadedTime:(NSTimeInterval)downloadedTime {
  [_playerControlsView setDownloadedTime:downloadedTime];
  [_playerControlsView updateScrubberAndTime];
}

- (void)setMediaTime:(NSTimeInterval)mediaTime {
  [_playerControlsView setMediaTime:mediaTime];
  [_playerControlsView updateScrubberAndTime];
}

- (void)setSeekbarTrackColor:(UIColor *)color {
  [_playerControlsView setSeekbarTrackColor:color];
}

- (void)setSeekbarTrackColorDefault {
  // Light blue
  [_playerControlsView setSeekbarTrackColor:[UIColor colorWithRed:0.08235294117
                                                            green:0.49411764705
                                                             blue:0.98431372549
                                                            alpha:1.0]];
}

- (void)disableSeekbarInteraction {
  [_playerControlsView disableSeekbarInteraction];
}

- (void)enableSeekbarInteraction {
  [_playerControlsView enableSeekbarInteraction];
}

// Check if the tap is over the subviews of the overlay, else let it go to handle taps
// in the aboveRenderingView
-(UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
  UIView *hitView = [super hitTest:point withEvent:event];
  if (hitView == self) {
    return nil;
  }
  return hitView;
}

@end

