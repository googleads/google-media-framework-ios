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

#import "GMFAdService.h"

@implementation GMFAdService

- (id)init {
  NSAssert(false, @"init not available, use initWithGMFVideoPlayer.");
  return nil;
}

// Designated initializer
- (id)initWithGMFVideoPlayer:(GMFPlayerViewController *)videoPlayerController {
  self = [super init];
  if (self) {
    _videoPlayerController = videoPlayerController;

    // Listen for playback finished event. See GMFPlayerFinishReason.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playbackWillFinish:)
                                                 name:kGMFPlayerStateWillChangeToFinishedNotification
                                               object:_videoPlayerController];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playbackDidFinish:)
                                                 name:kGMFPlayerStateDidChangeToFinishedNotification
                                               object:_videoPlayerController];
  }
  return self;
}

- (void)playbackWillFinish:(NSNotification *)notification {
  // Override this in your AdService class to play any postrolls or post-content events.
}

- (void)playbackDidFinish:(NSNotification *)notification {
  // After playbackWillFinish
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter]
      removeObserver:self
                name:kGMFPlayerStateWillChangeToFinishedNotification
              object:nil];
  [[NSNotificationCenter defaultCenter]
      removeObserver:self
                name:kGMFPlayerStateDidChangeToFinishedNotification
              object:nil];
}

@end
