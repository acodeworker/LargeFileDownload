//
//  ZMDKeepRunManager.m
//  VideoDownloader
//
//  Created by zmodo on 2019/7/2.
//  Copyright © 2019 JeremyLu. All rights reserved.
//

#import "ZMDKeepRunManager.h"
#import <AVFoundation/AVFoundation.h>

@interface ZMDKeepRunManager()
{
    dispatch_queue_t _queue;
    NSInteger _count;
}
@property (nonatomic, strong) AVAudioPlayer *playerBack;

@property (nonatomic, assign) UIBackgroundTaskIdentifier task;

@property (nonatomic, strong) NSTimer *logTimer;
@property (nonatomic, strong) NSTimer *soundTimer;

@property (nonatomic, assign) CFRunLoopRef runloopRef;

@end

@implementation ZMDKeepRunManager

static ZMDKeepRunManager* manager = nil;

+ (instancetype)sharedInstance{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken,^{
        manager = [[ZMDKeepRunManager alloc]init];
    });
    return manager;
    
}

- (instancetype)init
{
    if (self = [super init]) {
        [self setupAudioSession];
       
    }
    return self;
}

- (void)setupAudioSession {
    // 新建AudioSession会话
    _queue = dispatch_queue_create("com.audio.inBackground", NULL);

    AVAudioSession* audio = [AVAudioSession sharedInstance];
    //设置后台播放
    NSError* error = nil;
    [audio setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionMixWithOthers error:&error];
    if (error) {
        NSLog(@"setcategory avaudiosession: %@",error);
    }
    // 启动AudioSession，如果一个前台app正在播放音频则可能会启动失败

    [audio setActive:YES error:&error];
    if (error) {
        NSLog(@"Error activating AVAudioSession: %@", error);
    }
     //静音文件
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"noVoice" ofType:@"mp3"];
    NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:filePath];
    self.playerBack = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:nil];
    [self.playerBack prepareToPlay];
    // 0.0~1.0,默认为1.0
    self.playerBack.volume = 0.01;
    // 循环播放
    self.playerBack.numberOfLoops = -1;
     
}


-(void)startBackGroundRunning
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(_queue, ^{
        self.logTimer = [[NSTimer alloc]initWithFireDate:[NSDate date] interval:1 target:self selector:@selector(log) userInfo:nil repeats:YES];
//        self.soundTimer = [[NSTimer alloc]initWithFireDate:[NSDate date] interval:60 target:self selector:@selector(startAudioPlay) userInfo:nil repeats:YES];
        weakSelf.runloopRef = CFRunLoopGetCurrent();
        [[NSRunLoop currentRunLoop]addTimer:self.logTimer forMode:NSDefaultRunLoopMode];
//        [[NSRunLoop currentRunLoop]addTimer:self.soundTimer forMode:NSDefaultRunLoopMode];
        CFRunLoopRun();
    });
    
    [self.playerBack play];
//    [self applyforBackgroundTask];
}




/**
 申请后台
 */
- (void)applyforBackgroundTask {
    
    __weak typeof(self) myself = self;
    _task =[[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] endBackgroundTask:myself.task];
            myself.task = UIBackgroundTaskInvalid;
        });
    }];
}

/**
 打印
 */
- (void)log{
//    _count = _count + 1;
    NSLog(@"后台继续活跃呢");
}

/**
 检测后台运行时间
 */
- (void)startAudioPlay{
    _count = 0;
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([[UIApplication sharedApplication] backgroundTimeRemaining] < 61.0) {
            NSLog(@"后台快被杀死了");
            [self.playerBack play];
            [self applyforBackgroundTask];
        } else{
            NSLog(@"后台继续活跃呢");
        }///再次执行播放器停止，后台一直不会播放音乐文件
        [self.playerBack stop];
    });
}

/**
 停止后台运行
 */
- (void)stopBGRun{
    if (self.logTimer) {
        CFRunLoopStop(self.runloopRef);
        [self.logTimer invalidate];
        self.logTimer = nil;
        // 关闭定时器即可
        [self.soundTimer invalidate];
        self.soundTimer = nil;
        [self.playerBack stop];
    }
    if (_task) {
        [[UIApplication sharedApplication] endBackgroundTask:_task];
        _task = UIBackgroundTaskInvalid;
    }
    
    NSLog(@"hello %s",__func__);
    
}

@end
