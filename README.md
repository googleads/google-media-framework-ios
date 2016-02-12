#Google Media Framework for iOS

[![Build Status](https://travis-ci.org/googleads/google-media-framework-ios.png?branch=master)](https://travis-ci.org/googleads/google-media-framework-ios)

##Introduction
The Google Media Framework (GMF) is a lightweight media player designed to make video playback and integration with the Google IMA SDK on iOS easier.

![Google Media Framework iOS Demo](http://googleads.github.io/google-media-framework-ios/gmf_ios_portrait.png)

##Features
- A simple video player UI for video playback on iOS.
- Easily integrate the Google IMA SDK to enable advertising on your video content.

##Getting started
The easiest way to get started is by using [CocoaPods](http://cocoapods.org).

Create a new single view xcode project, then add the following line to your ```Podfile```:
```
pod "GoogleMediaFramework", "~> 1.0"
```
Then run
```
$ pod install
```
Then close your project in xcode and open the new xcworkspace that Cococapods just created:
```
$ open YourProjectName.xcworkspace
```
Find your new project's ```ViewController.m``` and add the following line at the top:
```
#import <GoogleMediaFramework/GoogleMediaFramework.h>
```
Then, add a ```viewDidAppear``` method:
```
- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];

  // An example url for the video content.
  NSString *videoURL = @"http://devimages.apple.com/samplecode/adDemo/ad.m3u8";

  // Init the video player view controller.
  GMFPlayerViewController *videoPlayerViewController = [[GMFPlayerViewController alloc] init];

  // Tell the player to play our content url.
  [videoPlayerViewController loadStreamWithURL:[NSURL URLWithString:videoURL]];

  // Tell the video player to start playing.
  [videoPlayerViewController play];

  [self presentViewController:videoPlayerViewController animated:YES completion:nil];
}
```
Now run your new app, and you should see the video player appear and start playing. (=Note: The close button will not work, as your application needs to know what to do when it is clicked. For a more in-depth example, see the demo app included with the framework.

The demo application shows a more advanced implementation using a UINavigationController to select from different video content and ad tags.

To try the demo app included with the Google Media Framework, clone the Google Media Framework Github repository, generate the xcworkspace file via ```pod install``` and open it.
```
$ git clone https://github.com/googleads/google-media-framework-ios.git GoogleMediaFramework
$ cd GoogleMediaFramework/GoogleMediaFrameworkDemo
$ pod install
$ open GoogleMediaFrameworkDemo.xcworkspace
```

You can now build the demo project and select a video to play.

The demo app includes the [Google Interactive Media Ads (IMA) SDK](https://developers.google.com/interactive-media-ads/docs/sdks/ios/v3/), which allows you to monetize your video content using [Doubleclick for Publishers](https://www.google.com/doubleclick/publishers/welcome/).

If you don't want to use CocoaPods, you should be able to integrate the framework by cloning the project and manually adding the classes and image resources to your project.

##Where do I report issues?
Please report issues on the [issues page](../../issues).

##Support
If you have questions about the framework, you can ask them at http://groups.google.com/d/forum/google-media-framework

##How do I contribute?
See [CONTRIBUTING.md](./CONTRIBUTING.md) for details.

##Requirements
  - iOS 6.1+
