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

#import "GMFIMASDKAdService.h"
#import "GMFContentPlayhead.h"

@class GMFPlayerOverlayView;

@interface GMFIMASDKAdService ()
@property (nonatomic, strong) UIColor *originalBackgroundTintColor;
@property (nonatomic, strong) UIColor *originalPlayPauseResetBackgroundColor;
@end

@implementation GMFIMASDKAdService {
  BOOL _hasVideoPlayerControl;
}

// Designated initializer
- (instancetype)initWithGMFVideoPlayer:(GMFPlayerViewController *)videoPlayerController {
  return [super initWithGMFVideoPlayer:videoPlayerController];
}

- (void)requestAdsWithRequest:(NSString *)request {
  [self createAdsLoader];
  
  // If there is no view above the rendering view, then there is no ads display container.
  // Thus, we create one and add it to the video player.
  if (self.videoPlayerController.playerView.aboveRenderingView == nil) {
    UIView *view = [[UIView alloc] initWithFrame:self.videoPlayerController.view.bounds];
    [self.videoPlayerController setABoveRenderingView:view];
    self.adDisplayContainer = [[IMAAdDisplayContainer alloc] initWithAdContainer:view
                                                                  companionSlots:nil];
  }
  
  IMAAdsRequest *adsRequest = [[IMAAdsRequest alloc] initWithAdTagUrl:request
                                                   adDisplayContainer:self.adDisplayContainer
                                                          userContext:nil];

  [_adsLoader requestAdsWithRequest:adsRequest];
}

- (IMASettings *)createIMASettings {
  IMASettings *settings = [[IMASettings alloc] init];
  settings.language = @"en";
  return settings;
}

- (void)createAdsLoader {
  self.adsLoader = [[IMAAdsLoader alloc] initWithSettings:[self createIMASettings]];
  self.adsLoader.delegate = self;
}

#pragma mark GMFVideoPlayerViewController notification handlers

// Listen to playbackWill finish in order to play postrolls if needed before the player ends.
// The GMFVideoPlayerSDK subscribes to this notification automatically.
- (void)playbackWillFinish:(NSNotification *)notification {
  [self.adsLoader contentComplete];
}

// Destroy adsManager when user exits the player
- (void)playbackDidFinish:(NSNotification *)notification {
  int finishReason = [[[notification userInfo]
      objectForKey:kGMFPlayerPlaybackDidFinishReasonUserInfoKey] intValue];
  if (finishReason == GMFPlayerFinishReasonUserExited) {
    [self.adsManager destroy];
    [self relinquishControlToVideoPlayer];
  }
}

#pragma mark IMAAdsLoaderDelegate

- (void)adsLoader:(IMAAdsLoader *)loader failedWithErrorData:(IMAAdLoadingErrorData *)adErrorData {
  // Loading failed, you probbaly want to log it when this happens.
  NSLog(@"Ad loading error: %@", adErrorData.adError.message);

  // Tell video content to play/resume.
  [self.videoPlayerController play];
}

// Ads are loaded, create the AdsManager and set up the ad frame for displaying ads
- (void)adsLoader:(IMAAdsLoader *)loader adsLoadedWithData:(IMAAdsLoadedData *)adsLoadedData {
  // Get the ads manager from ads loaded data.
  self.adsManager = adsLoadedData.adsManager;

  // GMFContentPlayhead handles listening for time updates from the video player and passing those
  // to the AdsManager.
  GMFContentPlayhead *contentPlayhead =
      [[GMFContentPlayhead alloc] initWithGMFPlayerViewController:self.videoPlayerController];

  [self.adsManager initializeWithContentPlayhead:contentPlayhead adsRenderingSettings:nil];

  self.adsManager.delegate = self;

  [self.adsManager start];
}

#pragma mark IMAAdsManagerDelegate

- (void)adsManagerDidRequestContentPause:(IMAAdsManager *)adsManager {
  // IMA SDK wants control of the player, so pause and take over delegate from video controls.
  [self takeControlOfVideoPlayer];
}

- (void)adsManagerDidRequestContentResume:(IMAAdsManager *)adsManager {
  // Resume or start (if not started yet) the content.
  [self.videoPlayerController setControlsVisibility:YES animated:YES];
  [self relinquishControlToVideoPlayer];
  [self.videoPlayerController play];
}

// Process ad events.
- (void)adsManager:(IMAAdsManager *)adsManager didReceiveAdEvent:(IMAAdEvent *)event {
  // Perform different actions based on the event type.
  NSLog(@"** Ad event **: %@", [self adEventAsString:event.type]);

  switch (event.type) {
    case kIMAAdEvent_LOADED:
      [self.videoPlayerController.playerOverlayView setTotalTime:event.ad.duration];
      [self.videoPlayerController.playerOverlayView setSeekbarTrackColor:[UIColor yellowColor]];
      break;
    case kIMAAdEvent_STARTED:
      [self.videoPlayerController.playerOverlayView disableSeekbarInteraction];
      // Break ommitted on purpose.
    case kIMAAdEvent_RESUME:
      // When an ad starts, take over control of the video player until the ad completes.
      [self.videoPlayerController.playerOverlayView showPauseButton];
      [self showPlayerControls];
      break;
    case kIMAAdEvent_PAUSE:
      [self.videoPlayerController.playerOverlayView showPlayButton];
      [self showPlayerControls];
      break;
    case kIMAAdEvent_ALL_ADS_COMPLETED:
      // When all ads are done, give control back to the video player.
      [self relinquishControlToVideoPlayer];
      [self.adsManager destroy];
      // TODO: destroy loader (pending IMA SDK bugfix)
      //[self.adsLoader destroy];
      break;
    default:
      break;
  }
}

