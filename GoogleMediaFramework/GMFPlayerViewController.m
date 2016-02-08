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

#import "GMFIMASDKAdService.h"
#import "GMFPlayerFinishReason.h"
#import "GMFPlayerViewController.h"
#import "GMFPlayerOverlayViewController.h"

NSString * const kGMFPlayerCurrentMediaTimeDidChangeNotification =
    @"kGMFPlayerCurrentMediaTimeDidChangeNotification";
NSString * const kGMFPlayerCurrentTotalTimeDidChangeNotification =
    @"kGMFPlayerCurrentTotalTimeDidChangeNotification";
NSString * const kGMFPlayerPlaybackStateDidChangeNotification =
    @"kGMFPlayerPlaybackStateDidChangeNotification";
NSString * const kGMFPlayerStateDidChangeToFinishedNotification =
    @"kGMFPlayerStateDidChangeToFinishedNotification";
NSString * const kGMFPlayerStateWillChangeToFinishedNotification =
    @"kGMFPlayerStateWillChangeToFinishedNotification";

NSString * const kGMFPlayerPlaybackDidFinishReasonUserInfoKey =
    @"kGMFPlayerPlaybackDidFinishReasonUserInfoKey";
NSString * const kGMFPlayerPlaybackWillFinishReasonUserInfoKey =
    @"kGMFPlayerPlaybackWillFinishReasonUserInfoKey";

// If there is no overlay view created yet, but we receive a request to create action button,
// we store the request in a mutable array of dictionaries which we use to construct the the
// action buttons when the overlay view is created.
// The constant below are the keys of the dictionaries.
NSString *const kActionButtonImageKey = @"kActionButtonImageKey";
NSString *const kActionButtonNameKey = @"kActionButtonNameKey";
NSString *const kActionButtonTargetKey = @"kActionButtonTargetKey";
NSString *const kActionButtonSelectorKey = @"kActionButtonSelectorKey";

@interface GMFPlayerViewController ()

@property(nonatomic, strong) GMFVideoPlayer *player;

@end

@implementation GMFPlayerViewController {
  GMFPlayerView *_playerView;
  NSURL *_currentMediaURL;

  BOOL _isUserScrubbing;
  BOOL _wasPlayingBeforeSeeking;
  
  // If there is no overlay view created yet, but we receive a request to create action button,
  // we store the request in a mutable array of dictionaries which we use to construct the the
  // action buttons when the overlay view is created.
  // This mutable array stores the dictionaries.
  NSMutableArray *_actionButtonDictionaries;
}

// Perhaps you'd like to init a player with no content?
- (id)init {
  self = [super init];
  if (self) {
    _actionButtonDictionaries = [[NSMutableArray alloc] init];
    if (!_player) {
      _player = [[GMFVideoPlayer alloc] init];
      [_player setDelegate:self];
    }
  }
  return self;
}

- (void)setControlsVisibility:(BOOL)visible animated:(BOOL)animated {
  if (visible) {
    [_videoPlayerOverlayViewController showPlayerControlsAnimated:animated];
  } else {
    [_videoPlayerOverlayViewController hidePlayerControlsAnimated:animated];
  }
}

- (void)loadStreamWithURL:(NSURL *)URL {
  [_player loadStreamWithURL:URL];
}

// Loads a video stream with the provided URL and requests ads via the IMA SDK with the provided
// ad tag.
- (void)loadStreamWithURL:(NSURL *)URL imaTag:(NSString *)tag {
  [_player loadStreamWithURL:URL];
  if (_adService && [_adService class] == [GMFIMASDKAdService class]) {
    [(GMFIMASDKAdService *)_adService reset];
  } else {
    _adService = [[GMFIMASDKAdService alloc] initWithGMFVideoPlayer:self];
  }
  [(GMFIMASDKAdService*)_adService requestAdsWithRequest:tag];
}

- (void)play {
  [_player play];
}

- (void)pause {
  [_player pause];
}

- (void)setAboveRenderingView:(UIView *)view {
  [_playerView setAboveRenderingView:view];
  [view addGestureRecognizer:[[UITapGestureRecognizer alloc]
                              initWithTarget:self
                              action:@selector(didTapGestureCapturingView:)]];
}

