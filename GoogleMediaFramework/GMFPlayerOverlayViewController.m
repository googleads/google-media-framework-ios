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
#import "GMFPlayerOverlayViewController.h"

static const NSInteger kPaddingTop = 60;
static const NSTimeInterval kAutoHideUserForcedAnimationDuration = 0.2;
static const NSTimeInterval kAutoHideFadeAnimationDuration = 0.4;
static const NSTimeInterval kAutoHideAnimationDelay = 2.0;

@interface GMFPlayerOverlayViewController ()

@end

@implementation GMFPlayerOverlayViewController

// TODO(tensafefrogs): Figure out a nice way to display playback errors here.
- (id)init {
  self = [super init];
  if (self) {
    _isAdDisplayed = NO;
    _autoHideEnabled = YES;
  }
  return self;
}

- (void)loadView {
  CGRect screenRect = [[UIScreen mainScreen] bounds];
  CGFloat screenWidth = screenRect.size.width;
  CGFloat screenHeight = screenRect.size.height;
  CGRect frameRect = CGRectMake(0,
                                kPaddingTop,
                                screenWidth,
                                screenHeight);
  _playerOverlayView = [[GMFPlayerOverlayView alloc] initWithFrame:frameRect];
  [self setView:_playerOverlayView];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [self.playerOverlayView setDelegate:self.delegate];
  [_playerOverlayView showSpinner];
  [self playerStateDidChangeToState:_playerState];
}

- (void)setDelegate:(id <GMFPlayerOverlayViewControllerDelegate>) delegate {
  // Store delegate in case the view isn't loaded yet.
  _delegate = delegate;
  [_playerOverlayView setDelegate:delegate];
}

- (void)setIsAdDisplayed:(BOOL)isAdDisplayed {
  _isAdDisplayed = isAdDisplayed;
  [self updateAutoHideEnabled];
}

- (GMFPlayerControlsView *)playerControlsView {
  return _playerOverlayView.playerControlsView;
}

- (void)setUserScrubbing:(BOOL)userScrubbing {
  _userScrubbing = userScrubbing;
  [self updateAutoHideEnabled];
  if (self.userScrubbing) {
    [_playerOverlayView showSpinner];
  } else {
    // Refresh the state so the correct button is shown.
    [self playerStateDidChangeToState:_playerState];
  }
}

- (void)playerStateDidChangeToState:(GMFPlayerState)toState {
  _playerState = toState;
  [self updatePlayerBarViewButtonWithState:toState];
  if (self.userScrubbing) {
    return;
  }
  [self updateAutoHideEnabled];
  
  switch (toState) {
    case kGMFPlayerStateEmpty:
      break;
    case kGMFPlayerStatePaused:
    case kGMFPlayerStatePlaying:
    case kGMFPlayerStateFinished:
    case kGMFPlayerStateError:
      [_playerOverlayView hideSpinner];
      break;
    case kGMFPlayerStateLoadingContent:
    case kGMFPlayerStateReadyToPlay:
    case kGMFPlayerStateBuffering:
    case kGMFPlayerStateSeeking:
      [_playerOverlayView showSpinner];
      break;
  }

  if (toState == kGMFPlayerStateReadyToPlay
      || toState == kGMFPlayerStateError
      || toState == kGMFPlayerStateFinished) {
    [self showPlayerControlsAnimated:YES];
  } else {
    [self updatePlayerControlsVisibility];
  }
}

- (void)setTotalTime:(NSTimeInterval)totalTime {
  [_playerOverlayView setTotalTime:totalTime];
}

- (void)setMediaTime:(NSTimeInterval)mediaTime {
  [_playerOverlayView setMediaTime:mediaTime];
}

- (void)updatePlayerControlsVisibility {
  if (!_playerControlsHidden) {
    [self showPlayerControlsAnimated:YES];
  } else {
    [self hidePlayerControlsAnimated:YES];
  }
}

- (void)showPlayerControlsAnimated:(BOOL)animated {
  if (animated) {
    [self animatePlayerControlsToHidden:NO
                      animationDuration:kAutoHideUserForcedAnimationDuration
                             afterDelay:0];
  } else {
    [self playerControlsWillShow];
    [self playerControlsDidShow];
  }
  if (_autoHideEnabled) {
    [self animatePlayerControlsToHidden:YES
                      animationDuration:kAutoHideFadeAnimationDuration
                             afterDelay:kAutoHideAnimationDelay];
  }
}

