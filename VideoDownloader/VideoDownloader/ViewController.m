//
//  ViewController.m
//  VideoDownloader
//
//  Created by JeremyLu on 2019/7/1.
//  Copyright © 2019年 JeremyLu. All rights reserved.
//

#import "ViewController.h"
#import "DownLoaderTask.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()<CustomDownLoaderTaskDelegate,AVAudioPlayerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *progressLabl;

@property (weak, nonatomic) IBOutlet UIProgressView *progress;

@property (nonatomic ,strong)DownLoaderTask* task;


@end

@implementation ViewController

- (IBAction)startDownloader:(id)sender {
    NSString *fileUrl = @"https://pic.ibaotu.com/00/48/71/79a888piCk9g.mp4";
    //    NSString *url = @"https://ss0.bdstatic.com/94oJfD_bAAcT8t7mm9GUKT-xh_/timg?image&quality=100&size=b4000_4000&sec=1556013089&di=8e3bb21e0e7b9ff9acfcd23609b10817&src=http://pic.90sjimg.com/back_pic/qk/back_origin_pic/00/03/46/6e9930b1b0af90f162d7339028d2ca29.jpg";
//    fileUrl = @"https://www.apple.com/105/media/cn/iphone-x/2017/01df5b43-28e4-4848-bf20-490c34a926a7/films/feature/iphone-x-feature-cn-20170912_1280x720h.mp4";
    
    [self.task downFile:fileUrl isBreakpoint:YES];
}

- (IBAction)resumeOrpause:(id)sender {
    [self.task resumeOrPause];
    
}

- (IBAction)duandianxuchuan:(id)sender {

}
- (IBAction)cancelDownloader:(id)sender {

}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.task = [[DownLoaderTask alloc]initWithTag:0];
    self.task.delegate = self;
    
 }


- (void)downloaderTaskProgress:(float)progress andTag:(NSInteger)tag
{
    self.progressLabl.text = [NSString stringWithFormat:@"%.4f",progress];
    self.progress.progress = progress;
}

- (void)downSucceedPath:(NSString*)filePath tag:(NSInteger)tag
{
    
}




@end
