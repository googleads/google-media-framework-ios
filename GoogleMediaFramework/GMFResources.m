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

#import "GMFResources.h"
#import "GMFVideoPlayer.h"

@implementation GMFResources

+ (UIImage *)playerBarPlayButtonImage {
  return [self imageNamed:@"player_control_play@2x"];
}

+ (UIImage *)playerBarPlayLargeButtonImage {
  return [self imageNamed:@"player_control_play_large@2x"];
}

+ (UIImage *)playerBarPauseButtonImage {
  return [self imageNamed:@"player_control_pause@2x"];
}

+ (UIImage *)playerBarPauseLargeButtonImage {
  return [self imageNamed:@"player_control_pause_large@2x"];
}

+ (UIImage *)playerBarReplayButtonImage {
  return [self imageNamed:@"player_control_replay@2x"];
}

+ (UIImage *)playerBarReplayLargeButtonImage {
  return [self imageNamed:@"player_control_replay_large@2x"];
}

+ (UIImage *)playerBarMaximizeButtonImage {
  return [self imageNamed:@"player_control_maximize@2x"];
}

+ (UIImage *)playerBarMinimizeButtonImage {
  return [self imageNamed:@"player_control_minimize@2x"];
}

+ (UIImage *)playerBarScrubberThumbImage {
  return [self imageNamed:@"player_scrubber_thumb@2x"];
}

+ (UIImage *)playerBarBackgroundImage {
  return [self imageNamed:@"player_controls_background@2x"];
}

+ (UIImage *)playerTitleBarBackgroundImage {
  return [self imageNamed:@"player_controls_title_bar_background@2x"];
}

#pragma mark Private Methods

+ (UIImage *)imageNamed:(NSString *)name
            stretchable:(BOOL)stretchable {
  NSBundle *frameworkBundle = [NSBundle bundleForClass:[self class]];
  NSString *resourcePath = [frameworkBundle pathForResource:name ofType:@"png"];
  UIImage *image = [UIImage imageWithContentsOfFile:resourcePath];

  NSAssert(image, @"There is no image called %@", name);
  if (stretchable) {
    // Stretching the image by using a center cap.
    CGSize size = [image size];
    return [image stretchableImageWithLeftCapWidth:size.width / 2.0
                                      topCapHeight:size.height / 2.0];
  } else {
    return image;
  }
}

+ (UIImage *)imageNamed:(NSString *)name {
  return [self imageNamed:name stretchable:NO];
}

@end

