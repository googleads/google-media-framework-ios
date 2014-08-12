

#import "GMFContentPlayhead.h"

@interface GMFContentPlayhead ()

@property (nonatomic, weak) GMFPlayerViewController * playerViewController;

@end

@implementation GMFContentPlayhead {
}

- (instancetype)init {
  NSAssert(false, @"You must initialize GMFContentPlayhead using initWithGMFPlayerViewController");
  return nil;
}

- (instancetype)initWithGMFPlayerViewController:(GMFPlayerViewController *)playerViewController {
  self = [super init];
  if (self) {
    _playerViewController = playerViewController;
    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(currentMediaTimeDidChange)
               name:kGMFPlayerCurrentMediaTimeDidChangeNotification
             object:_playerViewController];
  }
  return self;
}

- (void)currentMediaTimeDidChange {
  [self willChangeValueForKey:@"currentTime"];
  _currentTime = _playerViewController.currentMediaTime;
  [self didChangeValueForKey:@"currentTime"];
}

// Tell KVO that we will manually notify when the value of currentTime changes.
+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)theKey {
  BOOL automatic = NO;
  if ([theKey isEqualToString:@"currentTime"]) {
    automatic = NO;
  } else {
    automatic = [super automaticallyNotifiesObserversForKey:theKey];
  }
  return automatic;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter]
      removeObserver:self
                name:kGMFPlayerCurrentMediaTimeDidChangeNotification
              object:nil];
}

@end
