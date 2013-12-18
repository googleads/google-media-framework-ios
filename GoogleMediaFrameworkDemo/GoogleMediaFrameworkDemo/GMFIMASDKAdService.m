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
  IMAAdsRequest *adsRequest =
      [[IMAAdsRequest alloc] initWithAdTagUrl:request
                               companionSlots:nil
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
  int finishReason = [[[notification userInfo]
      objectForKey:kGMFPlayerPlaybackWillFinishReasonUserInfoKey] intValue];
  if (finishReason == GMFPlayerFinishReasonPlaybackEnded) {
    // Playback reached the end of the video, notify AdsManager in case there are postrolls.
    [self.adsLoader contentComplete];
  }
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

  self.adsManager.adView.frame = _adView.bounds;
  self.adsManager.delegate = self;

  // Set the adView to just above the player rendering view, but below the controls.
  [self.videoPlayerController setABoveRenderingView:self.adsManager.adView];

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
      // break ommitted on purpose
    case kIMAAdEvent_RESUME:
      // When an ad starts, take over control of the video player until the ad completes
      [self.videoPlayerController.playerOverlayView showPauseButton];
      break;
    case kIMAAdEvent_PAUSE:
      [self.videoPlayerController.playerOverlayView showPlayButton];
      break;
    case kIMAAdEvent_ALL_ADS_COMPLETED:
      // When all ads are done, give control back to the video player.
      [self relinquishControlToVideoPlayer];
      NSLog(@"destroying ads manager");
      [self.adsManager destroy];
      // TODO: destroy loader (pending IMA SDK bug)
      //[self.adsLoader destroy];
      break;
    default:
      break;
  }
}

// Process ad playing errors.
- (void)adsManager:(IMAAdsManager *)adsManager didReceiveAdError:(IMAAdError *)error {
  // There was an error while playing the ad.
  NSLog(@"Error during ad playback: %@", error);
  [self relinquishControlToVideoPlayer];
  [self.videoPlayerController play];
}

- (void)adDidProgressToTime:(NSTimeInterval)mediaTime totalTime:(NSTimeInterval)totalTime {
  [self.videoPlayerController.playerOverlayView setMediaTime:mediaTime];
}

- (void)takeControlOfVideoPlayer {
  _hasVideoPlayerControl = YES;
  [self.videoPlayerController pause];
  [self.videoPlayerController setVideoPlayerOverlayDelegate:self];
}

- (void)relinquishControlToVideoPlayer {
  [self.videoPlayerController.playerOverlayView enableSeekbarInteraction];
  [self.videoPlayerController setDefaultVideoPlayerOverlayDelegate];
  [self.videoPlayerController.playerOverlayView setSeekbarTrackColorDefault];
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

