
#import <Foundation/Foundation.h>
#import <GoogleMediaFramework/GoogleMediaFramework.h>
#import <IMAContentPlayhead.h>

// Provides a KVO observable property for the Google Interactive Media Ads SDK (IMA SDK).
@interface GMFContentPlayhead : NSObject<IMAContentPlayhead>

@property(nonatomic, readonly) NSTimeInterval currentTime;

- (instancetype)initWithGMFPlayerViewController:(GMFPlayerViewController *)playerViewController;

@end