- (void)addActionButtonWithImage:(UIImage *)image
                            name:(NSString *)name
                          target:(id)target
                        selector:(SEL)selector{
  
  // If the overlay view exists, create the action button.
  if (self.playerOverlayView && [self.playerOverlayView respondsToSelector:@selector(addActionButtonWithImage:name:target:selector:)]) {
    [self.playerOverlayView addActionButtonWithImage:image
                                                name:name
                                              target:target
                                            selector:selector];
  } else {
    // If the overlay view does not exist, create a dictionary of the arguments.
    // Add this dictionary to the list of dictionaries we have so far.
    // This way, when the overlay view is created, we can iterate through the dictionaries
    // and construct the action buttons.
    NSDictionary *actionButtonRequest = @{
      kActionButtonImageKey : image,
      kActionButtonNameKey : name,
      kActionButtonTargetKey : target,
      kActionButtonSelectorKey : [NSValue valueWithPointer:selector]
    };
    [_actionButtonDictionaries addObject:actionButtonRequest];
  }
}

- (void)registerAdService:(GMFAdService *)adService {
  _adService = adService;
}

// Allows outside classes take over or act as proxies for the video player controls.
- (void)setVideoPlayerOverlayDelegate:(id<GMFPlayerOverlayViewControllerDelegate>)delegate {
  [_videoPlayerOverlayViewController setDelegate:delegate];
}

- (void)setDefaultVideoPlayerOverlayDelegate {
  // Duration was probably changed by whatever delegate took over, so reset it here.
  [_videoPlayerOverlayViewController setTotalTime:[_player totalMediaTime]];
  [_videoPlayerOverlayViewController setMediaTime:[_player currentMediaTime]];
  [_videoPlayerOverlayViewController setDelegate:self];
}

- (void)setVideoPlayerOverlayViewController:(UIViewController <GMFPlayerOverlayViewControllerProtocol> *)videoPlayerOverlayViewController {
    [self.videoPlayerOverlayViewController removeFromParentViewController];
    _videoPlayerOverlayViewController = videoPlayerOverlayViewController;
    [self addChildViewController:self.videoPlayerOverlayViewController];
    if (self.playerView){
        [self.playerView setOverlayView:[videoPlayerOverlayViewController playerOverlayView]];
    }
}

- (void)loadView {
  _playerView = [[GMFPlayerView alloc] init];
  [self setView:_playerView];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  // Listen to tap events that fall through the overlay views
  _tapRecognizer = [[UITapGestureRecognizer alloc]
      initWithTarget:self
              action:@selector(didTapGestureCapturingView:)];
  [_tapRecognizer setDelegate:self];
  [_playerView.gestureCapturingView addGestureRecognizer:_tapRecognizer];

  if (!_videoPlayerOverlayViewController){
      _videoPlayerOverlayViewController = [[GMFPlayerOverlayViewController alloc] init];
      [self addChildViewController:self.videoPlayerOverlayViewController];
  }
  
  [_playerView setOverlayView:[_videoPlayerOverlayViewController playerOverlayView]];
  if (_controlTintColor && [self.playerOverlayView respondsToSelector:@selector(applyControlTintColor:)]) {
    [self.playerOverlayView applyControlTintColor:_controlTintColor];
  }
  
  // If we have received requests to create action buttons, iterate through each request (encoded
  // as a dictionary) and create the action buttons.
    if ([self.playerOverlayView respondsToSelector:@selector(addActionButtonWithImage:name:target:selector:)]){
        if ([_actionButtonDictionaries count] > 0) {
            for (NSDictionary *dict in _actionButtonDictionaries) {
                UIImage *image = [dict objectForKey:kActionButtonImageKey];
                NSString *name = [dict objectForKey:kActionButtonNameKey];
                id target = [dict objectForKey:kActionButtonTargetKey];
                SEL selector = [((NSValue *)[dict objectForKey:kActionButtonSelectorKey]) pointerValue];
                [self.playerOverlayView addActionButtonWithImage:image
                                                            name:name
                                                          target:target
                                                        selector:selector];
            }
        }
    }
  [self setDefaultVideoPlayerOverlayDelegate];
}

- (void)didTapGestureCapturingView:(UITapGestureRecognizer *)recognizer {
  [_videoPlayerOverlayViewController togglePlayerControlsVisibility];
}
- (void)restartPlayback {
  [_player replay];
}

- (GMFVideoPlayer *)videoPlayer {
  return _player;
}

