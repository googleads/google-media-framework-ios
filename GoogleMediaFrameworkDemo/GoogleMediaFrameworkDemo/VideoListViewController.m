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
      [[[notification userInfo] objectForKey:kGMFPlayerPlaybackDidFinishReasonUserInfoKey] intValue];
  switch (exitReason) {
    case GMFPlayerFinishReasonPlaybackEnded:
      NSLog(@"Playback ended, content complete.");
      break;
    case GMFPlayerFinishReasonUserExited:
      NSLog(@"User minimized player");
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
  // Tell the video player to start playing.
  [videoPlayerViewController play];

  [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark Videos Data array

// Populates the videos array with our sample content..
- (void)populateVideosArray {
  if ([_videos count] == 0) {
    _videos = @[
               [[VideoData alloc] initWithVideoURL:@"http://rmcdn.2mdn.net/Demo/html5/output.mp4"
                                            title:@"MP4 Video"
                                      description:@"No ads"
                                         adTagURL:nil],
               [[VideoData alloc] initWithVideoURL:@"http://rmcdn.2mdn.net/Demo/html5/output.mp4"
                                            title:@"MP4 Video"
                                      description:@"With Preroll"
                                         adTagURL:@"http://pubads.g.doubleclick.net/gampad/ads?sz=400x300&iu=%2F6062%2Fiab_vast_samples&ciu_szs=300x250%2C728x90&gdfp_req=1&env=vp&output=xml_vast2&unviewed_position_start=1&url=[referrer_url]&correlator=[timestamp]&cust_params=iab_vast_samples%3Dlinear"],
               [[VideoData alloc] initWithVideoURL:@"http://rmcdn.2mdn.net/Demo/html5/output.mp4"
                                            title:@"MP4 Video"
                                      description:@"2x Preroll pod w/ bumper, 2x midroll, 2x postroll w/ bumpers."
                                         adTagURL:@"http://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=%2F15018773%2Feverything2&ciu_szs=300x250%2C468x60%2C728x90&impl=s&gdfp_req=1&env=vp&output=xml_vast2&unviewed_position_start=1&url=[referrer_url]&correlator=[timestamp]&cmsid=133&vid=10XWSh7W4so&ad_rule=1"],
               [[VideoData alloc] initWithVideoURL:@"http://rmcdn.2mdn.net/Demo/html5/output.mp4"
                                            title:@"MP4 Video"
                                      description:@"2x midroll pod, 2 ads each @ 11s and 20s"
                                         adTagURL:@"http://pubads.g.doubleclick.net/gampad/ads?sz=400x300&iu=%2F15018773%2Fcue_point&ciu_szs=728x90&impl=s&gdfp_req=1&env=vp&output=xml_vast2&unviewed_position_start=1&url=[referrer_url]&correlator=[timestamp]&cmsid=493&vid=932730933&ad_rule=1"],
               [[VideoData alloc] initWithVideoURL:@"http://rmcdn.2mdn.net/Demo/html5/output.mp4"
                                            title:@"MP4 Video"
                                      description:@"Skippable preroll"
                                         adTagURL:@"http://pubads.g.doubleclick.net/gampad/ads?sz=400x300&iu=%2F6753%2FSDKregression%2Flinear_hosted_video_with_img_comps&ciu_szs=300x250%2C728x90&impl=s&gdfp_req=1&env=vp&output=xml_vast2&unviewed_position_start=1&url=example.com&correlator=12345"],
               [[VideoData alloc] initWithVideoURL:@"http://devimages.apple.com/samplecode/adDemo/ad.m3u8"
                                            title:@"m3u8 Streaming Video"
                                      description:@"No ads"
                                         adTagURL:nil],
               [[VideoData alloc] initWithVideoURL:@"http://devimages.apple.com/samplecode/adDemo/ad.m3u8"
                                            title:@"m3u8 Streaming Video"
                                      description:@"With Preroll"
                                         adTagURL:@"http://pubads.g.doubleclick.net/gampad/ads?sz=400x300&iu=%2F6062%2Fiab_vast_samples&ciu_szs=300x250%2C728x90&gdfp_req=1&env=vp&output=xml_vast2&unviewed_position_start=1&url=[referrer_url]&correlator=[timestamp]&cust_params=iab_vast_samples%3Dlinear"],
               [[VideoData alloc] initWithVideoURL:@"http://devimages.apple.com/samplecode/adDemo/ad.m3u8"
                                             title:@"m3u8 Streaming Video"
                                       description:@"Pre-roll, pre-roll bumper, mid-roll pods (pods of 4, every 30 seconds), post-roll bumper, and post roll"
                                          adTagURL:@"http://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=%2F3510761%2FadRulesSampleTags&ciu_szs=160x600%2C300x250%2C728x90&cust_params=adrule%3Dpremidpostpodandbumpers&impl=s&gdfp_req=1&env=vp&ad_rule=1&vid=47570401&cmsid=481&output=xml_vast2&unviewed_position_start=1&url=[referrer_url]&correlator=[timestamp]"]
               ];
  }
}


- (void)dealloc {
  [self removeVideoPlayerObservers];
}

@end

