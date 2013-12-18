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

#import "GMFAppDelegate.h"
#import "VideoListViewController.h"

@implementation GMFAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

  // For the purposes of this sample app, we are using a NavigationController to display
  // a few video and ad options.
  VideoListViewController *viewController = [[VideoListViewController alloc] init];
  UINavigationController *navController =
      [[UINavigationController alloc] initWithRootViewController:viewController];
  // Hide the navbar so the video plays fullscreen.
  [navController setNavigationBarHidden:YES animated:NO];

  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  self.window.rootViewController = navController;
  [self.window makeKeyAndVisible];

  return YES;
}

@end

