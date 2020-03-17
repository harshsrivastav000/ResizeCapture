//
//  TOUtility.m
//  CameraOBJC
//
//  Created by harsh on 13/03/20.
//  Copyright © 2020 harsh. All rights reserved.
//


#import "TOUtility.h"
#import "SDAVAssetExportSession.h"
#include <sys/types.h>
#include <sys/sysctl.h>

@implementation TOUtility


+ (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.mindtree.CoreDataSample" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}



+(void)addWatermarkToVideo:(NSURL *)assetURL image:(UIImage *)image completion:(AddWatermarkCompletion)block{
    
    NSLog(@"addWatermarkToVideo  %@",assetURL);
    
    AVURLAsset* videoAsset = [[AVURLAsset alloc]initWithURL:assetURL options:nil];
    AVMutableComposition* mixComposition = [AVMutableComposition composition];
    
    AVMutableCompositionTrack *compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo  preferredTrackID:kCMPersistentTrackID_Invalid];
    
    NSArray *videoTracksArray = [videoAsset tracksWithMediaType:AVMediaTypeVideo];
    if(videoTracksArray.count<=0) {
        NSArray *tracks = [videoAsset tracksWithMediaCharacteristic:AVMediaCharacteristicVisual];
        if(tracks.count != 0) {
            videoTracksArray = tracks;
        } else {
            block(assetURL,[NSError errorWithDomain:@"" code:-1 userInfo:nil]);
            NSLog(@"returning without adding branding becuase tracks are 0 for %@.",assetURL);
            return;
        }
    }

    AVAssetTrack *clipVideoTrack = [videoTracksArray objectAtIndex:0];
    [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration)
                                   ofTrack:clipVideoTrack
                                    atTime:kCMTimeZero error:nil];

    [compositionVideoTrack setPreferredTransform:[[videoTracksArray objectAtIndex:0] preferredTransform]];
    
    if([videoAsset tracksWithMediaType:AVMediaTypeAudio].count>0){
        AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                            preferredTrackID:kCMPersistentTrackID_Invalid];
        [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration)
                            ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0]
                             atTime:kCMTimeZero
                              error:nil];
    }
    
    CGSize videoSize = clipVideoTrack.naturalSize;
    videoSize = CGSizeMake(fabs(videoSize.width), fabs(videoSize.height));
    CGSize imageSize = image.size;
    if(videoSize.width>videoSize.height){ // 1.

        if(imageSize.width>videoSize.width) { // a.
            float ratio = videoSize.height / imageSize.width;
            imageSize = CGSizeMake(imageSize.width * ratio, ratio * imageSize.height);
        }
        else if(imageSize.height>videoSize.height){ // b.

            float ratio = videoSize.height / imageSize.height/2;
            imageSize = CGSizeMake(ratio * imageSize.width, ratio * imageSize.height);
        }
    }
    else{
        if(imageSize.width>videoSize.width) {
            float ratio = videoSize.width / imageSize.width;
            imageSize = CGSizeMake(imageSize.width * ratio, ratio * imageSize.height);
        }
        else if(imageSize.height>videoSize.height) {

            float ratio = videoSize.height / imageSize.height;
            imageSize = CGSizeMake(ratio * imageSize.width, ratio * imageSize.height);
        }
    }
    
    
    if(imageSize.width < image.size.width){
        CGRect rect = CGRectMake(0.0, 0.0, imageSize.width, imageSize.height);
        UIGraphicsBeginImageContextWithOptions(rect.size, NO, 1);
        [image drawInRect:rect];
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    
    CALayer *aLayer = [CALayer layer];
    aLayer.contents = (id)image.CGImage;
    aLayer.opacity = 1; //Feel free to alter the alpha here
    aLayer.frame = CGRectMake(0, 0, imageSize.width, imageSize.height); //Needed
    
    
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    
    if (videoSize.width > videoSize.height) {
        parentLayer.frame = CGRectMake(0, 0, videoSize.height, videoSize.width);
        videoLayer.frame = CGRectMake(0, 0, videoSize.height, videoSize.width);
    }else{
        parentLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
        videoLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
    }
    [parentLayer addSublayer:videoLayer];
    [parentLayer addSublayer:aLayer];
    
    
    AVMutableVideoComposition* videoComp = [AVMutableVideoComposition videoComposition];
    if (videoSize.width > videoSize.height) {
        videoComp.renderSize = CGSizeMake(videoSize.height, videoSize.width);
    }else{
        videoComp.renderSize = videoSize;
    }
    
    videoComp.frameDuration = CMTimeMake(1, 30);
    videoComp.animationTool = [AVVideoCompositionCoreAnimationTool      videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    
    
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, [mixComposition duration]);
    AVAssetTrack *videoTrack = [[mixComposition tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    AVMutableVideoCompositionLayerInstruction* layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    if (videoSize.width > videoSize.height) {
        CGAffineTransform t1 = CGAffineTransformMakeTranslation(videoSize.height, 0);
        CGAffineTransform t2 = CGAffineTransformRotate(t1,90 * M_PI / 180 );
        [layerInstruction setTransform:t2 atTime:kCMTimeZero];
        [instruction setLayerInstructions:[NSArray arrayWithObject:layerInstruction]];
        videoComp.instructions = [NSArray arrayWithObject: instruction];
        
    }else{
        instruction.layerInstructions = [NSArray arrayWithObject:layerInstruction];
        videoComp.instructions = [NSArray arrayWithObject: instruction];
    }
    
    AVAssetExportSession *_assetExport = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];//AVAssetExportPresetPassthrough
    _assetExport.videoComposition = videoComp;
    
    NSString* videoName = assetURL.path.lastPathComponent;
    NSString *exportPath = [[self applicationDocumentsDirectory].path stringByAppendingPathComponent:videoName];
    NSURL    *exportUrl = [NSURL fileURLWithPath:exportPath];
    
    NSString* tempFolder = [[self applicationDocumentsDirectory].path stringByAppendingPathComponent:@"watermark"];
    NSString *tempExportPath = [tempFolder stringByAppendingPathComponent:videoName];
    NSURL    *newExportUrl = [NSURL fileURLWithPath:tempExportPath];
    
    [[NSFileManager defaultManager] createDirectoryAtPath:tempFolder withIntermediateDirectories:YES attributes:nil error:nil];
    
    
    _assetExport.outputFileType = AVFileTypeMPEG4;
    _assetExport.outputURL = newExportUrl;
    _assetExport.shouldOptimizeForNetworkUse = YES;
    
    [_assetExport exportAsynchronouslyWithCompletionHandler:
     ^(void ) {
         
         NSLog(@"addWatermarkToVideo writing status is %ld and asset error = %@", (long)_assetExport.status, _assetExport.error);
         
         if (_assetExport.status == AVAssetExportSessionStatusCompleted) {
             
             if ([[NSFileManager defaultManager] fileExistsAtPath:exportPath])
             {
                 [[NSFileManager defaultManager] removeItemAtPath:exportPath error:nil];
             }
             
             NSError* error = nil;
             if ([[NSFileManager defaultManager] fileExistsAtPath:tempExportPath])
             {
                 [[NSFileManager defaultManager] moveItemAtURL:newExportUrl toURL:exportUrl error:&error];
                 NSLog(@"addWatermarkToVideo filed moved. error = %@",error.localizedDescription);
             }
         }
         
         block(exportUrl,nil);
         
     }];
}



+(void)resizeVideo:(NSURL*)videoUrl withcompletion:(ResizeVideoCompletion)block
{

   NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *uuid = [NSUUID UUID].UUIDString;
    NSString *finalVideoURLString = [NSString stringWithFormat:@"%@%@.mp4", NSTemporaryDirectory(), uuid];
    NSURL *outputVideoUrl = ([[NSURL URLWithString:finalVideoURLString] isFileURL] == 1)?([NSURL URLWithString:finalVideoURLString]):([NSURL fileURLWithPath:finalVideoURLString]); // Url Should be a file Url, so here we check and convert it into a file Url


    SDAVAssetExportSession *compressionEncoder = [SDAVAssetExportSession.alloc initWithAsset:[AVAsset assetWithURL:videoUrl]]; // provide inputVideo Url Here
    compressionEncoder.outputFileType = AVFileTypeMPEG4;
    compressionEncoder.outputURL = outputVideoUrl; //Provide output video Url here
    compressionEncoder.videoSettings = @
    {
    AVVideoCodecKey: AVVideoCodecTypeH264,
    AVVideoWidthKey: @960,   //Set your resolution width here
    AVVideoHeightKey: @1280,  //set your resolution height here
    AVVideoCompressionPropertiesKey: @
        {
        AVVideoAverageBitRateKey: [NSNumber numberWithInt:[TOUtility bitRateForCurrentDeviceType]] , // Give your bitrate here for lower size give low values
        AVVideoProfileLevelKey: AVVideoProfileLevelH264High40,
        },
    };
    compressionEncoder.audioSettings = @
    {
    AVFormatIDKey: @(kAudioFormatMPEG4AAC),
    AVNumberOfChannelsKey: @2,
    AVSampleRateKey: @44100,
    AVEncoderBitRateKey: @128000,
    };

    [compressionEncoder exportAsynchronouslyWithCompletionHandler:^
     {
         if (compressionEncoder.status == AVAssetExportSessionStatusCompleted)
         {
            NSLog(@"Compression Export Completed Successfully");
            block(outputVideoUrl,nil);
         }
         else if (compressionEncoder.status == AVAssetExportSessionStatusCancelled)
         {
             NSLog(@"Compression Export Canceled");
                block(nil,nil);
         }
         else
         {
              NSLog(@"Compression Failed");
                block(nil,nil);

         }
     }];

}

+ (NSString *) platform{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithUTF8String:machine];
    free(machine);
    return platform;
}

