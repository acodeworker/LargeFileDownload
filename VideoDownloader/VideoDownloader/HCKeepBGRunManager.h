//
//  HCKeepBGRunManager.h
//  SoundBackProject
//
//  Created by zmodo on 2019/7/2.
//  Copyright © 2019 ZCZ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HCKeepBGRunManager : NSObject

+ (HCKeepBGRunManager *)shareManager;

/**
 开启后台运行
 */
- (void)startBGRun;

/**
 关闭后台运行
 */
- (void)stopBGRun;

@end

NS_ASSUME_NONNULL_END