- (UIView<GMFPlayerControlsProtocol> *)playerOverlayView {
  return [_videoPlayerOverlayViewController playerOverlayView];
}

- (GMFPlayerState)playbackState {
  return _player.state;
}

- (NSTimeInterval)currentMediaTime {
  return _player.currentMediaTime;
}

- (NSTimeInterval)totalMediaTime {
    return _player.totalMediaTime;
}

- (void) setControlTintColor:(UIColor *)controlTintColor {
  _controlTintColor = controlTintColor;
  if (self.playerOverlayView && [self.playerOverlayView respondsToSelector:@selector(applyControlTintColor:)]) {
    [self.playerOverlayView applyControlTintColor:controlTintColor];
  }
}

- (void) setVideoTitle:(NSString *)videoTitle {
  _videoTitle = videoTitle;
  if (self.playerOverlayView && [self.playerOverlayView respondsToSelector:@selector(setVideoTitle:)]) {
    [self.playerOverlayView setVideoTitle:videoTitle];
  }
}

- (void) setLogoImage:(UIImage *)logoImage {
  _logoImage = logoImage;
  if (self.playerOverlayView && [self.playerOverlayView respondsToSelector:@selector(setLogoImage:)]) {
    [self.playerOverlayView setLogoImage:logoImage];
  }
}

#pragma mark Player State Change Handlers

- (void)playerStateDidChangeToReadyToPlay {
  [_playerView setVideoRenderingView:[_player renderingView]];
}

- (void)playerStateDidChangeToPlaying {
  // NSLog(@"State changed to playing");
}

- (void)playerStateDidChangeToPaused {
  // NSLog(@"State changed to paused");
}

// Broadcast just before the player ends to allow any ads or other provider that wants to perform
// an action before playback ends.
- (void)playerStateWillChangeToFinished {
  NSDictionary *userInfo = @{
                             kGMFPlayerPlaybackWillFinishReasonUserInfoKey:
                               [NSNumber numberWithInt:GMFPlayerFinishReasonPlaybackEnded]
                             };
  [[NSNotificationCenter defaultCenter]
      postNotificationName:kGMFPlayerStateWillChangeToFinishedNotification
                    object:self
                  userInfo:userInfo];
}

- (void)playerStateDidChangeToFinished {
  NSDictionary *userInfo = @{
                             kGMFPlayerPlaybackDidFinishReasonUserInfoKey:
                               [NSNumber numberWithInt:GMFPlayerFinishReasonPlaybackEnded]
                             };
  [[NSNotificationCenter defaultCenter]
      postNotificationName:kGMFPlayerStateDidChangeToFinishedNotification
                    object:self
                  userInfo:userInfo];
}

#pragma mark GMFVideoPlayer protocol handlers

- (void)videoPlayer:(GMFVideoPlayer *)videoPlayer
    stateDidChangeFrom:(GMFPlayerState)fromState
                    to:(GMFPlayerState)toState {
  [_videoPlayerOverlayViewController playerStateDidChangeToState:toState];
  switch (toState) {
    case kGMFPlayerStateReadyToPlay:
      [self playerStateDidChangeToReadyToPlay];
      break;
    case kGMFPlayerStatePlaying:
      [self playerStateDidChangeToPlaying];
      break;
    case kGMFPlayerStatePaused:
      [self playerStateDidChangeToPaused];
      break;
    case kGMFPlayerStateFinished:
      // Allow any ads provider to play any post rolls before we actually finish
      [self playerStateWillChangeToFinished];
      [self playerStateDidChangeToFinished];
      break;
    case kGMFPlayerStateBuffering:
      // Video is buffering
      break;
    case kGMFPlayerStateSeeking:
      // Seeking
      break;
    case kGMFPlayerStateLoadingContent:
      // Loading content
      break;
    case kGMFPlayerStateEmpty:
      // Player was reset
      break;
    case kGMFPlayerStateError:
      // TODO(tensafefrogs): Do something with error state.
      break;
  }
  [[NSNotificationCenter defaultCenter]
      postNotificationName:kGMFPlayerPlaybackStateDidChangeNotification
                    object:self];
}

- (void)videoPlayer:(GMFVideoPlayer *)videoPlayer
    currentMediaTimeDidChangeToTime:(NSTimeInterval)time {
  [_videoPlayerOverlayViewController setMediaTime:time];
  [self notifyCurrentMediaTimeDidChange];
}

