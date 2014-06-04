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

#import "GMFVideoPlayer.h"

static const NSTimeInterval kGMFPollingInterval = 0.2;

static void *kGMFPlayerItemStatusContext = &kGMFPlayerItemStatusContext;
static void *kGMFPlayerRateContext = &kGMFPlayerRateContext;
static void *kGMFPlayerDurationContext = &kGMFPlayerDurationContext;


static NSString * const kStatusKey = @"status";
static NSString * const kRateKey = @"rate";
static NSString * const kDurationKey = @"currentItem.duration";

// Pause the video if user unplugs their headphones.
void GMFAudioRouteChangeListenerCallback(void *inClientData,
                                         AudioSessionPropertyID inID,
                                         UInt32 inDataSize,
                                         const void *inData) {
  NSDictionary *routeChangeDictionary = (__bridge NSDictionary *)inData;
  NSString *reasonKey =
      [NSString stringWithCString:kAudioSession_AudioRouteChangeKey_Reason
                         encoding:NSASCIIStringEncoding];
  UInt32 reasonCode = 0;
  [[routeChangeDictionary objectForKey:reasonKey] getValue:&reasonCode];
  if (reasonCode == kAudioSessionRouteChangeReason_OldDeviceUnavailable) {
    // If the user removed the headphones, pause the playback.
    GMFVideoPlayer *_player = (__bridge GMFVideoPlayer *)inClientData;
    [_player pause];
  }
}

#pragma mark -
#pragma mark GMFPlayerLayerView

// GMFPlayerLayerView is a UIView that uses an AVPlayerLayer instead of CGLayer.
@interface GMFPlayerLayerView : UIView

// Returns an instance of GMFPlayerLayerView for rendering the video content in.
- (AVPlayerLayer *)playerLayer;

@end

@implementation GMFPlayerLayerView

+ (Class)layerClass {
  return [AVPlayerLayer class];
}

- (AVPlayerLayer *)playerLayer {
  return (AVPlayerLayer *)[self layer];
}

@end

#pragma mark GMFVideoPlayer

@interface GMFVideoPlayer () {
  GMFPlayerLayerView *_renderingView;
}

@property (nonatomic, strong) AVPlayerItem *playerItem;

@property (nonatomic, strong) AVPlayer *player;

// Polling timer for content time updates.
@property (nonatomic, strong) NSTimer *playbackStatusPoller;

// Track content time updates so we know when playback stalls or is paused/playing.
@property (nonatomic, assign) NSTimeInterval lastReportedPlaybackTime;

@property (nonatomic, assign) NSTimeInterval lastReportedBufferTime;

// Allow |[_player play]| to be called before content finishes loading.
@property (nonatomic, assign) BOOL pendingPlay;

// Set when pause is invoked and cleared when player enters the playing state.
// This is used to determine, when resuming from an audio interruption such as
// a phone call, whether the player should be resumed or it should stay in a
// pause state.
@property (nonatomic, assign) BOOL manuallyPaused;

// Creates an AVPlayerItem and AVPlayer instance when preparing to play a new content URL.
- (void)handlePlayableAsset:(AVAsset *)asset;

// Updates the current |playerItem| and |player| and removes and re-adds observers.
- (void)setAndObservePlayerItem:(AVPlayerItem *)playerItem player:(AVPlayer *)player;

// Updates the internal player state and notifies the delegate.
- (void)setState:(GMFPlayerState)state;

// Starts a polling timer to track content playback state and time.
- (void)startPlaybackStatusPoller;

// Resets the above polling timer.
- (void)stopPlaybackStatusPoller;

// Handles audio session changes, such as when a user unplugs headphones.
- (void)onAudioSessionInterruption:(NSNotification *)notification;

// Handler for |playerItem| state changes.
- (void)playerItemStatusDidChange;

// Reset the player state. Readies the player to play a new content URL.
- (void)clearPlayer;

// Resets the player to its default state.
- (void)reset;

@end

@implementation GMFVideoPlayer

// AVPlayerLayer class for video rendering.
@synthesize renderingView = _renderingView;

- (instancetype)init {
  self = [super init];
  if (self) {
    _state = kGMFPlayerStateEmpty;
    AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange,
                                    GMFAudioRouteChangeListenerCallback,
                                    (__bridge void *)self);

    // Handles interruptions to playback, like phone calls and activating Siri.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onAudioSessionInterruption:)
                                                 name:AVAudioSessionInterruptionNotification
                                               object:[AVAudioSession sharedInstance]];
  }
  return self;
}

