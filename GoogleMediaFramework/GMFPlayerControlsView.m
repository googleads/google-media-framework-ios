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

#import "GMFPlayerControlsView.h"
#import "GMFResources.h"
#import "UILabel+GMFLabels.h"

static const CGFloat kGMFBarPaddingX = 4;

@implementation GMFPlayerControlsView {
  UIImageView *_backgroundView;
  UIButton *_playButton;
  UIButton *_pauseButton;
  UIButton *_replayButton;
  UIButton *_minimizeButton;
  UILabel *_secondsPlayedLabel;
  UILabel *_totalSecondsLabel;
  UISlider *_scrubber;
  NSTimeInterval _totalSeconds;
  NSTimeInterval _mediaTime;
  NSTimeInterval _downloadedSeconds;
  BOOL _userScrubbing;

  __weak id<GMFPlayerControlsViewDelegate> _delegate;
}

// TODO(tensafefrogs): Add _secondsPlayedLabel / _totalSecondsLabel to controls
- (id)init {
  self = [super initWithFrame:CGRectZero];
  if (self) {
    _backgroundView = [[UIImageView alloc] initWithImage:[GMFResources playerBarBackgroundImage]];
    [self addSubview:_backgroundView];

    _secondsPlayedLabel = [UILabel GMF_clearLabelForPlayerControls];
    [_secondsPlayedLabel setTextAlignment:NSTextAlignmentCenter];
    [_secondsPlayedLabel setIsAccessibilityElement:NO];
    [self addSubview:_secondsPlayedLabel];

    _totalSecondsLabel = [UILabel GMF_clearLabelForPlayerControls];
    [_totalSecondsLabel setIsAccessibilityElement:NO];
    [self addSubview:_totalSecondsLabel];

    _playButton = [self playerButtonWithImage:[GMFResources playerBarPlayButtonImage]
                                       action:@selector(didPressPlay:)
                           accessibilityLabel:@"Play"];
    [self addSubview:_playButton];

    _pauseButton = [self playerButtonWithImage:[GMFResources playerBarPauseButtonImage]
                                        action:@selector(didPressPause:)
                            accessibilityLabel:@"Pause"];
    [self addSubview:_pauseButton];

    _replayButton = [self playerButtonWithImage:[GMFResources playerBarReplayButtonImage]
                                         action:@selector(didPressReplay:)
                             accessibilityLabel:@"Replay"];
    [self addSubview:_replayButton];

    // Seekbar
    _scrubber = [[UISlider alloc] init];
    [_scrubber setMinimumValue:0.0];
    [_scrubber setAccessibilityLabel:@"Seek bar"];
    [self setSeekbarThumbToDefaultImage];
    [_scrubber setMaximumTrackTintColor:[UIColor colorWithWhite:122/255.0 alpha:1.0]];
    [_scrubber addTarget:self
                  action:@selector(didScrubbingProgress:)
        forControlEvents:UIControlEventValueChanged];
    // Scrubbing starts as soon as the user touches the scrubber.
    [_scrubber addTarget:self
                  action:@selector(didScrubbingStart:)
        forControlEvents:UIControlEventTouchDown];
    [_scrubber addTarget:self
                  action:@selector(didScrubbingEnd:)
        forControlEvents:UIControlEventTouchUpInside];
    [_scrubber addTarget:self
                  action:@selector(didScrubbingEnd:)
        forControlEvents:UIControlEventTouchUpOutside];
    [self addSubview:_scrubber];

    _minimizeButton = [self playerButtonWithImage:[GMFResources playerBarMinimizeButtonImage]
                                           action:@selector(didPressMinimize:)
                               accessibilityLabel:@"Minimize"];
    [self addSubview:_minimizeButton];

    [self setupLayoutConstraints];
    [self showPlayButton];
  }
  return self;
}

- (id)initWithFrame:(CGRect)frame {
  NSAssert(false, @"Invalid initializer.");
  return nil;
}

- (void)dealloc {
  [_playButton removeTarget:self
                     action:NULL
           forControlEvents:UIControlEventTouchUpInside];
  [_pauseButton removeTarget:self
                      action:NULL
            forControlEvents:UIControlEventTouchUpInside];
  [_replayButton removeTarget:self
                       action:NULL
             forControlEvents:UIControlEventTouchUpInside];
  [_scrubber removeTarget:self
                   action:NULL
         forControlEvents:UIControlEventAllEvents];
  [_minimizeButton removeTarget:self
                      action:NULL
            forControlEvents:UIControlEventTouchUpInside];
}

