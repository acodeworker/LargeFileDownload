//
//  DownLoaderTask.m
//  VideoDownloader
//
//  Created by JeremyLu on 2019/7/1.
//  Copyright © 2019年 JeremyLu. All rights reserved.
//

#import "DownLoaderTask.h"
#import "ZMDKeepRunManager.h"

@interface DownLoaderTask()<NSURLSessionDelegate>

@property (nonatomic,assign) NSInteger tag;

@property (nonatomic, copy) NSString* fileName;

@property (nonatomic,assign) BOOL isSuspend;

@property (nonatomic ,strong)NSURLSessionDownloadTask* task;

@property (nonatomic ,assign)UIBackgroundTaskIdentifier backIdentifier;

@property (nonatomic ,strong)NSURLSession* session;

@end

@implementation DownLoaderTask

- (instancetype)initWithTag:(NSInteger)tag
{
    if (self = [super init]) {
        self.tag = tag;
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(appWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
}


//获取当前时间 下载id标识用
- (NSString *)currentDateStr{
    NSDate *currentDate = [NSDate date];//获取当前时间，日期
    NSTimeInterval timeInterval = [currentDate timeIntervalSince1970];
    return [NSString stringWithFormat:@"%.f",timeInterval];
}

- (NSString*)getTmpFileUrl{
    
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *filePath = [docPath stringByAppendingPathComponent:@"downloadtmp"];
    filePath = [filePath stringByAppendingPathComponent:@"download.tmp"];
    
    NSLog(@"%@",filePath);
    
    //    NSString* url = [NSString stringWithFormat:@"/Users/LM/Desktop/%@.tmp",self.fileName];
    return filePath;
}

- (void)appWillTerminate:(NSNotification*)app{
    
    NSLog(@"hellozmodo%s----",__func__);

    __weak typeof(self) weakSelf = self;
    [self.task cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
        
        [resumeData writeToFile:[weakSelf getTmpFileUrl] atomically:NO];
        NSLog(@"hellozmodo%s----%@",__func__,resumeData);

    }];
}


//提前保存临时文件 预防下载中杀掉app
//开启定时器
-(void)saveTmpFile{
    [NSTimer scheduledTimerWithTimeInterval:4 target:self selector:@selector(downloadTmpFile) userInfo:nil repeats:YES];
}



//杀掉app后 不至于下载的部分文件全部丢失
- (void)downloadTmpFile{
    //下载状态才记录
    if(self.isSuspend) return;
    __weak typeof(self) weakSelf = self;

    [self.task cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
        
        NSLog(@"杀死程序 来了这里");
        //每4s 保存一次临时文件
        [resumeData writeToFile:[self getTmpFileUrl] atomically:NO];
        //继续下载
        weakSelf.task = [self.session downloadTaskWithResumeData:resumeData];
        [weakSelf.task resume];
     }];
}



//开始下载
- (void)downFile:(NSString*)fileUrl isBreakpoint:(BOOL)breakpoint
{
    if (!fileUrl.length) { return;}
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSData *fileData  = [fm contentsAtPath:[self getTmpFileUrl]];
    NSString *fileStr = [[NSString alloc] initWithData:fileData encoding:NSUTF8StringEncoding];
    NSLog(@"resumeData == %@",fileData);
    NSLog(@"fileStr == %@",fileStr);
    NSString* fileTempName = [[NSUserDefaults standardUserDefaults]objectForKey:fileUrl];
 
    self.fileName = [fileUrl lastPathComponent];
//    NSURLSessionConfiguration* config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:[self currentDateStr]];
    NSURLSession* session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    self.session = session;
    NSURLSessionDownloadTask* task = nil;
    if (fileTempName.length) {
        //全路径
       fileTempName = [NSTemporaryDirectory() stringByAppendingPathComponent:fileTempName];
        NSData*  resumeData = [self getResumeDataWithFilePath:fileTempName url:fileUrl];
        task =  [session downloadTaskWithResumeData:resumeData];
        
    }else{
        task = [session downloadTaskWithURL:[NSURL URLWithString:fileUrl]];
        NSString* fileTempName = [[task valueForKey:@"downloadFile"]valueForKey:@"path"];
        [[NSUserDefaults standardUserDefaults]setObject:fileTempName.lastPathComponent forKey:fileUrl];
    }
    self.task = task;
    [task resume];
    [[ZMDKeepRunManager sharedInstance]startBackGroundRunning];
}


