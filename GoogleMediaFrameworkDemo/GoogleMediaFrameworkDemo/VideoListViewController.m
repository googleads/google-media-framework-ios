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

#import <GoogleMediaFramework/GoogleMediaFramework.h>

@interface VideoListViewController ()

@end

@implementation VideoListViewController

- (void)loadView {
  self.title = @"Example Videos";

  self.tableView = [[UITableView alloc] initWithFrame:CGRectZero];
  self.tableView.dataSource = self;
  self.tableView.delegate = self;

  [self populateVideosArray];

  self.view = self.tableView;
}

#pragma mark GMFVideoPlayer notifications

- (void)playbackDidFinish:(NSNotification *)notification {
  int exitReason =
      [[[notification userInfo]
          objectForKey:kGMFPlayerPlaybackDidFinishReasonUserInfoKey] intValue];
  switch (exitReason) {
    case GMFPlayerFinishReasonPlaybackEnded:
      // Playback finished, you may wish to show an end screen here or return to the video selection
      // screen.
      break;
    case GMFPlayerFinishReasonUserExited:
      // User clicked minimize, go back to the prev screen and remove observers
      [self removeVideoPlayerObservers];
      [self.navigationController popViewControllerAnimated:YES];
      break;
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
  cell.detailTextLabel.text = video.description;
  return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [_videos count];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  VideoData *video = [_videos objectAtIndex:indexPath.row];

  // Init the video player view controller.
  GMFPlayerViewController *videoPlayerViewController = [[GMFPlayerViewController alloc] init];

  // Listen for playback finished event. See GMFPlayerFinishReason.
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(playbackDidFinish:)
                                               name:kGMFPlayerStateDidChangeToFinishedNotification
                                             object:videoPlayerViewController];
  // Set the content URL in the player.
  [videoPlayerViewController loadStreamWithURL:[NSURL URLWithString:video.videoURL]];

  // If there's an ad associated with the player, initialize the AdService using the video player
  // and request the ads.
  if (video.adTagURL != nil) {
    _adService = [[GMFIMASDKAdService alloc] initWithGMFVideoPlayer:videoPlayerViewController];

    [videoPlayerViewController registerAdService:_adService];

    [_adService requestAdsWithRequest:video.adTagURL];
  }

  // Show the video player.
  [self.navigationController pushViewController:videoPlayerViewController animated:YES];
  
  // (Optional): Customize the UI by giving the buttons and seekbar a blue tint.
  //  videoPlayerViewController.controlTintColor = [UIColor blueColor];
  
  // Tell the video player to start playing.
  [videoPlayerViewController play];

  [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark Videos Data array

// Populates the videos array with our sample content..
- (void)populateVideosArray {
  if ([_videos count] == 0) {
    _videos = @[
      [[VideoData alloc] initWithVideoURL:@"https://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"
                                    title:@"Video with no ads"
                              description:@""
                                 adTagURL:nil],
      [[VideoData alloc] initWithVideoURL:@"https://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"
                                    title:@"Skippable preroll"
                              description:@""
                                 adTagURL:@"http://pubads.g.doubleclick.net/gampad/ads?sz=400x300&iu=%2F6062%2Fgmf_demo&ciu_szs&impl=s&gdfp_req=1&env=vp&output=xml_vast2&unviewed_position_start=1&url=[referrer_url]&correlator=[timestamp]&cust_params=gmf_format%3Dskip"],
      [[VideoData alloc] initWithVideoURL:@"https://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"
                                    title:@"Unskippable preroll"
                              description:@""
                                 adTagURL:@"http://pubads.g.doubleclick.net/gampad/ads?sz=400x300&iu=%2F6062%2Fgmf_demo&ciu_szs&impl=s&gdfp_req=1&env=vp&output=xml_vast2&unviewed_position_start=1&url=[referrer_url]&correlator=[timestamp]&cust_params=gmf_format%3Dstd"],
      [[VideoData alloc] initWithVideoURL:@"https://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"
                                    title:@"Adrules (Preroll and ad breaks at 5s, 10s, 15s)"
                              description:@""
                                 adTagURL:@"http://pubads.g.doubleclick.net/gampad/ads?sz=400x300&iu=%2F6062%2Fgmf_demo&ciu_szs&impl=s&gdfp_req=1&env=vp&output=xml_vast2&unviewed_position_start=1&url=[referrer_url]&correlator=[timestamp]&ad_rule=1&cmsid=11924&vid=cWCkSYdFlU0&cust_params=gmf_format%3Dstd%2Cskip"],
    ];
  }
}

- (void)dealloc {
  [self removeVideoPlayerObservers];
}

@end
