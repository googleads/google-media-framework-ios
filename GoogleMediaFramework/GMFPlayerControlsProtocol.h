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
#import "GMFPlayerControlsView.h"

@protocol GMFPlayerControlsProtocol<NSObject>

@property(nonatomic, weak) id<GMFPlayerControlsViewDelegate> delegate;

// These are all mutually exclusive. E.g. calling showPlayButton hides all the
// other views and shows the play button. Only one can be shown at a time.

- (void)showPlayButton;
- (void)showPauseButton;
- (void)showReplayButton;

- (void)enableSeekbarInteraction;
- (void)disableSeekbarInteraction;
- (void)setSeekbarTrackColor:(UIColor *)color;

- (void)setTotalTime:(NSTimeInterval)totalTime;
- (void)setMediaTime:(NSTimeInterval)mediaTime;


@optional

- (void)addActionButtonWithImage:(UIImage *)image
                            name:(NSString *)name
                          target:(id)target
                        selector:(SEL)selector;
- (void)applyControlTintColor:(UIColor *)color;
- (void)setVideoTitle:(NSString *)videoTitle;
- (void)setLogoImage:(UIImage *)logoImage;

@end
