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

#import <UIKit/UIKit.h>
#import "GMFPlayerControlsProtocol.h"
#import "GMFPlayerControlsView.h"
#import "GMFTopBarView.h"

@interface GMFPlayerOverlayView : UIView<GMFPlayerControlsProtocol> {
 @private
  GMFPlayerControlsView *_playerControlsView;
}

// The play/pause/replay button can display either a play, pause, or replay icon.
// We represent the current image being displayed by using this enum.
typedef enum CurrentPlayPauseReplayIcon {
  PLAY,
  PAUSE,
  REPLAY
} CurrentPlayPauseReplayIcon;

@property(nonatomic, readonly) GMFPlayerControlsView *playerControlsView;
@property(nonatomic, readonly) GMFTopBarView *topBarView;
@property(nonatomic, strong) UIColor *playPauseResetButtonBackgroundColor;
@property(nonatomic, weak) id<GMFPlayerControlsViewDelegate> delegate;


// Show/hide the loading spinner
- (void)showSpinner;
- (void)hideSpinner;

- (void)setPlayerBarVisible:(BOOL)visible;

- (void)setSeekbarTrackColor:(UIColor *)color;
- (void)setSeekbarTrackColorDefault;

- (void)addActionButtonWithImage:(UIImage *)image
                            name:(NSString *)name
                          target:(id)target
                        selector:(SEL)selector;

- (void)applyControlTintColor:(UIColor *)color;
- (void)setVideoTitle:(NSString *)videoTitle;
- (void)setLogoImage:(UIImage *)logoImage;

- (void)disableTopBar;
- (void)enableTopBar;

@end

