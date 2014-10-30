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

#import "GoogleMediaFrameworkDemoTests.h"

NSString *CONTENT_URL = @"http://rmcdn.2mdn.net/Demo/html5/output.mp4";
int DEFAULT_TIMEOUT = 10;

@implementation GoogleMediaFrameworkDemoTests {
 @private
  GMFVideoPlayer *_player;
  NSMutableArray *_eventList;
}

- (void)setUp {
  [super setUp];
  _player = [[GMFVideoPlayer alloc] init];
  [_player setDelegate:self];
  _eventList = [NSMutableArray array];
}

- (void)tearDown {
  _player = nil;
  _eventList = nil;

  [super tearDown];
}

- (void)testPlay {
  [self loadContentURL];
  
  // Play stream
  [_player play];
  [self waitForState:kGMFPlayerStatePlaying];
  
  // Pause stream
  [_player pause];
  [self waitForState:kGMFPlayerStatePaused];
  [self assertPlaybackDoesNotProgress];
  
  // Seek
  [_player seekToTime:[_player totalMediaTime] - 1];
  [self waitForState:kGMFPlayerStateSeeking];
  [self waitForState:kGMFPlayerStatePaused];
  
  // Play after seeking
  [_player play];
  [self waitForState:kGMFPlayerStatePlaying];
  [self assertPlaybackDoesProgress];
  
  // Play until the end of the movie.
  [self waitForState:kGMFPlayerStateFinished];
  
  [self assertNoOtherStateChange];
}

- (void)testReplay {
  [self loadContentURL];
  
  // Seek to the end and wait for the end of the movie.
  [_player seekToTime:[_player totalMediaTime] - 1];
  [_player play];
  [self waitForState:kGMFPlayerStateSeeking];
  [self waitForState:kGMFPlayerStatePlaying];
  [self waitForState:kGMFPlayerStateFinished];
  
  // Replay and verify that the player starts from the beginning.
  [_player replay];
  [self waitForState:kGMFPlayerStateSeeking];
  [self waitForState:kGMFPlayerStatePlaying];
  XCTAssertTrue([_player currentMediaTime] < 0.25,
               @"Player media time should be near the beginning of the movie, but it is %f.",
               [_player currentMediaTime]);
  [self assertPlaybackDoesProgress];
  
  [self assertNoOtherStateChange];
  
}

- (void)testSeekingAndPlay {
  [self loadContentURL];
  
  [_player seekToTime:[_player totalMediaTime] / 2];
  [_player play];
  [self waitForState:kGMFPlayerStateSeeking];
  [self waitForState:kGMFPlayerStatePlaying];
  
  [self assertNoOtherStateChange];
}

- (void)testSeekingToImpossibleTimes {
  [self loadContentURL];
  NSTimeInterval totalMediaTime = [_player totalMediaTime];
  
  // Seek to the middle.
  [_player seekToTime:totalMediaTime / 2];
  [self waitForState:kGMFPlayerStateSeeking];
  [self waitForState:kGMFPlayerStatePaused];
  
  // Seek before the beginning.
  [_player seekToTime:-totalMediaTime];
  [self waitForState:kGMFPlayerStateSeeking];
  [self waitForState:kGMFPlayerStatePaused];
  XCTAssertTrue([_player currentMediaTime] == 0,
               @"Current media time should be 0 for seeks before the beginning.");
  
  // Seek after the end.
  [_player seekToTime:totalMediaTime * 2];
  [_player play];
  [self waitForState:kGMFPlayerStateSeeking];
  [self waitForState:kGMFPlayerStatePlaying];
  [self waitForState:kGMFPlayerStateFinished];
  
  [self assertNoOtherStateChange];
}

- (void)testPlayerSetStreamURLAgain {
  // State changes: [testPlay] -> Paused -> Empty -> Loading content ->
  // Ready to play -> Playing.
  [self loadContentURL];
  [self loadContentURL];
  [self assertNoOtherStateChange];
}

- (void)testResetContent {
  [self loadContentURL];
  [_player reset];
  [self waitForState:kGMFPlayerStateEmpty];
  [self assertNoOtherStateChange];
}

- (void)testPlayerIgnoresDoublePlaybackCommands {
  // State changes: [testPlay] -> Paused -> Play.
  [self loadContentURL];
  [_player play];
  [_player play];
  [self waitForState:kGMFPlayerStatePlaying];
  [_player pause];
  [_player pause];
  [self waitForState:kGMFPlayerStatePaused];
  [self assertNoOtherStateChange];
}

