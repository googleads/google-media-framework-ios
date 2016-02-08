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

#import "VideoData.h"
#import "VideoListViewController.h"

#define kAnimationDuration 0.2f

@interface VideoListViewController ()

@end

@implementation VideoListViewController

- (void)loadView {
  self.title = @"Example Videos";
  
  // Determine the size of the screen.
  CGRect screenBounds = [[UIScreen mainScreen] bounds];
  
  // Create a container view which will hold the table view and the video player.
  UIView *containerView = [[UIView alloc] initWithFrame:screenBounds];
  
  // Create the table view.
  self.tableView = [[UITableView alloc] initWithFrame:containerView.bounds];
  self.tableView.dataSource = self;
  self.tableView.delegate = self;
  
  // Put the elements into the table view.
  [self populateVideosArray];

  // Add the table view to the container.
  [containerView addSubview:self.tableView];
  
  // Display the container view which currently contains the table view.
  self.view = containerView;
}

// Display the video player on the screen.
- (void) showVideoPlayer {
  self.isVideoPlayerDisplayed = YES;
  
  // Add the video player's view controller as a child of this view controller.
  [self addChildViewController:self.videoPlayerViewController];
  [self.videoPlayerViewController didMoveToParentViewController:self];
  
  // Add the video player to the view.
  [self.view addSubview:self.videoPlayerViewController.view];
  
  // Resize the table video and video player.
  [self resizeTableViewAndVideoPlayer];
}

// Remove the video player from the screen.
- (void) hideVideoPlayer {
  self.isVideoPlayerDisplayed = NO;
  
  // Remove the video player.
  [self.videoPlayerViewController.view removeFromSuperview];
  
  // Remove the video player's view controller.
  [self.videoPlayerViewController removeFromParentViewController];
  
  // Resize the table view and view player.
  [self resizeTableViewAndVideoPlayer];
}

// Adjust the sizes of the video player and table view based on
// the device orientation and whether a video is playing.
- (void) resizeTableViewAndVideoPlayer {
  
  // Determine whether the status bar is shown or hidden.
  if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
    [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
  } else {
    // iOS 6
    [[UIApplication sharedApplication] setStatusBarHidden:YES
                                            withAnimation:UIStatusBarAnimationSlide];
  }
  
  
  // Since the status bar is at the top, we need to offset the vertical position of our views.
  // The status bar is a long, thin rectangle.
  // When the device is in portrait mode, the length of the thin  side of the status bar is
  // statusBarFrame.height.
  //
  // When the device is in landscape mdoe, the length of the thin side of the status bar is
  // statusBarFrame.width.
  //
  // In either case, the length of the thin side will be the smaller of statusBarFrame.height
  // and statusBarFrame.height.
  CGSize statusBarFrame = [[UIApplication sharedApplication] statusBarFrame].size;
  float statusBarOffset = MIN(statusBarFrame.height, statusBarFrame.width);
  
  // Get the dimensions of the view which contains the table view and video player.
  CGFloat containerWidth = self.view.bounds.size.width;
  CGFloat containerHeight = self.view.bounds.size.height - statusBarOffset;

  if (self.isVideoPlayerDisplayed) {
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
      // If the video player is showing and we are in landscape mode, make the table view hidden
      // and make the video player occupy the full screen.
      [UIView animateWithDuration:kAnimationDuration animations:^{
          self.tableView.frame = CGRectMake(0, containerHeight, 0, 0);
          self.videoPlayerViewController.view.frame = CGRectMake(0,
                                                                 statusBarOffset,
                                                                 containerWidth,
                                                                 containerHeight);
      }];
    } else {
      // If the video player is showing and we are in portrait mode,
      // make the video player occupy the top half of the screen
      // and make the table view occupy the bottom half of the screen.
      [UIView animateWithDuration:kAnimationDuration animations:^{
          self.tableView.frame = CGRectMake(0,
                                            containerHeight/2,
                                            containerWidth,
                                            containerHeight/2 + statusBarOffset);
          self.videoPlayerViewController.view.frame = CGRectMake(0,
                                                                 statusBarOffset,
                                                                 containerWidth,
                                                                 containerHeight/2);
      }];
    }
  } else {
    // If there is no video player, make the table view occupy the full screen.
    [UIView animateWithDuration:kAnimationDuration animations:^{
        self.tableView.frame = self.view.bounds;
    }];
  }
  
  // Redraw the view.
  [self.view setNeedsDisplay];
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
  [self resizeTableViewAndVideoPlayer];
}

// If the video is playing and we are in landscape mode, hide the status bar.
- (BOOL) prefersStatusBarHidden {
  return (UIInterfaceOrientationIsLandscape(self.interfaceOrientation) &&
          self.isVideoPlayerDisplayed);
}

// If the video player is playing and status bar is displayed, the color of the status bar should
// be light.
- (UIStatusBarStyle)preferredStatusBarStyle{
  return self.isVideoPlayerDisplayed ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault;
}

#pragma mark GMFVideoPlayer notifications

- (void)playbackDidFinish:(NSNotification *)notification {
  int exitReason =
      [[[notification userInfo]
          objectForKey:kGMFPlayerPlaybackDidFinishReasonUserInfoKey] intValue];
  if (exitReason == GMFPlayerFinishReasonPlaybackEnded ||
      exitReason == GMFPlayerFinishReasonUserExited) {
    [self removeVideoPlayerObservers];
    [self hideVideoPlayer];
  }
}