- (void)videoPlayer:(GMFVideoPlayer *)videoPlayer
    currentTotalTimeDidChangeToTime:(NSTimeInterval)time {
  if([_videoPlayerOverlayViewController.delegate isEqual:self]) {
    [_videoPlayerOverlayViewController setTotalTime:time];
    [self notifyCurrenTotalTimeDidChange];
  }
}

- (void)videoPlayer:(GMFVideoPlayer *)videoPlayer
  bufferedMediaTimeDidChangeToTime:(NSTimeInterval)time {
}

#pragma mark YTPlayerOverlayViewDelegate

- (void)didPressPlay {
  [_player play];
}

- (void)didPressPause {
  [_player pause];
}

- (void)didSeekToTime:(NSTimeInterval)seekTime {
  [_player seekToTime:seekTime];
  if (_wasPlayingBeforeSeeking) {
    [_player play];
  }
}

- (void)didStartScrubbing {
  // We don't want to override this flag if we're in the middle of another
  // seek.
  if ([_player state] != kGMFPlayerStateSeeking) {
    GMFPlayerState playerState = [_player state];
    _wasPlayingBeforeSeeking = playerState == kGMFPlayerStatePlaying ||
        playerState == kGMFPlayerStateBuffering;
  }
  _isUserScrubbing = YES;
  [_videoPlayerOverlayViewController setUserScrubbing:_isUserScrubbing];
  [_player pause];
}

- (void)didEndScrubbing {
  _isUserScrubbing = NO;
  [_videoPlayerOverlayViewController setUserScrubbing:_isUserScrubbing];
}

- (void)didPressReplay {
  if ([_player state] == kGMFPlayerStateFinished) {
    [_player replay];
  }
}

- (void)didPressMinimize {
  // Notify first to give observers a chance to remove themselves.
  [self notifyUserWillMinimize];
  [self notifyUserDidMinimize];
  [self resetPlayerAndPlayerView];
}

- (void)notifyUserWillMinimize {
  NSDictionary *userInfo = @{
                             kGMFPlayerPlaybackWillFinishReasonUserInfoKey:
                               [NSNumber numberWithInt:GMFPlayerFinishReasonUserExited]
                             };
  [[NSNotificationCenter defaultCenter]
      postNotificationName:kGMFPlayerStateWillChangeToFinishedNotification
                    object:self
                  userInfo:userInfo];
}

// Notifies a listener that the user minimized the video player by tapping the minimize button.
- (void)notifyUserDidMinimize {
  NSDictionary *userInfo = @{
                             kGMFPlayerPlaybackDidFinishReasonUserInfoKey:
                               [NSNumber numberWithInt:GMFPlayerFinishReasonUserExited]
                             };
  [[NSNotificationCenter defaultCenter]
      postNotificationName:kGMFPlayerStateDidChangeToFinishedNotification
                    object:self
                  userInfo:userInfo];
}

// Notifies a listener that the curent media time has changed. The listener is expected to check
// GMFVideoPlayerViewController.currentMediaTime to get the new value. Only dispatches a
// notification when the value changes, not on a set time interval.
// TODO(tensafefrogs): Include the new value in the userInfo dictionary with this notification.
- (void)notifyCurrentMediaTimeDidChange {
  [[NSNotificationCenter defaultCenter]
      postNotificationName:kGMFPlayerCurrentMediaTimeDidChangeNotification
                    object:self
                  userInfo:nil];
}

- (void)notifyCurrenTotalTimeDidChange {
  [[NSNotificationCenter defaultCenter]
      postNotificationName:kGMFPlayerCurrentTotalTimeDidChangeNotification
                    object:self
                  userInfo:nil];
}

#pragma mark -

// Reset these together, else playerView might retain a reference to the player's renderingView.
- (void)resetPlayerAndPlayerView {
  [_videoPlayerOverlayViewController reset];
  [_playerView reset];
  [_player reset];
}

// View was removed, clear player and notify observers.
- (void)dealloc {
  // Call this first to give things a chance to remove observers.
  [self notifyUserDidMinimize];
  [self resetPlayerAndPlayerView];

  [_tapRecognizer setDelegate:nil];
  [_tapRecognizer removeTarget:self action:@selector(didTapGestureCapturingView:)];
}

@end