- (void)loadContentURL {
  [_player loadStreamWithURL:[NSURL URLWithString:CONTENT_URL]];
  [self waitForState:kGMFPlayerStateLoadingContent];
  [self waitForState:kGMFPlayerStateReadyToPlay];
  [self waitForState:kGMFPlayerStatePaused];
}

- (void)assertNoOtherStateChange {
  XCTAssertFalse(_eventList.count, @"Unexpected events %@", _eventList);
}

- (void) waitForState:(GMFPlayerState)state {
  [self waitForState:state withTimeout:DEFAULT_TIMEOUT];
}

- (void) waitForState:(GMFPlayerState)state withTimeout:(NSInteger)timeout {
  XCTAssertTrue(
    WaitFor(
      ^BOOL {
          return ([_eventList count] > 0 && _eventList[0] == [NSNumber numberWithInt:state]);
      },
      timeout),
    @"Failed while waiting for state %@, eventList is %@",
        [GoogleMediaFrameworkDemoTests stringWithState:state],
        _eventList);
  [self removeWaitingState:state];
}

- (void) removeWaitingState:(GMFPlayerState)state {
  [_eventList removeObject:[NSNumber numberWithInt:state]];
}

BOOL WaitFor(BOOL (^block)(void), NSTimeInterval seconds) {
  NSDate* start = [NSDate date];
  NSDate* end = [[NSDate date] dateByAddingTimeInterval:seconds];
  while (!block() && [GoogleMediaFrameworkDemoTests timeIntervalSince:start] < seconds) {
    [[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode
                             beforeDate: end];
  }
  return block();
}

+ (NSTimeInterval)timeIntervalSince:(NSDate*)date {
  return -[date timeIntervalSinceNow];
}

- (void)assertPlaybackDoesProgress {
  NSTimeInterval startMediaTime = [_player currentMediaTime];
  [self waitForTimeInterval:1];
  NSTimeInterval endMediaTime = [_player currentMediaTime];
  XCTAssertTrue(startMediaTime != endMediaTime,
               @"Playback progressed when it was not expected to");
}

- (void)assertPlaybackDoesNotProgress {
  NSTimeInterval startMediaTime = [_player currentMediaTime];
  [self waitForTimeInterval:1];
  NSTimeInterval endMediaTime = [_player currentMediaTime];
  XCTAssertTrue(startMediaTime == endMediaTime,
               @"Playback progressed when it was not expected to");
}

- (void)waitForTimeInterval:(NSTimeInterval)timeInterval {
  [[NSRunLoop currentRunLoop] runUntilDate:[NSDate
                                            dateWithTimeIntervalSinceNow:timeInterval]];
}

- (void) videoPlayer:(GMFVideoPlayer *)videoPlayer
  stateDidChangeFrom:(GMFPlayerState)fromState
                  to:(GMFPlayerState)toState {
  // Ignore buffering events - we can't reliable predict when they will be fired
  if (toState != kGMFPlayerStateBuffering) {
    [_eventList addObject:[NSNumber numberWithInt:toState]];
  }
}

- (void) videoPlayer:(GMFVideoPlayer *)videoPlayer
    currentMediaTimeDidChangeToTime:(NSTimeInterval)time {
  // no-op
}

- (void)videoPlayer:(GMFVideoPlayer *)videoPlayer
    bufferedMediaTimeDidChangeToTime:(NSTimeInterval)time {
  // no-op
}

- (void)videoPlayer:(GMFVideoPlayer *)videoPlayer
    currentTotalTimeDidChangeToTime:(NSTimeInterval)time {
  // no-op
}

+ (NSString *)stringWithState:(GMFPlayerState)state {
  switch (state) {
    case kGMFPlayerStateEmpty:
      return @"Empty";
    case kGMFPlayerStateBuffering:
      return @"Buffering";
    case kGMFPlayerStateLoadingContent:
      return @"Loading content";
    case kGMFPlayerStateReadyToPlay:
      return @"Ready to play";
    case kGMFPlayerStatePlaying:
      return @"Playing";
    case kGMFPlayerStatePaused:
      return @"Paused";
    case kGMFPlayerStateFinished:
      return @"Finished";
    case kGMFPlayerStateSeeking:
      return @"Seeking";
    case kGMFPlayerStateError:
      return @"Error";
  }
  return nil;
}

@end