- (void)showPlayerControls {
  GMFPlayerOverlayViewController *overlayVc =
      (GMFPlayerOverlayViewController *)self.videoPlayerController.videoPlayerOverlayViewController;
  [overlayVc showPlayerControlsAnimated:YES];
}

// Process ad playing errors.
- (void)adsManager:(IMAAdsManager *)adsManager didReceiveAdError:(IMAAdError *)error {
  // There was an error while playing the ad.
  [self relinquishControlToVideoPlayer];
  [self.videoPlayerController play];
}

- (void)adDidProgressToTime:(NSTimeInterval)mediaTime totalTime:(NSTimeInterval)totalTime {
  [self.videoPlayerController.playerOverlayView setMediaTime:mediaTime];
}

- (void)takeControlOfVideoPlayer {
  GMFPlayerViewController *playerVc = self.videoPlayerController;
  GMFPlayerOverlayView *overlayView = (GMFPlayerOverlayView *) playerVc.playerOverlayView;
  GMFPlayerOverlayViewController *overlayVc =
      (GMFPlayerOverlayViewController *)self.videoPlayerController.videoPlayerOverlayViewController;

  [overlayVc setIsAdDisplayed:YES];
  [overlayView hideSpinner];
  
  // Store the current background colors of the overlay view and the play/pause/reset button.
  self.originalBackgroundTintColor = [overlayView.tintedBackgroundColor copy];
  self.originalPlayPauseResetBackgroundColor = [overlayView.playPauseResetButtonBackgroundColor
                                                copy];
  
  // Make the background of the overlay view clear so that it does not obstruct the ad UI.
  [overlayView setTintedBackgroundColor:[UIColor clearColor]];
  
  // Hide the top bar of the video player.
  [overlayView disableTopBar];
  
  // Give the play/pause/reset button a slightly transparent black background so that the contrast
  // makes it easily visible.
  [overlayView setPlayPauseResetButtonBackgroundColor:[UIColor colorWithRed:0
                                                                      green:0
                                                                       blue:0
                                                                      alpha:0.5f]];
  
  _hasVideoPlayerControl = YES;
  [self.videoPlayerController pause];
  [self.videoPlayerController setVideoPlayerOverlayDelegate:self];
}

- (void)relinquishControlToVideoPlayer {
  GMFPlayerViewController *playerVc = self.videoPlayerController;
  GMFPlayerOverlayView *overlayView = (GMFPlayerOverlayView *) playerVc.playerOverlayView;
  GMFPlayerOverlayViewController *overlayVc =
      (GMFPlayerOverlayViewController *)self.videoPlayerController.videoPlayerOverlayViewController;
  
  [overlayVc setIsAdDisplayed:NO];
  [overlayView enableSeekbarInteraction];
  
  // Restore the background color of the overlay view and the play/pause/reset button to their
  // original values.
  [overlayView setTintedBackgroundColor:self.originalBackgroundTintColor];
  [overlayView setPlayPauseResetButtonBackgroundColor:self.originalPlayPauseResetBackgroundColor];
  
  [self.videoPlayerController setDefaultVideoPlayerOverlayDelegate];
  [overlayView setSeekbarTrackColorDefault];
  
  // Show the top bar again.
  [overlayView enableTopBar];
  
  _hasVideoPlayerControl = NO;
}

#pragma mark GMFPlayerOverlayViewDelegate

- (void)didPressPlay {
  [self.adsManager resume];
}

- (void)didPressPause {
  [self.adsManager pause];
}

- (void)didPressReplay {
  // Noop
}

- (void)didPressMinimize {
  [self.videoPlayerController didPressMinimize];
}

// Not implemented since ads seek bar is read only.
- (void)didSeekToTime:(NSTimeInterval)time {
  // Noop
}

- (void)didStartScrubbing {
  // Noop
}

- (void)didEndScrubbing {
  // Noop
}

#pragma mark Debug Methods

// Helper/debug method for displaying ad events in the application log.
- (NSString *)adEventAsString:(IMAAdEventType)adEventType {
  switch(adEventType) {
    case kIMAAdEvent_ALL_ADS_COMPLETED:
      // All ads managed by the ads manager have completed.
      return @"All Ads Completed";
    case kIMAAdEvent_CLICKED:
      // Ad clicked.
      return @"Ad Clicked";
    case kIMAAdEvent_COMPLETE:
      // Single ad has finished.
      return @"Complete";
    case kIMAAdEvent_FIRST_QUARTILE:
      // First quartile of a linear ad was reached.
      return @"First quartile reached";
    case kIMAAdEvent_LOADED:
      // An ad was loaded.
      return @"Loaded";
    case kIMAAdEvent_MIDPOINT:
      // Midpoint of a linear ad was reached.
      return @"Midpoint reached";
    case kIMAAdEvent_PAUSE:
      // Ad paused.
      return @"Ad Paused";
    case kIMAAdEvent_RESUME:
      // Ad resumed.
      return @"Ad Resumed";
    case kIMAAdEvent_THIRD_QUARTILE:
      // Third quartile of a linear ad was reached.
      return @"Third quartile reached";
    case kIMAAdEvent_STARTED:
      // Ad has started.
      return @"Ad Started";
    default:
      return @"Invalid Error type";
  }
}

@end