#pragma mark Public playback methods

- (void)play {
  _manuallyPaused = NO;
  if (_state == kGMFPlayerStateLoadingContent || _state == kGMFPlayerStateSeeking) {
    _pendingPlay = YES;
  } else if (![_player rate]) {
    _pendingPlay = YES;
    [_player play];
  }
}

- (void)pause {
  _pendingPlay = NO;
  _manuallyPaused = YES;
  if (_state == kGMFPlayerStatePlaying ||
      _state == kGMFPlayerStateBuffering ||
      _state == kGMFPlayerStateSeeking) {
    [_player pause];
    // Setting paused state here rather than KVO observing, since the |rate|
    // value can change to 0 because of buffer issues too.
    [self setState:kGMFPlayerStatePaused];
  }
}

- (void)replay {
  _pendingPlay = YES;
  [self seekToTime:0.0];
}

- (void)seekToTime:(NSTimeInterval)time {
  if ([_playerItem status] != AVPlayerItemStatusReadyToPlay) {
    // Calling [AVPlayerItem seekToTime:] before it is in the "ready to play" state
    // causes a crash.
    // TODO(tensafefrogs): Dev assert here instead of silent return.
    return;
  }
  if (![self isLive]) {
    time = MIN(MAX(time, 0), [self totalMediaTime]);
  } else {
    time = MAX(time, 0);
  }
  [self setState:kGMFPlayerStateSeeking];
  __weak GMFVideoPlayer *weakSelf = self;
  [_playerItem seekToTime:CMTimeMake(time, 1)
        completionHandler:^(BOOL finished) {
            GMFVideoPlayer *strongSelf = weakSelf;
            if (!strongSelf) {
              return;
            }
            if (finished) {
              if ([strongSelf pendingPlay]) {
                [strongSelf setPendingPlay:NO];
                [[strongSelf player] play];
              } else {
                [strongSelf setState:kGMFPlayerStatePaused];
              }
            }
        }];
}

- (void)loadStreamWithURL:(NSURL *)URL {
  [self setState:kGMFPlayerStateLoadingContent];
  AVAsset *asset = [AVAsset assetWithURL:URL];
  [self handlePlayableAsset:asset];
}

#pragma mark Querying Player for info

- (NSTimeInterval)currentMediaTime {
  return [self isPlayableState] ?
      [GMFVideoPlayer secondsWithCMTime:[_playerItem currentTime]] : 0.0;
}

- (NSTimeInterval)totalMediaTime {
  // |_playerItem| duration is 0 if the video is a live stream.
  return [self isPlayableState] ? [GMFVideoPlayer secondsWithCMTime:[_playerItem duration]] : 0.0;
}

- (NSTimeInterval)bufferedMediaTime {
  if ([self isPlayableState]) {
    // Call |loadedTimeRanges| before storing |currentTime| so that the
    // loaded time ranges don't change before we get |currentTime|.
    // This can happen while video is playing.
    NSArray *timeRanges = [_playerItem loadedTimeRanges];
    CMTime currentTime = [_playerItem currentTime];
    for (NSValue *timeRange in timeRanges) {
      CMTimeRange range;
      [timeRange getValue:&range];
      if (CMTimeRangeContainsTime(range, currentTime)) {
        return [GMFVideoPlayer secondsWithCMTime:CMTimeRangeGetEnd(range)];
      }
    }
  }
  return 0;
}

- (BOOL)isLive {
  // |totalMediaTime| is 0 if the video is a live stream.
  // TODO(tensafefrogs): Is there a better way to determine if the video is live?
  return [self totalMediaTime] == 0.0;
}

#pragma mark Private methods

// Once an asset is playable (i.e. tracks are loaded) hand it off to this method to add observers.
- (void)handlePlayableAsset:(AVAsset *)asset {
  AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
  // Recreating the AVPlayer instance because of issues when playing HLS then non-HLS back to
  // back, and vice-versa.
  AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
  [self setAndObservePlayerItem:playerItem player:player];
}