- (void)resumeOrPause{
     if (!self.isSuspend) {
        [self.task suspend];
     }else{
        [self.task resume];
     }
    self.isSuspend = !self.isSuspend;
    
}

- (NSData *)getResumeDataWithFilePath:(NSString *)tempFilePath url:(NSString *)url {
    NSData *resumeData;
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    if ([fileMgr fileExistsAtPath:tempFilePath]) {
        NSDictionary *tempFileAttr = [[NSFileManager defaultManager] attributesOfItemAtPath:tempFilePath error:nil ];
        unsigned long long fileSize = [tempFileAttr[NSFileSize] unsignedLongLongValue];
        
        if (fileSize > 0) {
            NSMutableDictionary *fakeResumeData = [NSMutableDictionary dictionary];
            
            NSMutableURLRequest *newResumeRequest =[NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
            NSString *bytesStr =[NSString stringWithFormat:@"bytes=%ld-",fileSize];
            [newResumeRequest addValue:bytesStr forHTTPHeaderField:@"Range"];
            
            NSData *newResumeData =[NSKeyedArchiver archivedDataWithRootObject:newResumeRequest];
            [fakeResumeData setObject:newResumeData forKey:@"NSURLSessionResumeCurrentRequest"];
            [fakeResumeData setObject:url forKey:@"NSURLSessionDownloadURL"];
            [fakeResumeData setObject:@(fileSize) forKey:@"NSURLSessionResumeBytesReceived"];
            [fakeResumeData setObject:[tempFilePath lastPathComponent] forKey:@"NSURLSessionResumeInfoTempFileName"]; // iOS9以下 需要路径
            
            resumeData = [NSPropertyListSerialization dataWithPropertyList:fakeResumeData format:NSPropertyListXMLFormat_v1_0 options:0 error:nil];
        }
    }
    return resumeData;
}


#pragma mark - NSURLSessionDownloadTaskDelegate

/* Sent periodically to notify the delegate of download progress. */
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    float downPro   = 1.0 * totalBytesWritten/totalBytesExpectedToWrite;
    NSLog(@"下载进度：%f",downPro);
    NSLog(@"%@",[[downloadTask valueForKey:@"downloadFile"]valueForKey:@"path"]);
    if (self.delegate && [self.delegate respondsToSelector:@selector(downloaderTaskProgress:andTag:)]) {
        [self.delegate downloaderTaskProgress:downPro andTag:self.tag];
    }
    
}

/* Sent when a download has been resumed. If a download failed with an
 * error, the -userInfo dictionary of the error will contain an
 * NSURLSessionDownloadTaskResumeData key, whose value is the resume
 * data.
 */
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes
{
    
}

//下载失败调用
-(void)URLSession:(nonnull NSURLSession *)session task:(nonnull NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error{
    
    // 根据不同错误反馈不同 -- 错误吗层
    // 200-299
    // 序列化 -- http / json
    if (error) {
        NSData* resumedata = [[error userInfo]objectForKey:NSURLSessionDownloadTaskResumeData];

    }
}

/*
 2.下载完成之后调用该方法
 */
-(void)URLSession:(nonnull NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(nonnull NSURL *)location
{

    //下载完成后放到一个特定的文件夹中
    NSFileManager* manager = [NSFileManager defaultManager];
    NSString *directoryPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"videoDownload"];
    BOOL isExist = [manager fileExistsAtPath:directoryPath];
    if (!isExist) {
        [manager createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *file = [directoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",self.fileName]];
    NSError *saveError;
    if ([manager fileExistsAtPath:file]) {
        [manager removeItemAtPath:file error:&saveError];
        if (saveError) {//出错了
            NSLog(@"removepath:%@",saveError.userInfo);
        }
    }
//    BOOL success = [manager copyItemAtPath:location.path toPath:file error:&saveError];
    BOOL success = [[NSFileManager defaultManager]moveItemAtURL:location toURL:[NSURL fileURLWithPath:file] error:&saveError];
    if (saveError) {//出错了
        NSLog(@"saveError:%@",saveError.userInfo);
    }
    if (success) {
       
        [manager removeItemAtPath:location.path error:&saveError];
        if (saveError) {//出错了
            NSLog(@"saveError:%@",saveError.userInfo);
        }
        NSLog(@"hello download successfully");

        [[ZMDKeepRunManager sharedInstance]stopBGRun];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(downSucceedPath:tag:)]) {
            NSLog(@"hello download successfully -- delegate");

            [self.delegate downSucceedPath:file tag:self.tag];
        }
    }
   
    
    
}

@end