- (void)hidePlayerControlsAnimated:(BOOL)animated {
  [self animatePlayerControlsToHidden:animated
                    animationDuration:kAutoHideUserForcedAnimationDuration
                           afterDelay:0];
}

- (void)playerControlsDidHide {
  // Override in a subclass to be notified when _autoHideView is hidden.
  [_videoPlayerOverlayViewControllerDelegate playerControlsDidHide];
}

- (void)playerControlsWillHide {
  // Override in a subclass to be notified when _autoHideView starts hiding.
  [_playerOverlayView setPlayerBarVisible:NO];
  _playerControlsHidden = YES;
}

- (void)playerControlsDidShow {
  // Override in a subclass to be notified when _autoHideView is shown.
  [_videoPlayerOverlayViewControllerDelegate playerControlsDidShow];
}

- (void)playerControlsWillShow {
  // Override in a subclass to be notified when _autoHideView starts showing.
  [_playerOverlayView setPlayerBarVisible:YES];
  _playerControlsHidden = NO;
}

- (void)togglePlayerControlsVisibility {
  // Hide/show the autoHideView as appropriate.
  if (_playerControlsHidden) {
    [self showPlayerControlsAnimated:YES];
  } else {
    [self hidePlayerControlsAnimated:YES];
  }
}

#pragma mark Private Methods

- (GMFPlayerOverlayView *)playerOverlayView {
  return (GMFPlayerOverlayView *)[self view];
}

- (void)updateAutoHideEnabled {
  BOOL enabled = _isAdDisplayed || ((_playerState == kGMFPlayerStatePlaying) &&
                                    !self.userScrubbing);
  if (_autoHideEnabled != enabled) {
    _autoHideEnabled = enabled;
    if (!enabled) {
      [NSObject cancelPreviousPerformRequestsWithTarget:self];
    } else {
      [self animatePlayerControlsToHidden:YES
                        animationDuration:kAutoHideFadeAnimationDuration
                               afterDelay:kAutoHideAnimationDelay];
    }
  }
}

- (void)animatePlayerControlsToHidden:(BOOL)hidden
                    animationDuration:(NSTimeInterval)duration
                           afterDelay:(NSTimeInterval)delay {
  // If we animate before the view is loaded,
  // then the first call to layoutSubviews may be animated.
  if (![self isViewLoaded]) {
    return;
  }
  void (^animateAutoHideViewBlock)(void) = ^(void) {
    [UIView animateWithDuration:duration
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState |
                            UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                       if (hidden) {
                         [self playerControlsWillHide];
                       } else {
                         [self playerControlsWillShow];
                       }
                     }
                     completion:^(BOOL finished) {
                       if (finished) {
                         if (hidden) {
                           [self playerControlsDidHide];
                         } else {
                           [self playerControlsDidShow];
                         }
                       }
                     }];
  };

  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  if (delay) {
    [self performSelector:@selector(performVoidBlock:)
               withObject:animateAutoHideViewBlock
               afterDelay:delay];
  } else {
    animateAutoHideViewBlock();
  }
}

// Simply executes the block passed to it.
// Used to execute a block after a delay using performSelector.
- (void)performVoidBlock:(void (^)(void))block {
  block();
}

- (void)updatePlayerBarViewButtonWithState:(GMFPlayerState)playerState {
  switch (playerState) {
    case kGMFPlayerStateEmpty:
    case kGMFPlayerStateReadyToPlay:
    case kGMFPlayerStatePaused:
      [[self playerOverlayView] showPlayButton];
      break;
    case kGMFPlayerStatePlaying:
      [[self playerOverlayView] showPauseButton];
      break;
    case kGMFPlayerStateFinished:
      [[self playerOverlayView] showReplayButton];
      break;
    default:
      break;
  }
}

- (void)reset {
  [self setTotalTime:0.0];
  [self setMediaTime:0.0];
  [self playerStateDidChangeToState:kGMFPlayerStateEmpty];
}

- (void)resetAutoHideTimer {
  if (!_autoHideEnabled) {
    return;
  }
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  [self animatePlayerControlsToHidden:YES
                    animationDuration:kAutoHideFadeAnimationDuration
                           afterDelay:kAutoHideAnimationDelay];
}

@end