+(int)bitRateForCurrentDeviceType{
    NSString *platform = [TOUtility platform];
    int bitRate = 2000000;
    if ([platform isEqualToString:@"iPad1,1"]){
        //return @"iPad";
    }
    if ([platform isEqualToString:@"iPad2,1"]){
        //return @"iPad 2 (WiFi)";
    }
    if ([platform isEqualToString:@"iPad2,2"]){
        //return @"iPad 2 (Cellular)";
    }
    if ([platform isEqualToString:@"iPad2,3"]){
        //return @"iPad 2 (Cellular)";
    }
    if ([platform isEqualToString:@"iPad2,4"]){
        //return @"iPad 2 (WiFi)";
    }
    if ([platform isEqualToString:@"iPad2,5"]){
        //return @"iPad Mini (WiFi)";
    }
    if ([platform isEqualToString:@"iPad2,6"]){
        //return @"iPad Mini (Cellular)";
    }
    if ([platform isEqualToString:@"iPad2,7"]){
        //return @"iPad Mini (Cellular)";
    }
    if ([platform isEqualToString:@"iPad3,1"]){
        //return @"iPad 3 (WiFi)";
    }
    if ([platform isEqualToString:@"iPad3,2"]){
        //return @"iPad 3 (Cellular)";
    }
    if ([platform isEqualToString:@"iPad3,3"]){
        //return @"iPad 3 (Cellular)";
    }
    if ([platform isEqualToString:@"iPad3,4"]){
        //return @"iPad 4 (WiFi)";
    }
    if ([platform isEqualToString:@"iPad3,5"]){
        //return @"iPad 4 (Cellular)";
    }
    if ([platform isEqualToString:@"iPad3,6"]){
        //return @"iPad 4 (Cellular)";
    }
    if ([platform isEqualToString:@"iPad4,1"]){
        //return @"iPad Air (WiFi)";
    }
    if ([platform isEqualToString:@"iPad4,2"]){
        //return @"iPad Air (Cellular)";
    }
    if ([platform isEqualToString:@"iPad4,4"])
    {
        //return @"iPad Mini 2 (WiFi)";
    }
    if ([platform isEqualToString:@"iPad4,5"]){
        //return @"iPad Mini 2 (Cellular)";
    }
    if ([platform isEqualToString:@"iPad4,6"]){
        //return @"iPad Mini 2";
    }
    if ([platform isEqualToString:@"iPad4,7"]){
        //return @"iPad Mini 3";
    }
    if ([platform isEqualToString:@"iPad4,8"]){
        //return @"iPad Mini 3";
    }
    if ([platform isEqualToString:@"iPad4,9"]){
        //return @"iPad Mini 3";
    }
    if ([platform isEqualToString:@"iPad5,1"]){
        //return @"iPad Mini 4 (WiFi)";
    }
    if ([platform isEqualToString:@"iPad5,2"]){
        //return @"iPad Mini 4 (LTE);
    }
    if ([platform isEqualToString:@"iPad5,3"]){
        //return @"iPad Air 2";
    }
    if ([platform isEqualToString:@"iPad5,4"]){
        //return @"iPad Air 2";
    }
    if ([platform isEqualToString:@"iPad6,7"]){
        //return @"iPad Pro (WiFi)";
        bitRate = 800000;
    }
    if ([platform isEqualToString:@"iPad6,8"]){
        //return @"iPad Pro (Cellular)";
        bitRate = 800000;
    }
    return bitRate;
}
@end