- (void)removeVideoPlayerObservers {
  [[NSNotificationCenter defaultCenter]
      removeObserver:self
                name:kGMFPlayerStateDidChangeToFinishedNotification
              object:nil];
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *const kVideoCellReuseIndetifier = @"videoCell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kVideoCellReuseIndetifier];
  if (!cell) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                  reuseIdentifier:kVideoCellReuseIndetifier];
  }

  VideoData *video = [_videos objectAtIndex:indexPath.row];
  // TODO(tensafefrogs): Add thumbnails to the sample videos.
  // cell.imageView.image = video.thumbnail;
  cell.textLabel.text = video.title;
  cell.detailTextLabel.text = video.summary;
  return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [_videos count];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  VideoData *video = [_videos objectAtIndex:indexPath.row];

  // If a video player already exists, remove it.
  if (self.videoPlayerViewController) {
    [self.videoPlayerViewController didPressMinimize];
  }
  
  self.videoPlayerViewController = [[GMFPlayerViewController alloc] init];

  // Listen for playback finished event. See GMFPlayerFinishReason.
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(playbackDidFinish:)
                                               name:kGMFPlayerStateDidChangeToFinishedNotification
                                             object:self.videoPlayerViewController];

  // If there's an ad associated with the player, initialize the AdService using the video player
  // and request the ads.
  if (video.adTagURL != nil) {
    // Set the content URL and ad tag in the player.
    [self.videoPlayerViewController loadStreamWithURL:[NSURL URLWithString:video.videoURL]
                                               imaTag:video.adTagURL];
  } else {
    // Set the content URL in the player.
    [self.videoPlayerViewController loadStreamWithURL:[NSURL URLWithString:video.videoURL]];
  }

  // Show the video player.
  [self showVideoPlayer];
  
  // (Optional): Customize the UI by giving the buttons and seekbar a blue tint.
  //  self.videoPlayerViewController.controlTintColor = [UIColor blueColor];
  
  // (Optional): Create a set of action buttons which will be displayed in the right of the top bar.
  [self.videoPlayerViewController addActionButtonWithImage:[UIImage imageNamed:@"Favorite-Icon"]
                                                      name:@"Button"
                                                    target:self
                                                  selector:@selector(clickedFavoriteButton)];
  [self.videoPlayerViewController addActionButtonWithImage:[UIImage imageNamed:@"Delete-Icon"]
                                                      name:@"Button"
                                                    target:self
                                                  selector:@selector(clickedDeleteButton)];
  [self.videoPlayerViewController addActionButtonWithImage:[UIImage imageNamed:@"Share-Icon"]
                                                      name:@"Button"
                                                    target:self
                                                  selector:@selector(clickedShareButton)];

  self.videoPlayerViewController.videoTitle = video.title;
  self.videoPlayerViewController.logoImage = [UIImage imageNamed:@"Gmf-Icon"];
  // Tell the video player to start playing.
  [self.videoPlayerViewController play];

  [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void) clickedShareButton {
  [self.videoPlayerViewController pause];
  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Share button clicked"
                                                  message:@"You clicked the share button."
                                                 delegate:nil
                                        cancelButtonTitle:@"OK"
                                        otherButtonTitles:nil];
  [alert show];
}

- (void) clickedFavoriteButton {
  [self.videoPlayerViewController pause];
  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Favorite button clicked"
                                                  message:@"You clicked the favorite button."
                                                 delegate:nil
                                        cancelButtonTitle:@"OK"
                                        otherButtonTitles:nil];
  [alert show];
}

- (void) clickedDeleteButton {
  [self.videoPlayerViewController pause];
  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Delete button clicked"
                                                  message:@"You clicked the delete button."
                                                 delegate:nil
                                        cancelButtonTitle:@"OK"
                                        otherButtonTitles:nil];
  [alert show];
}

#pragma mark Videos Data array

// Populates the videos array with our sample content..
- (void)populateVideosArray {
  NSString *contentURL = @"https://s0.2mdn.net/instream/videoplayer/media/android.mp4";
  if ([_videos count] == 0) {
    _videos = @[
      [[VideoData alloc] initWithVideoURL:contentURL
                                    title:@"Video with no ads"
                                  summary:@""
                                 adTagURL:nil],
      [[VideoData alloc] initWithVideoURL:contentURL
                                    title:@"Skippable preroll"
                                  summary:@""
                                 adTagURL:@"http://pubads.g.doubleclick.net/gampad/ads?sz=640x360&iu=/6062/iab_vast_samples/skippable&"
       @"ciu_szs=300x250,728x90&impl=s&gdfp_req=1&env=vp&output=xml_vast2&unviewed_position_start=1&"
       @"url=[referrer_url]&correlator=[timestamp]"],
      [[VideoData alloc] initWithVideoURL:contentURL
                                    title:@"Unskippable preroll"
                                  summary:@""
                                 adTagURL:@"http://pubads.g.doubleclick.net/gampad/ads?sz=400x300&"
       @"iu=%2F6062%2Fhanna_MA_group%2Fvideo_comp_app&ciu_szs=&impl=s&gdfp_req=1&env=vp&"
       @"output=xml_vast2&unviewed_position_start=1&m_ast=vast&url=[referrer_url]&"
       @"correlator=[timestamp]"],
      [[VideoData alloc] initWithVideoURL:contentURL
                                    title:@"Adrules (Preroll and ad breaks at 5s, 10s, 15s)"
                                  summary:@""
                                 adTagURL:@"http://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=%2F15018773%2Feverything2&"
       @"ciu_szs=300x250%2C468x60%2C728x90&impl=s&gdfp_req=1&env=vp&output=xml_vmap1&"
       @"unviewed_position_start=1url=[referrer_url]&correlator=[timestamp]&cmsid=133&"
       @"vid=10XWSh7W4so&ad_rule=1"],
    ];
  }
}

- (void)dealloc {
  [self removeVideoPlayerObservers];
}

@end
