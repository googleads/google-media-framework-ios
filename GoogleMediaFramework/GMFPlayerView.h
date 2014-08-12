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

#import "GMFPlayerOverlayView.h"

@interface GMFPlayerView : UIView {
 @private
  UIView<GMFPlayerControlsProtocol> *_overlayView;
}

@property(nonatomic, weak) UIView *aboveRenderingView;
@property(nonatomic, strong) UIView *renderingView;

// Handles capturing various gestures (taps, swipes, whatever else) and forwards the events to the
// overlayView. This allows 3rd party views set as the aboveRenderingView to capture tap events
// along side the player controls, and also handle taps on the video surface.
@property(nonatomic, readonly) UIView *gestureCapturingView;

- (id)init;

- (void)reset;

- (void)setVideoRenderingView:(UIView *)renderingView;

- (void)setAboveRenderingView:(UIView *)aboveRenderingView;

- (void)setOverlayView:(UIView<GMFPlayerControlsProtocol> *)overlayView;

@end

