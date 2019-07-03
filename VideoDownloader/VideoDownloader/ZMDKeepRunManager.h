//
//  ZMDKeepRunManager.h
//  VideoDownloader
//
//  Created by zmodo on 2019/7/2.
//  Copyright © 2019 JeremyLu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZMDKeepRunManager : NSObject

+ (instancetype)sharedInstance;

- (void)startBackGroundRunning;

- (void)stopBGRun;

@end

NS_ASSUME_NONNULL_END
