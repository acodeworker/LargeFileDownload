//
//  DownLoaderTask.h
//  VideoDownloader
//
//  Created by JeremyLu on 2019/7/1.
//  Copyright © 2019年 JeremyLu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CustomDownLoaderTaskDelegate <NSObject>
@optional
- (void)downloaderTaskProgress:(float)progress andTag:(NSInteger)tag;
- (void)downSucceedPath:(NSString*)filePath tag:(NSInteger)tag;

@end

@interface DownLoaderTask : NSObject

@property (nonatomic ,weak)id<CustomDownLoaderTaskDelegate> delegate;

- (instancetype)initWithTag:(NSInteger)tag;

- (void)downFile:(NSString*)fileUrl isBreakpoint:(BOOL)breakpoint;

- (void)resumeOrPause;

@end

NS_ASSUME_NONNULL_END
