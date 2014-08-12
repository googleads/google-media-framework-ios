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
#import "GMFPlayerState.h"
#import "GMFPlayerOverlayView.h"

@protocol GMFPlayerOverlayViewControllerDelegate<GMFPlayerControlsViewDelegate>
@optional
- (void)playerControlsWillShow;
- (void)playerControlsDidShow;
- (void)playerControlsWillHide;
- (void)playerControlsDidHide;
@end


@protocol GMFPlayerOverlayViewControllerProtocol <NSObject>

@property (nonatomic, weak) id<GMFPlayerOverlayViewControllerDelegate> delegate;
@property (nonatomic, strong) UIView<GMFPlayerControlsProtocol> *playerOverlayView;
// Set this to YES when the user is scrubbing. This will cause the spinner to be shown regardless
// of state.
@property (nonatomic) BOOL userScrubbing;

- (void) showPlayerControlsAnimated:(BOOL) animated;
- (void) hidePlayerControlsAnimated:(BOOL) animated;
- (void) setTotalTime:(NSTimeInterval) totalTime;
- (void) setMediaTime:(NSTimeInterval) mediaTime;
- (void) togglePlayerControlsVisibility;
- (void) playerStateDidChangeToState:(GMFPlayerState) toState;
- (void) reset;

@end

@interface GMFPlayerOverlayViewController : UIViewController <GMFPlayerOverlayViewControllerProtocol> {
 @private
  GMFPlayerOverlayView *_playerOverlayView;
  GMFPlayerState _playerState;
  BOOL _autoHideEnabled;
  BOOL _playerControlsHidden;
}

@property (nonatomic, weak) id<GMFPlayerOverlayViewControllerDelegate> delegate;
@property (nonatomic, strong) UIView<GMFPlayerControlsProtocol> *playerOverlayView;
@property (nonatomic) BOOL userScrubbing;
@property(nonatomic, weak) id<GMFPlayerOverlayViewControllerDelegate>
    videoPlayerOverlayViewControllerDelegate;
@property (nonatomic) BOOL isAdDisplayed;

- (void)playerStateDidChangeToState:(GMFPlayerState)toState;

- (void)playerControlsDidHide;
- (void)playerControlsWillHide;
- (void)playerControlsDidShow;
- (void)playerControlsWillShow;

- (GMFPlayerControlsView *)playerControlsView;

- (void)resetAutoHideTimer;

@end
