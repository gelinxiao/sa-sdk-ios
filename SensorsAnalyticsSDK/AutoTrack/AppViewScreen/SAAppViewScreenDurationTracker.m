//
// SAAppViewScreenDurationTracker.m
// SensorsAnalyticsSDK
//
// Created by 葛林晓 on 2021/8/2.
// Copyright © 2021 Sensors Data Co., Ltd. All rights reserved.
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
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAAppViewScreenDurationTracker.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAConstants+Private.h"

@interface SAAppViewScreenDurationTracker ()

@property (nonatomic, copy) NSString *timerEventID;

@end

@implementation SAAppViewScreenDurationTracker

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        _timerEventID = kSAEventNameAppViewScreenDuration;
    }
    return self;
}

#pragma mark - Override

- (NSString *)eventId {
    return self.timerEventID ?: kSAEventNameAppViewScreenDuration;
}

- (BOOL)isIgnored {
    return [super isIgnored];
}

- (BOOL)isPassively {
    return [super isPassively];
}

#pragma mark - Public Methods

- (void)trackTimerStartForAppViewScreenDuration {
    self.timerEventID = [SensorsAnalyticsSDK.sdkInstance trackTimerStart:kSAEventNameAppEnd];
}

@end
