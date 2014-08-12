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

#import "GMFPlayerView.h"

// Contains and manages the layout of the various subviews of the video player.
@implementation GMFPlayerView

- (id)init {
  self = [super initWithFrame:CGRectZero];
  if (self) {
    [self createAndAddGestureCapturingView];
    [self setBackgroundColor:[UIColor blackColor]];
    //[self setUserInteractionEnabled:YES];
  }
  return self;
}

- (id)initWithFrame:(CGRect)frame {
  NSAssert(false, @"initWithFrame not available, use init.");
  return nil;
}

- (void)layoutSubviews {
  [super layoutSubviews];
  CGRect bounds = [self bounds];
  [_gestureCapturingView setFrame:bounds];
  [_renderingView setFrame:bounds];
  [_aboveRenderingView setFrame:bounds];
  [_overlayView setFrame:bounds];
}

- (void)createAndAddGestureCapturingView {
  _gestureCapturingView = [[UIView alloc] init];
  [self insertSubview:_gestureCapturingView atIndex:0];
}

- (void)setVideoRenderingView:(UIView *)renderingView {
  [_renderingView removeFromSuperview];
  _renderingView = renderingView;
  if (_renderingView) {
    // Let taps fall through to |_aboveRenderingView| or |_gestureCapturingView|.
    [_renderingView setUserInteractionEnabled:NO];
    [self insertSubview:_renderingView aboveSubview:_gestureCapturingView];
  }
  [self setNeedsLayout];
}

- (void)setOverlayView:(UIView<GMFPlayerControlsProtocol> *)overlayView {
  [_overlayView removeFromSuperview];
  _overlayView = overlayView;
  if (_overlayView) {
    // The _overlayView should always be the top view.
    [self addSubview:_overlayView];
  }
}

- (void)setAboveRenderingView:(UIView *)aboveRenderingView {
  [_aboveRenderingView removeFromSuperview];
  _aboveRenderingView = aboveRenderingView;
  if (_aboveRenderingView) {
    [self insertSubview:_aboveRenderingView belowSubview:_overlayView];
  }
}

- (void)reset {
  [self setVideoRenderingView:nil];
}

@end

