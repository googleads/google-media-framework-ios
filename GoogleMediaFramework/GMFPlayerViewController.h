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

#import "GMFPlayerView.h"
#import "GMFVideoPlayer.h"
#import "GMFPlayerOverlayViewController.h"

@class GMFAdService;
@class GMFPlayerControlsViewDelegate;

extern NSString * const kGMFPlayerCurrentMediaTimeDidChangeNotification;
extern NSString * const kGMFPlayerCurrentTotalTimeDidChangeNotification;
extern NSString * const kGMFPlayerDidMinimizeNotification;
extern NSString * const kGMFPlayerPlaybackStateDidChangeNotification;
extern NSString * const kGMFPlayerStateDidChangeToFinishedNotification;
extern NSString * const kGMFPlayerStateWillChangeToFinishedNotification;

extern NSString * const kGMFPlayerPlaybackDidFinishReasonUserInfoKey;
extern NSString * const kGMFPlayerPlaybackWillFinishReasonUserInfoKey;

@interface GMFPlayerViewController : UIViewController<GMFVideoPlayerDelegate,
                                                      GMFPlayerOverlayViewControllerDelegate,
                                                      GMFPlayerControlsViewDelegate,
                                                      UIGestureRecognizerDelegate> {
 @private
  UITapGestureRecognizer *_tapRecognizer;
}

@property(nonatomic, readonly) GMFPlayerView *playerView;

@property(nonatomic, weak) GMFAdService *adService;

@property(nonatomic, readonly, getter=isVideoFinished) BOOL videoFinished;

@property(nonatomic, strong) UIColor *controlColorScheme;

- (id)init;

- (void)loadStreamWithURL:(NSURL *)URL;

- (void)play;

- (void)pause;

- (GMFPlayerState)playbackState;

- (NSTimeInterval)currentMediaTime;


#pragma mark Advanced controls

- (void)registerAdService:(GMFAdService *)adService;

- (void)setABoveRenderingView:(UIView *)view;

- (void)setControlsVisibility:(BOOL)visible animated:(BOOL)animated;

- (void)setVideoPlayerOverlayDelegate:(id<GMFPlayerControlsViewDelegate>)delegate;

- (void)setDefaultVideoPlayerOverlayDelegate;

- (GMFPlayerOverlayView *)playerOverlayView;

@end

