//
//  UIViewController+AutoTrack.m
//  SensorsAnalyticsSDK
//
//  Created by 王灼洲 on 2017/10/18.
//  Copyright © 2015-2020 Sensors Data Co., Ltd. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif


#import "UIViewController+AutoTrack.h"
#import "SensorsAnalyticsSDK.h"
#import "SAConstants+Private.h"
#import "SACommonUtility.h"
#import "SALog.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "UIView+AutoTrack.h"
#import "SAAutoTrackManager.h"
#import "SAWeakPropertyContainer.h"
#import <objc/runtime.h>
#import "SAAppViewScreenDurationTracker.h"

static void *const kSAPreviousViewController = (void *)&kSAPreviousViewController;

@implementation UIViewController (AutoTrack)

- (BOOL)sensorsdata_isIgnored {
    return ![[SAAutoTrackManager sharedInstance].appClickTracker shouldTrackViewController:self];
}

- (NSString *)sensorsdata_screenName {
    return NSStringFromClass([self class]);
}

- (NSString *)sensorsdata_title {
    __block NSString *titleViewContent = nil;
    __block NSString *controllerTitle = nil;
    [SACommonUtility performBlockOnMainThread:^{
        titleViewContent = self.navigationItem.titleView.sensorsdata_elementContent;
        controllerTitle = self.navigationItem.title;
    }];
    if (titleViewContent.length > 0) {
        return titleViewContent;
    }

    if (controllerTitle.length > 0) {
        return controllerTitle;
    }
    
    UILabel *titleLabel = [self valueForKey:@"jw_leftTitleLabel"];
    if (titleLabel.text.length > 0) {
        return titleLabel.text;
    }

    return nil;
}

- (void)sa_autotrack_viewDidAppear:(BOOL)animated {
    // 防止 tabbar 切换，可能漏采 $AppViewScreen 全埋点
    if ([self isKindOfClass:UINavigationController.class]) {
        UINavigationController *nav = (UINavigationController *)self;
        nav.sensorsdata_previousViewController = nil;
    }

    SAAppViewScreenTracker *appViewScreenTracker = SAAutoTrackManager.sharedInstance.appViewScreenTracker;

    // parentViewController 判断，防止开启子页面采集时候的侧滑多采集父页面 $AppViewScreen 事件
    if (self.navigationController && self.parentViewController == self.navigationController) {
        // 全埋点中，忽略由于侧滑部分返回原页面，重复触发 $AppViewScreen 事件
        if (self.navigationController.sensorsdata_previousViewController == self) {
            return [self sa_autotrack_viewDidAppear:animated];
        }
    }
    
    SAAppViewScreenDurationTracker *appViewScreenDurationTracker = [SAAppViewScreenDurationTracker new];
    [self setAppViewScreenDurationTracker:appViewScreenDurationTracker];

#ifndef SENSORS_ANALYTICS_ENABLE_AUTOTRACK_CHILD_VIEWSCREEN
    UIViewController *viewController = (UIViewController *)self;
    if (!viewController.parentViewController ||
        [viewController.parentViewController isKindOfClass:[UITabBarController class]] ||
        [viewController.parentViewController isKindOfClass:[UINavigationController class]] ||
        [viewController.parentViewController isKindOfClass:[UIPageViewController class]] ||
        [viewController.parentViewController isKindOfClass:[UISplitViewController class]]) {
        [appViewScreenTracker autoTrackEventWithViewController:viewController];
        [appViewScreenDurationTracker trackTimerStartForAppViewScreenDuration];
    }
#else
    [appViewScreenTracker autoTrackEventWithViewController:self];
    [appViewScreenDurationTracker trackTimerStartForAppViewScreenDuration];
#endif

    // 标记 previousViewController
    if (self.navigationController && self.parentViewController == self.navigationController) {
        self.navigationController.sensorsdata_previousViewController = self;
    }

    [self sa_autotrack_viewDidAppear:animated];
}

- (void)sa_autotrack_viewDidDisappear:(BOOL)animated {
    
    // 防止 tabbar 切换，可能漏采 $AppViewScreen 全埋点
    if ([self isKindOfClass:UINavigationController.class]) {
        UINavigationController *nav = (UINavigationController *)self;
        nav.sensorsdata_previousViewController = nil;
    }

    // parentViewController 判断，防止开启子页面采集时候的侧滑多采集父页面 $AppViewScreen 事件
    if (self.navigationController && self.parentViewController == self.navigationController) {
        // 全埋点中，忽略由于侧滑部分返回原页面，重复触发 $AppViewScreen 事件
        if (self.navigationController.sensorsdata_previousViewController == self) {
            return [self sa_autotrack_viewDidDisappear:animated];
        }
    }
    
    SAAppViewScreenDurationTracker *appViewScreenDurationTracker = [self appViewScreenDurationTracker];

#ifndef SENSORS_ANALYTICS_ENABLE_AUTOTRACK_CHILD_VIEWSCREEN
    UIViewController *viewController = (UIViewController *)self;
    if (!viewController.parentViewController ||
        [viewController.parentViewController isKindOfClass:[UITabBarController class]] ||
        [viewController.parentViewController isKindOfClass:[UINavigationController class]] ||
        [viewController.parentViewController isKindOfClass:[UIPageViewController class]] ||
        [viewController.parentViewController isKindOfClass:[UISplitViewController class]]) {
        [appViewScreenDurationTracker autoTrackEventWithViewController:viewController];
    }
#else
    [appViewScreenDurationTracker autoTrackEventWithViewController:viewController];
#endif

    [self sa_autotrack_viewDidDisappear:animated];

}

#pragma mark - Private

const void *appViewScreenDurationTrackerKey = &appViewScreenDurationTrackerKey;

- (void)setAppViewScreenDurationTracker:(SAAppViewScreenDurationTracker *)tracker {
    objc_setAssociatedObject(self, appViewScreenDurationTrackerKey, tracker, OBJC_ASSOCIATION_RETAIN);
}

- (SAAppViewScreenDurationTracker *)appViewScreenDurationTracker {
    return objc_getAssociatedObject(self, appViewScreenDurationTrackerKey);
}

- (nullable id)valueForUndefinedKey:(NSString *)key {
    return nil;
}

@end

@implementation UINavigationController (AutoTrack)

- (void)setSensorsdata_previousViewController:(UIViewController *)sensorsdata_previousViewController {
    SAWeakPropertyContainer *container = [SAWeakPropertyContainer containerWithWeakProperty:sensorsdata_previousViewController];
    objc_setAssociatedObject(self, kSAPreviousViewController, container, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIViewController *)sensorsdata_previousViewController {
    SAWeakPropertyContainer *container = objc_getAssociatedObject(self, kSAPreviousViewController);
    return container.weakProperty;
}

@end
