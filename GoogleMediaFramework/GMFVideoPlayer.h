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

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

#import "GMFPlayerState.h"

@class GMFVideoPlayer;

@protocol GMFVideoPlayerDelegate<NSObject>

- (void)videoPlayer:(GMFVideoPlayer *)videoPlayer
    stateDidChangeFrom:(GMFPlayerState)fromState
                    to:(GMFPlayerState)toState;

// Called whenever media time changes during playback.
- (void)videoPlayer:(GMFVideoPlayer *)videoPlayer
    currentMediaTimeDidChangeToTime:(NSTimeInterval)time;

// Called when the media duration changes during playback
- (void)videoPlayer:(GMFVideoPlayer *)videoPlayer
    currentTotalTimeDidChangeToTime:(NSTimeInterval)time;

@optional
// Called whenever buffered media time changes during playback or while loading or paused.
- (void)videoPlayer:(GMFVideoPlayer *)videoPlayer
    bufferedMediaTimeDidChangeToTime:(NSTimeInterval)time;

@end

// Handles video playback via AVPlayer classes and AVPlayerItem management. Provides a simple API
// to control playback of media content.
@interface GMFVideoPlayer : NSObject

@property(nonatomic, weak) id<GMFVideoPlayerDelegate> delegate;

@property(nonatomic, readonly) GMFPlayerState state;

// |renderingView| will only be set after the player enters the ready to play state. After calling
// |reset|, the player discards any previously set rendering view, so if
// you maintain a separate reference to this rendering view, it will no longer be valid for the
// current playback.
@property(nonatomic, readonly) UIView *renderingView;

// Public method to play media via url.
- (void)loadStreamWithURL:(NSURL* )url;

// Reset the playback state to enable playing a new video in an existing player instance.
- (void)reset;

// Handling playback.
- (void)play;
- (void)pause;
- (void)replay;
- (void)seekToTime:(NSTimeInterval)time;

// Querying the player.
- (NSTimeInterval)currentMediaTime;
- (NSTimeInterval)totalMediaTime;
- (NSTimeInterval)bufferedMediaTime;

@end


