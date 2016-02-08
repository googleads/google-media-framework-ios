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

#import <GoogleMediaFramework/GoogleMediaFramework.h>
#import <GoogleInteractiveMediaAds/GoogleInteractiveMediaAds.h>

@interface GMFIMASDKAdService : GMFAdService<IMAAdsLoaderDelegate,
                                             IMAAdsManagerDelegate,
                                             GMFPlayerOverlayViewControllerDelegate> {
 @private
  UIView* _adView;
}

@property(nonatomic, strong) IMAAdsLoader *adsLoader;

@property(nonatomic, strong) IMAAdsManager *adsManager;

@property(nonatomic, strong) IMAAdDisplayContainer *adDisplayContainer;

// Initiate a request to the ads server for ads associated with the given adtag.
- (void)requestAdsWithRequest:(NSString *)request;

- (void)reset;

#pragma mark GMFPlayerOverlayViewDelegate

- (void)didPressPlay;
- (void)didPressPause;
- (void)didPressReplay;
- (void)didPressMinimize;
- (void)didSeekToTime:(NSTimeInterval)time;
- (void)didStartScrubbing;
- (void)didEndScrubbing;

@end

