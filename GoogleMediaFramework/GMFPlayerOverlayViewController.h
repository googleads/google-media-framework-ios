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

@interface GMFPlayerOverlayViewController : UIViewController {
 @private
  GMFPlayerOverlayView *_playerOverlayView;
  __weak NSObject<GMFPlayerControlsViewDelegate> *_delegate;
  GMFPlayerState _playerState;
  BOOL _autoHideEnabled;
  BOOL _playerControlsHidden;
}

@property(nonatomic, weak) id<GMFPlayerOverlayViewControllerDelegate>
    videoPlayerOverlayViewControllerDelegate;

- (void)setDelegate:(NSObject<GMFPlayerControlsViewDelegate> *)delegate;

- (void)playerStateDidChangeToState:(GMFPlayerState)toState;

- (void)showPlayerControlsAnimated:(BOOL)animated;
- (void)hidePlayerControlsAnimated:(BOOL)animated;

- (void)playerControlsDidHide;
- (void)playerControlsWillHide;
- (void)playerControlsDidShow;
- (void)playerControlsWillShow;

- (void)setTotalTime:(NSTimeInterval)totalTime;
- (void)setMediaTime:(NSTimeInterval)mediaTime;

- (GMFPlayerOverlayView *)playerOverlayView;

- (GMFPlayerControlsView *)playerControlsView;

- (void)togglePlayerControlsVisibility;

- (void)reset;

@end
