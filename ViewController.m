//
//  ViewController.m
//  VideoWatermarkBugExample
//
//  Created by Brian Shamblen on 12/5/13.
//  Copyright (c) 2013 Brian Shamblen. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()
{
    MPMoviePlayerController *moviePlayer;
    CGSize renderingSize;
    float displayDuration;
    
    AVMutableComposition *mutableComposition;
    AVMutableVideoComposition *videoComposition;
    AVMutableCompositionTrack *mutableCompositionVideoTrack;
    AVAssetExportSession *exporter;
}
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    renderingSize = CGSizeMake(640, 360);
    displayDuration = 2.0;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)generateVideo:(UIButton *)sender
{
    if (moviePlayer)
        [moviePlayer.view removeFromSuperview];
    
    self.progressView.hidden = NO;
    self.progressView.progress = 0.0;
    [NSTimer scheduledTimerWithTimeInterval:0.05
									 target:self
								   selector:@selector(updateExportProgress:)
								   userInfo:nil
									repeats:YES];
    [self generateBrandingShot];
}

-(void)updateExportProgress:(NSTimer *)timer
{
    self.progressView.progress = exporter.progress;
}

-(void)generateBrandingShot
{
    NSURL *brandingURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), @"branding.mp4"]];
    
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtURL:brandingURL error:&error];
    
    mutableComposition = [AVMutableComposition composition];
    mutableCompositionVideoTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.renderSize = renderingSize;
    videoComposition.frameDuration = CMTimeMake(1, 30);
    
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, videoComposition.renderSize.width, videoComposition.renderSize.height);
    videoLayer.frame = CGRectMake(0, 0, videoComposition.renderSize.width, videoComposition.renderSize.height);
    [parentLayer addSublayer:videoLayer];
    
    videoComposition.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"blank_1080p" ofType:@"mp4"];
    NSURL *url = [NSURL fileURLWithPath:path];
    AVAsset *asset = [AVAsset assetWithURL:url];
    AVAssetTrack *track = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    [mutableCompositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero,CMTimeMakeWithSeconds(displayDuration, 600)) ofTrack:track atTime:kCMTimeZero error:nil];
    
    CALayer *imageLayer = [CALayer layer];
    imageLayer.bounds = parentLayer.frame;
    imageLayer.anchorPoint = CGPointMake(0.5, 0.5);
    imageLayer.position = CGPointMake(CGRectGetMidX(imageLayer.bounds), CGRectGetMidY(imageLayer.bounds));
    imageLayer.contents = (id)[UIImage imageNamed:@"template_branding_background.png"].CGImage;
    imageLayer.contentsGravity = kCAGravityResizeAspectFill;
    imageLayer.zPosition = 0;
    [parentLayer addSublayer:imageLayer];
    
    UIImage *testImage = [UIImage imageNamed:@"bannerTextLayer.png"];
    
    CALayer *titleLayer = [CALayer layer];
    titleLayer.bounds = CGRectMake(0, 0, 540, 40);
    titleLayer.anchorPoint = CGPointMake(0.5, 0.5);
    titleLayer.position = CGPointMake(CGRectGetMidX(titleLayer.bounds), CGRectGetMidY(titleLayer.bounds));
    titleLayer.contents = (id)testImage.CGImage;
    titleLayer.contentsGravity = kCAGravityResizeAspect;
    titleLayer.zPosition = 0;
    [parentLayer addSublayer:titleLayer];
    
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(displayDuration, 600));
    videoComposition.instructions = @[instruction];
    
    exporter = [[AVAssetExportSession alloc] initWithAsset:mutableComposition presetName:AVAssetExportPresetHighestQuality];
    exporter.outputURL = brandingURL ;
    exporter.videoComposition = videoComposition;
    exporter.outputFileType= AVFileTypeMPEG4;
    exporter.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(displayDuration, 600));
    exporter.shouldOptimizeForNetworkUse = YES;
    
    [exporter exportAsynchronouslyWithCompletionHandler:^(void){
        switch (exporter.status) {
            case AVAssetExportSessionStatusFailed:{
                NSLog(@"Fail: %@", exporter.error);
                break;
            }
            case AVAssetExportSessionStatusCompleted:{
                NSLog(@"Success");
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.progressView.hidden = YES;
                    if (moviePlayer)
                        [moviePlayer.view removeFromSuperview];
                    
                    moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:brandingURL];
                    
                    moviePlayer.view.frame = CGRectMake(0, 0, 320, 180);
                    [moviePlayer setControlStyle:MPMovieControlStyleNone];
                    
                    [self.previewView addSubview:moviePlayer.view];
                    [moviePlayer play];
                    
                });
                
                break;
            }
            default:
                break;
        }
    }];
}

@end
