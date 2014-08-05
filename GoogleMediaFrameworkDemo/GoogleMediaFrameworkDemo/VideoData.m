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

@implementation VideoData

- (instancetype)initWithVideoURL:(NSString *)videoURL
                 title:(NSString *)title
               summary:(NSString *)summary
              adTagURL:(NSString *)adTagURL {
  self = [super init];
  if (self) {
    _videoURL = videoURL;
    _title = title;
    _summary = summary;
    _adTagURL = adTagURL;
  }
  return self;
}

@end
