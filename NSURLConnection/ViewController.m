//
//  ViewController.m
//  NSURLConnection
//
//  Created by wangjianwei on 15/10/22.
//  Copyright (c) 2015年 JW. All rights reserved.
//
#define JWLog(xx, ...)  NSLog(@"%@%s(%d): " xx,[NSThread currentThread], __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#import "ViewController.h"

@interface ViewController ()<NSURLConnectionDataDelegate>

@property long long currentLength;

@property long long totalLength;

@property (strong,nonatomic) NSMutableData *dataM;

@property (weak, nonatomic) IBOutlet UIProgressView *progress;

@property (nonatomic,assign) BOOL downloading;

@property (nonatomic,assign) BOOL shouldAlwaysLoop;
@end

@implementation ViewController

-(NSMutableData *)dataM{
    
    if (_dataM == nil) {
        _dataM = [NSMutableData data];
    }
    return  _dataM;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self download];
    });
}
-(void)download{
    if (!self.downloading) {
        self.downloading = YES;
        NSString * str = [NSString stringWithFormat:@"http://127.0.0.1/01-知识点回顾.mp4"];
        str = [str stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSMutableURLRequest  * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:str] cachePolicy:1 timeoutInterval:10];
        NSURLConnection *connection = [NSURLConnection connectionWithRequest:request delegate:self];
        JWLog(@"%@",[NSRunLoop currentRunLoop]);
        [connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        [connection setDelegateQueue:[[NSOperationQueue alloc]init]];
        [connection start];
//        [[NSRunLoop currentRunLoop]run];
        [[NSRunLoop currentRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:60*60*24]];
        self.shouldAlwaysLoop = YES;
        while (self.shouldAlwaysLoop && [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
    }
}
#pragma mark -NSURLConnection

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progress setProgress:0];
    });
    JWLog(@"%lld",response.expectedContentLength);
    self.totalLength = response.expectedContentLength;
    self.currentLength = 0;
    self.dataM = nil;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{

    self.currentLength += data.length;
    JWLog(@"%lld",self.currentLength);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progress setProgress:(float)self.currentLength/self.totalLength animated:YES];
    });
    [self writeData:data toPath:@"/Users/JW/Desktop/123.mp4"];
}

-(void)writeData:(NSData *)data toPath:(NSString *)path{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if ([[NSFileManager defaultManager]fileExistsAtPath:path]) {
            [[NSFileManager defaultManager]removeItemAtPath:path error:NULL];
        }
    });
    NSFileHandle *fp = [NSFileHandle fileHandleForWritingAtPath:path];
    if (fp == nil) {
        [data writeToFile:path atomically:YES];
    }else{
        [fp seekToEndOfFile];
        [fp writeData:data];
        [fp closeFile];
    }
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
    JWLog(@"下载完成");
    self.downloading = NO;
    self.shouldAlwaysLoop = NO;
}
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    JWLog(@"下载有错误：%@",error);
}
@end