- (void)showPlayButton {
  [_playButton setHidden:NO];
  [_pauseButton setHidden:YES];
  [_replayButton setHidden:YES];
}

- (void)showPauseButton {
  [_playButton setHidden:YES];
  [_pauseButton setHidden:NO];
  [_replayButton setHidden:YES];
}

- (void)showReplayButton {
  [_playButton setHidden:YES];
  [_pauseButton setHidden:YES];
  [_replayButton setHidden:NO];
}

- (void)setupLayoutConstraints {
  [_backgroundView setTranslatesAutoresizingMaskIntoConstraints:NO];
  [_playButton setTranslatesAutoresizingMaskIntoConstraints:NO];
  [_pauseButton setTranslatesAutoresizingMaskIntoConstraints:NO];
  [_replayButton setTranslatesAutoresizingMaskIntoConstraints:NO];
  [_secondsPlayedLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
  [_totalSecondsLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
  [_scrubber setTranslatesAutoresizingMaskIntoConstraints:NO];
  [_minimizeButton setTranslatesAutoresizingMaskIntoConstraints:NO];

  NSDictionary *metrics = @{
      @"buttonPadding": @(kGMFBarPaddingX)
  };

  NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(_backgroundView,
                                                                 _playButton,
                                                                 _pauseButton,
                                                                 _replayButton,
                                                                 _secondsPlayedLabel,
                                                                 _scrubber,
                                                                 _totalSecondsLabel,
                                                                 _minimizeButton);

  // Align all to same Y, scrubber stretches in the middle.
  NSString *controlsVisualFormat = [NSString stringWithFormat:@"%@%@",
      @"|-buttonPadding-[_playButton]-[_secondsPlayedLabel]-[_scrubber]",
      @"-[_totalSecondsLabel]-[_minimizeButton]-buttonPadding-|"];
  NSArray *constraints = [NSLayoutConstraint
      constraintsWithVisualFormat:controlsVisualFormat
                          options:NSLayoutFormatAlignAllCenterY
                          metrics:metrics
                          views:viewsDictionary];

  // Set alignment of pauseButton and replayButton
  constraints = [constraints arrayByAddingObjectsFromArray:[NSLayoutConstraint
      constraintsWithVisualFormat:@"|-buttonPadding-[_pauseButton]"
                          options:NSLayoutFormatAlignAllCenterY
                          metrics:metrics
                          views:viewsDictionary]];
  constraints = [constraints arrayByAddingObjectsFromArray:[NSLayoutConstraint
      constraintsWithVisualFormat:@"|-buttonPadding-[_replayButton]"
                          options:NSLayoutFormatAlignAllCenterY
                          metrics:metrics
                            views:viewsDictionary]];

  // Not sure why using NSLayoutFormatAlignAllCenterY above doesn't center the buttons vertically,
  // so we need another set of constraints to center them vertically.
  constraints = [constraints arrayByAddingObject:
      [NSLayoutConstraint constraintWithItem:_playButton
                                   attribute:NSLayoutAttributeCenterY
                                   relatedBy:NSLayoutRelationEqual
                                      toItem:_playButton.superview
                                   attribute:NSLayoutAttributeCenterY
                                  multiplier:1.0f
                                    constant:0]];
  constraints = [constraints arrayByAddingObject:
      [NSLayoutConstraint constraintWithItem:_pauseButton
                                   attribute:NSLayoutAttributeCenterY
                                   relatedBy:NSLayoutRelationEqual
                                      toItem:_pauseButton.superview
                                   attribute:NSLayoutAttributeCenterY
                                  multiplier:1.0f
                                    constant:0]];
  constraints = [constraints arrayByAddingObject:
      [NSLayoutConstraint constraintWithItem:_replayButton
                                   attribute:NSLayoutAttributeCenterY
                                   relatedBy:NSLayoutRelationEqual
                                      toItem:_replayButton.superview
                                   attribute:NSLayoutAttributeCenterY
                                  multiplier:1.0f
                                    constant:0]];

  // Make background fill the controlbar.
  constraints = [constraints arrayByAddingObjectsFromArray:[NSLayoutConstraint
      constraintsWithVisualFormat:@"V:|[_backgroundView]|"
                          options:0
                          metrics:nil
                            views:viewsDictionary]];
  constraints = [constraints arrayByAddingObjectsFromArray:[NSLayoutConstraint
      constraintsWithVisualFormat:@"H:|[_backgroundView]|"
                          options:0
                          metrics:nil
                            views:viewsDictionary]];

  [self addConstraints:constraints];
}

- (void)setTotalTime:(NSTimeInterval)totalTime {
  _totalSeconds = totalTime;
}

- (void)setDownloadedTime:(NSTimeInterval)downloadedTime {
  _downloadedSeconds = downloadedTime;
}

- (void)setMediaTime:(NSTimeInterval)mediaTime {
  _mediaTime = mediaTime;
}

- (CGFloat)preferredHeight {
  return [[GMFResources playerBarBackgroundImage] size].height;
}

- (void)setDelegate:(id<GMFPlayerControlsViewDelegate>)delegate {
  _delegate = delegate;
}

- (void)updateScrubberAndTime {
  // TODO(tensafefrogs): Handle live streams
  [_scrubber setMaximumValue:_totalSeconds];
  [_totalSecondsLabel setText:[self stringWithDurationSeconds:_totalSeconds]];
  [_secondsPlayedLabel setText:[self stringWithDurationSeconds:_mediaTime]];
  if (_userScrubbing) {
    [self setMediaTime:[_scrubber value]];
    _userScrubbing = NO;
  } else {
    // If time is this low, we might be resetting the slider after a video completes, so don't want
    // it to slide back to zero animated.
    BOOL animated = _mediaTime <= 0.5;
    [_scrubber setValue:_mediaTime animated:animated];
  }
}

#pragma mark Private Methods

// Formats media time into a more readable format of HH:MM:SS.
- (NSString *)stringWithDurationSeconds:(NSTimeInterval)durationSeconds {
  NSInteger durationSecondsRounded = lround(durationSeconds);
  NSInteger seconds = (durationSecondsRounded) % 60;
  NSInteger minutes = (durationSecondsRounded / 60) % 60;
  NSInteger hours = durationSecondsRounded / 3600;
  if (hours) {
    return [NSString stringWithFormat:@"%d:%02d:%02d", hours, minutes, seconds];
  } else {
    return [NSString stringWithFormat:@"%d:%02d", minutes, seconds];
  }
}

- (void)setSeekbarThumbToDefaultImage {
  [_scrubber setThumbImage:
      [GMFResources playerBarScrubberThumbImage] forState:UIControlStateNormal];
}

- (void)didPressPlay:(id)sender {
  [_delegate didPressPlay];
}

- (void)didPressPause:(id)sender {
  [_delegate didPressPause];
}

- (void)didPressReplay:(id)sender {
  [_delegate didPressReplay];
}

- (void)didPressMinimize:(id)sender {
  [_delegate didPressMinimize];
}

- (void)didScrubbingStart:(id)sender {
  _userScrubbing = YES;
  [_delegate didStartScrubbing];
}

- (void)didScrubbingProgress:(id)sender {
  _userScrubbing = YES;
  [self updateScrubberAndTime];
}

- (void)didScrubbingEnd:(id)sender {
  _userScrubbing = YES;
  [_delegate didSeekToTime:[_scrubber value]];
  [_delegate didEndScrubbing];
  [self updateScrubberAndTime];
}

- (void)setSeekbarTrackColor:(UIColor *)color {
  [_scrubber setMinimumTrackTintColor:color];
}

- (void)disableSeekbarInteraction {
  [_scrubber setThumbImage:[[UIImage alloc] init] forState:UIControlStateNormal];
  [_scrubber setUserInteractionEnabled:NO];
}

- (void)enableSeekbarInteraction {
  [self setSeekbarThumbToDefaultImage];
  [_scrubber setUserInteractionEnabled:YES];
}

- (UIButton *)playerButtonWithImage:(UIImage *)image
                             action:(SEL)action
                 accessibilityLabel:(NSString *)accessibilityLabel {
  UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
  [button setImage:image forState:UIControlStateNormal];
  [button addTarget:self
             action:action
   forControlEvents:UIControlEventTouchUpInside];
  [button setAccessibilityLabel:accessibilityLabel];
  [button setExclusiveTouch:YES];
  [button setShowsTouchWhenHighlighted:YES];
  [button sizeToFit];
  return button;
}

@end

