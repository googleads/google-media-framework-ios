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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol GMFPlayerControlsViewDelegate <NSObject>

- (void)didPressPlay;
- (void)didPressPause;
- (void)didPressReplay;
- (void)didPressMinimize;

// User seeked to a given time relative to the start of the video.
- (void)didSeekToTime:(NSTimeInterval)time;
- (void)didStartScrubbing;
- (void)didEndScrubbing;

@end

@interface GMFPlayerControlsView : UIView

// Set the total duration of the video. May be NaN or Infinity if the
// total time is unknown. Call updateScrubberAndTime to make the change visible.
- (void)setTotalTime:(NSTimeInterval)totalTime;

// Set the amount of video downloaded. Call updateScrubberAndTime to make
// the change visible.
- (void)setDownloadedTime:(NSTimeInterval)downloadedTime;

// Set the current position of the scrubber within the total video duration.
// Call updateScrubberAndTime to make the change visible.
- (void)setMediaTime:(NSTimeInterval)mediaTime;

- (void)updateScrubberAndTime;

- (CGFloat)preferredHeight;

- (void)setDelegate:(id<GMFPlayerControlsViewDelegate>)delegate;

- (void)setSeekbarTrackColor:(UIColor *)color;

- (void)disableSeekbarInteraction;
- (void)enableSeekbarInteraction;

- (void)applyControlTintColor:(UIColor *)color;

@end