- (void)setAndObservePlayerItem:(AVPlayerItem *)playerItem player:(AVPlayer *)player {
  // Player item observers.
  [_playerItem removeObserver:self forKeyPath:kStatusKey];
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:AVPlayerItemDidPlayToEndTimeNotification
                                                object:_playerItem];

  _playerItem = playerItem;
  if (_playerItem) {
    [_playerItem addObserver:self
                  forKeyPath:kStatusKey
                     options:0
                     context:kGMFPlayerItemStatusContext];

    __weak GMFVideoPlayer *weakSelf = self;
    [[NSNotificationCenter defaultCenter]
        addObserverForName:AVPlayerItemDidPlayToEndTimeNotification
                    object:_playerItem
                     queue:[NSOperationQueue mainQueue]
                usingBlock:^(NSNotification *note) {
                    GMFVideoPlayer *strongSelf = weakSelf;
                    if (!strongSelf) {
                      return;
                    }
                    [strongSelf playbackDidReachEnd];
                }];
  }

  // Player observers.
  [_player removeObserver:self forKeyPath:kRateKey];
  [_player removeObserver:self forKeyPath:kDurationKey];

  _player = player;
  if (_player) {
    [_player addObserver:self
              forKeyPath:kRateKey
                 options:0
                 context:kGMFPlayerRateContext];
    [_player addObserver:self
              forKeyPath:kDurationKey
                 options:0
                 context:kGMFPlayerDurationContext];
    _renderingView = [[GMFPlayerLayerView alloc] init];
    [[_renderingView playerLayer] setVideoGravity:AVLayerVideoGravityResizeAspect];
    [[_renderingView playerLayer] setBackgroundColor:[[UIColor blackColor] CGColor]];
    [[_renderingView playerLayer] setPlayer:_player];
  } else {
    // It is faster to discard the rendering view and create a new one when
    // necessary than to call setPlayer:nil and reuse it for future playbacks.
    _renderingView = nil;
  }
}

- (void)setState:(GMFPlayerState)state {
  if (state != _state) {
    GMFPlayerState prevState = _state;
    _state = state;

    // Call this last in case the delegate removes references/destroys self.
    [_delegate videoPlayer:self stateDidChangeFrom:prevState to:state];
  }
}

- (void)startPlaybackStatusPoller {
  if (_playbackStatusPoller) {
    return;
  }
  _playbackStatusPoller = [NSTimer
      scheduledTimerWithTimeInterval:kGMFPollingInterval
                              target:self
                            selector:@selector(updateStateAndReportMediaTimes)
                            userInfo:nil
                             repeats:YES];
  // Ensure timer fires during UI events such as scrolling.
  [[NSRunLoop currentRunLoop] addTimer:_playbackStatusPoller
                               forMode:NSRunLoopCommonModes];
}

- (void)stopPlaybackStatusPoller {
  _lastReportedBufferTime = 0;
  [_playbackStatusPoller invalidate];
  _playbackStatusPoller = nil;
}

#pragma mark AVAudioSession notifications

- (void)onAudioSessionInterruption:(NSNotification *)notification {
  NSDictionary *userInfo = [notification userInfo];
  AVAudioSessionInterruptionType type =
      [(NSNumber *)[userInfo valueForKey:AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
  NSUInteger flags =
      [(NSNumber *)[userInfo valueForKey:AVAudioSessionInterruptionOptionKey] unsignedIntegerValue];
  // It seems like we don't receive the InterruptionTypeBegan
  // event properly. This might be an iOS bug:
  // http://openradar.appspot.com/12412685
  //
  // So instead we try to detect if the player was manually paused by invoking
  // pause, and only resume if the player was not manually paused.
  if (type == AVAudioSessionInterruptionTypeEnded &&
      flags & AVAudioSessionInterruptionOptionShouldResume &&
      _state == kGMFPlayerStatePaused &&
      !_manuallyPaused) {
    [self play];
  }
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  AudioSessionRemovePropertyListenerWithUserData(kAudioSessionProperty_AudioRouteChange,
                                                 GMFAudioRouteChangeListenerCallback,
                                                 (__bridge void *)self);
  [self clearPlayer];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
  if (context == kGMFPlayerDurationContext) {
    // Update total duration of player
    NSTimeInterval currentTotalTime = [GMFVideoPlayer secondsWithCMTime:_playerItem.duration];
    [_delegate videoPlayer:self currentTotalTimeDidChangeToTime:currentTotalTime];
  } else if (context == kGMFPlayerItemStatusContext) {
    [self playerItemStatusDidChange];
  } else if (context == kGMFPlayerRateContext) {
    [self playerRateDidChange];
  } else {
    [super observeValueForKeyPath:keyPath
                         ofObject:object
                           change:change
                          context:context];
  }
}

- (void)playerItemStatusDidChange {
  if ([_playerItem status] == AVPlayerItemStatusReadyToPlay &&
      _state == kGMFPlayerStateLoadingContent) {
    // TODO(tensafefrogs): It seems like additional AVPlayerItemStatusReadyToPlay
    // events indicate HLS stream switching. Investigate.
    [self setState:kGMFPlayerStateReadyToPlay];
    if (_pendingPlay) {
      _pendingPlay = NO;
      // Let's buffer some more data and let the playback poller start playback.
      [self setState:kGMFPlayerStateBuffering];
      [self startPlaybackStatusPoller];
    } else {
      [self setState:kGMFPlayerStatePaused];
    }
  } else if ([_playerItem status] == AVPlayerItemStatusFailed) {
    // TODO(tensafefrogs): Better error handling: [self failWithError:[_playerItem error]];
  }
}

- (void)playerRateDidChange {
  // TODO(tensafefrogs): Abandon rate observing since it's inconsistent between HLS
  // and non-HLS videos. Rely on the poller.
  if ([_player rate]) {
    [self startPlaybackStatusPoller];
    [self setState:kGMFPlayerStatePlaying];
  }
}

- (void)playbackDidReachEnd {
  if ([_playerItem status] != AVPlayerItemStatusReadyToPlay) {
    // In some cases, |AVPlayerItemDidPlayToEndTimeNotification| is fired while
    // the player is being initialized. Ignore such notifications.
    return;
  }

  // Make sure we report the final media time if necessary before stopping the poller.
  [self updateStateAndReportMediaTimes];
  [self stopPlaybackStatusPoller];
  [self setState:kGMFPlayerStateFinished];
  // For HLS videos, the rate isn't set to 0 on video end, so we have to do it
  // explicitly.
  if ([_player rate]) {
    [_player setRate:0];
  }
}

- (BOOL)isPlayableState {
  // TODO(tensafefrogs): Drop this method and rely on the existence of |_player|.
  return _state == kGMFPlayerStatePlaying ||
      _state == kGMFPlayerStatePaused ||
      _state == kGMFPlayerStateReadyToPlay ||
      _state == kGMFPlayerStateBuffering ||
      _state == kGMFPlayerStateSeeking ||
      _state == kGMFPlayerStateFinished;
}

- (void)updateStateAndReportMediaTimes {
  NSTimeInterval bufferedMediaTime = [self bufferedMediaTime];
  if (_lastReportedBufferTime != bufferedMediaTime) {
    _lastReportedBufferTime = bufferedMediaTime;
    [_delegate videoPlayer:self bufferedMediaTimeDidChangeToTime:bufferedMediaTime];
  }

  if (_state != kGMFPlayerStatePlaying && _state != kGMFPlayerStateBuffering) {
    return;
  }

  NSTimeInterval currentMediaTime = [self currentMediaTime];
  // If the current media time is different from the last reported media time,
  // the player is playing.
  if (_lastReportedPlaybackTime != currentMediaTime) {
    _lastReportedPlaybackTime = currentMediaTime;
    if (_state == kGMFPlayerStatePlaying) {
      [_delegate videoPlayer:self currentMediaTimeDidChangeToTime:currentMediaTime];
    } else {
      // Player resumed playback from buffering state.
      [self setState:kGMFPlayerStatePlaying];
    }
  } else if (![_player rate]) {
    [_player play];
  }
}

#pragma mark Cleanup

- (void)clearPlayer {
  _pendingPlay = NO;
  _manuallyPaused = NO;
  [self stopPlaybackStatusPoller];
  [self setAndObservePlayerItem:nil player:nil];
  _lastReportedPlaybackTime = 0;
  _lastReportedBufferTime = 0;
}

- (void)reset {
  [self clearPlayer];
  [self setState:kGMFPlayerStateEmpty];
}

#pragma mark Utils and Misc.

+ (NSTimeInterval)secondsWithCMTime:(CMTime)t {
  return CMTIME_IS_NUMERIC(t) ? CMTimeGetSeconds(t) : 0;
}

@end


