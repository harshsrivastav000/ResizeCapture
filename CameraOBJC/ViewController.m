//
//  ViewController.m
//  CameraOBJC
//
//  Created by harsh on 13/03/20.
//  Copyright © 2020 harsh. All rights reserved.
//

#define TODocumentDirectory [[TOStorage sharedStorage] applicationDocumentsDirectory]



#import "ViewController.h"


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.isRecording = NO;
    [self initializeCameraManager];
}

-(void)initializeCameraManager {
    self.cameraManager = [[CameraManager alloc] init];
    self.cameraManager.writeFilesToPhoneLibrary = NO;
    self.cameraManager.shouldRespondToOrientationChanges = NO;
    self.cameraManager.cameraOutputQuality = CameraOutputQualityHigh;
    self.cameraManager.cameraDevice = CameraDeviceFront;
    
    _cameraManager.cameraOutputMode = CameraOutputModeVideoWithMic;
    CameraState cameraState = [self.cameraManager addPreviewLayerToView:self.cameraLayer newCameraOutputMode:CameraOutputModeVideoWithMic];
    NSLog(@"camera state is %ld",(long)cameraState);
}

- (IBAction)recordButtonAction:(id)sender {
    
    if(self.isRecording == YES) {
        self.isRecording = NO;
        [_cameraManager stopVideoRecording:^(NSURL * _Nullable url, NSError * _Nullable error) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"%@", url);
                [self cropVideoSquare:url withCompletion:^(NSURL *asset) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [TOUtility resizeVideo:asset withcompletion:^(NSURL * _Nonnull new_assetURL, NSError * _Nonnull error) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [TOUtility addWatermarkToVideo:new_assetURL image:[UIImage imageNamed:@"Final_3.png"] completion:^(NSURL * _Nonnull assetURL, NSError * _Nonnull error) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        UISaveVideoAtPathToSavedPhotosAlbum(assetURL.path, nil, nil,nil);
                                        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Success"
                                                                                                                 message:@"Video Saved"
                                                                                                          preferredStyle:UIAlertControllerStyleAlert];
                                    
                                        UIAlertAction *actionOk = [UIAlertAction actionWithTitle:@"OK"
                                                                                           style:UIAlertActionStyleDefault
                                                                                         handler:nil];
                                        [alertController addAction:actionOk];
                                        [self presentViewController:alertController animated:YES completion:nil];
                                        //                }];
                                    });
                                }];
                            });
                        }];
                        
                        
                    });
                    
                }];
                
//                [self cropView:url withCompletion:^(NSURL *asset) {
//
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        UISaveVideoAtPathToSavedPhotosAlbum(asset.path, nil, nil,nil);
//                        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Success"
//                                                                                                 message:@"Video Saved"
//                                                                                          preferredStyle:UIAlertControllerStyleAlert];
//                        //We add buttons to the alert controller by creating UIAlertActions:
//                        UIAlertAction *actionOk = [UIAlertAction actionWithTitle:@"OK"
//                                                                           style:UIAlertActionStyleDefault
//                                                                         handler:nil]; //You can use a block here to handle a press on this button
//                        [alertController addAction:actionOk];
//                        [self presentViewController:alertController animated:YES completion:nil];
//                    });
//
//                }];
            });
        }];
    } else {
        self.isRecording = YES;
        [self.cameraManager startRecordingVideo];
    }
}



-(void)cropView:(NSURL*)outputfile withCompletion:(void (^)(NSURL *asset))block
{
     AVAsset *asset = [AVAsset assetWithURL:outputfile];


    AVAssetTrack *clipVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    AVMutableVideoComposition* videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.frameDuration = CMTimeMake(1, 30);

    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(60, 30));

    CGSize videoSize = [[[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] naturalSize];
    float scaleFactor;

    if (videoSize.width > videoSize.height) {

        scaleFactor = videoSize.height/720;
    }
    else if (videoSize.width == videoSize.height){

        scaleFactor = videoSize.height/720;
    }
    else{
        scaleFactor = videoSize.width/720;
    }



    CGFloat cropOffX = 0;
    CGFloat cropOffY = (170 * self.view.frame.size.height)/ 1112;
    CGFloat cropWidth = 720 *scaleFactor;
    CGFloat cropHeight = 720 *scaleFactor;

    videoComposition.renderSize = CGSizeMake(cropWidth, cropHeight);

    AVMutableVideoCompositionLayerInstruction* transformer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:clipVideoTrack];

    UIImageOrientation videoOrientation = [self getVideoOrientationFromAsset:asset];

    CGAffineTransform t1 = CGAffineTransformIdentity;
    CGAffineTransform t2 = CGAffineTransformIdentity;

    switch (videoOrientation) {
        case UIImageOrientationUp:
            t1 = CGAffineTransformMakeTranslation(clipVideoTrack.naturalSize.height - cropOffX, 0 - cropOffY );
            t2 = CGAffineTransformRotate(t1, M_PI_2 );
            break;
        case UIImageOrientationDown:
            t1 = CGAffineTransformMakeTranslation(0 - cropOffX, clipVideoTrack.naturalSize.width - cropOffY ); // not fixed width is the real height in upside down
            t2 = CGAffineTransformRotate(t1, - M_PI_2 );
            break;
        case UIImageOrientationRight:
            t1 = CGAffineTransformMakeTranslation(0 - cropOffX, 0 - cropOffY );
            t2 = CGAffineTransformRotate(t1, 0 );
            break;
        case UIImageOrientationLeft:
            t1 = CGAffineTransformMakeTranslation(clipVideoTrack.naturalSize.width - cropOffX, clipVideoTrack.naturalSize.height - cropOffY );
            t2 = CGAffineTransformRotate(t1, M_PI  );
            break;
        default:
            NSLog(@"no supported orientation has been found in this video");
            break;
    }

    CGAffineTransform finalTransform = t2;
    [transformer setTransform:finalTransform atTime:kCMTimeZero];

    //add the transformer layer instructions, then add to video composition
    instruction.layerInstructions = [NSArray arrayWithObject:transformer];
    videoComposition.instructions = [NSArray arrayWithObject: instruction];

    NSString *uuid = [NSUUID UUID].UUIDString;
    NSString *outputPath = [NSString stringWithFormat:@"%@%@.mp4", NSTemporaryDirectory(), uuid];
    NSURL *exportUrl = [NSURL fileURLWithPath:outputPath];

    //[[NSFileManager defaultManager]  removeItemAtURL:exportUrl error:nil];


    //Export
    self.exporter = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetHighestQuality] ;
    self.exporter.videoComposition = videoComposition;
    self.exporter.outputURL = exportUrl;
    self.exporter.outputFileType = AVFileTypeQuickTimeMovie;
    
    [self.exporter exportAsynchronouslyWithCompletionHandler:^
     {
         dispatch_async(dispatch_get_main_queue(), ^{
             //Call when finished
             block(exportUrl);
         });
     }];

}

- (UIImageOrientation)getVideoOrientationFromAsset:(AVAsset *)asset
{
    AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    CGSize size = [videoTrack naturalSize];
    CGAffineTransform txf = [videoTrack preferredTransform];

    if (size.width == txf.tx && size.height == txf.ty)
        return UIImageOrientationLeft; //return UIInterfaceOrientationLandscapeLeft;
    else if (txf.tx == 0 && txf.ty == 0)
        return UIImageOrientationRight; //return UIInterfaceOrientationLandscapeRight;
    else if (txf.tx == 0 && txf.ty == size.width)
        return UIImageOrientationDown; //return UIInterfaceOrientationPortraitUpsideDown;
    else
        return UIImageOrientationUp;  //return UIInterfaceOrientationPortrait;
}






- (void)cropVideoSquare:(NSURL*)outputUrl  withCompletion:(void (^)(NSURL *asset))block {
    
//    //load our movie Asset
//    AVAsset *asset = [AVAsset assetWithURL:outputUrl];
//
//    //create an avassetrack with our asset
//    AVAssetTrack *clipVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
//
//    //create a video composition and preset some settings
//    AVMutableVideoComposition* videoComposition = [AVMutableVideoComposition videoComposition];
//    videoComposition.frameDuration = CMTimeMake(1, 30);
//    //here we are setting its render size to its height x height (Square)
//    videoComposition.renderSize = CGSizeMake(720, 960);
//
//    //create a video instruction
//    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
//    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(60, 30));
//
//    AVMutableVideoCompositionLayerInstruction* transformer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:clipVideoTrack];
//
//    //Here we shift the viewing square up to the TOP of the video so we only see the top
//    CGAffineTransform t1 = CGAffineTransformMakeTranslation(720, 0);
//   // t1.ty= - 0.0;
//    //Use this code if you want the viewing square to be in the middle of the video
//    //CGAffineTransform t1 = CGAffineTransformMakeTranslation(clipVideoTrack.naturalSize.height, -(clipVideoTrack.naturalSize.width - clipVideoTrack.naturalSize.height) /2 );
//
//    //Make sure the square is portrait
//    CGAffineTransform t2 = CGAffineTransformRotate(t1, M_PI_2);
//
//    CGAffineTransform finalTransform = t2;
//    [transformer setTransform:finalTransform atTime:kCMTimeZero];
//
//    //add the transformer layer instructions, then add to video composition
//    instruction.layerInstructions = [NSArray arrayWithObject:transformer];
//    videoComposition.instructions = [NSArray arrayWithObject: instruction];
//
//    //Create an Export Path to store the cropped video
//    NSString * documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
//    NSString *exportPath = [documentsPath stringByAppendingFormat:@"/CroppedVideo.mp4"];
//    NSURL *exportUrl = [NSURL fileURLWithPath:exportPath];
//
//    //Remove any prevouis videos at that path
//    [[NSFileManager defaultManager]  removeItemAtURL:exportUrl error:nil];
//
//    //Export
//    self.exporter = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetHighestQuality] ;
//    self.exporter.videoComposition = videoComposition;
//    self.exporter.outputURL = exportUrl;
//    self.exporter.outputFileType = AVFileTypeQuickTimeMovie;
//
//    [self.exporter exportAsynchronouslyWithCompletionHandler:^
//     {
//         dispatch_async(dispatch_get_main_queue(), ^{
//             //Call when finished
//             block(exportUrl);
//         });
//     }];
    
    
    
    AVAsset *asset = [AVAsset assetWithURL:outputUrl];


    AVAssetTrack *clipVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    AVMutableVideoComposition* videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.frameDuration = CMTimeMake(1, 30);

    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(60, 30));

    CGSize videoSize = [[[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] naturalSize];
    float scaleFactor;

    if (videoSize.width > videoSize.height) {

        scaleFactor = videoSize.height/720;
    }
    else if (videoSize.width == videoSize.height){

        scaleFactor = videoSize.height/720;
    }
    else{
        scaleFactor = videoSize.width/720;
    }



    CGFloat cropOffX = 0;
    CGFloat cropOffY = (170 * self.view.frame.size.height)/ 1112;
    CGFloat cropWidth = 720 *scaleFactor;
    CGFloat cropHeight = 960 *scaleFactor;

    videoComposition.renderSize = CGSizeMake(cropWidth, cropHeight);

    AVMutableVideoCompositionLayerInstruction* transformer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:clipVideoTrack];

    UIImageOrientation videoOrientation = [self getVideoOrientationFromAsset:asset];

    CGAffineTransform t1 = CGAffineTransformIdentity;
    CGAffineTransform t2 = CGAffineTransformIdentity;

    switch (videoOrientation) {
        case UIImageOrientationUp:
            t1 = CGAffineTransformMakeTranslation(clipVideoTrack.naturalSize.height - cropOffX, 0 - cropOffY );
            t2 = CGAffineTransformRotate(t1, M_PI_2 );
            break;
        case UIImageOrientationDown:
            t1 = CGAffineTransformMakeTranslation(0 - cropOffX, clipVideoTrack.naturalSize.width - cropOffY ); // not fixed width is the real height in upside down
            t2 = CGAffineTransformRotate(t1, - M_PI_2 );
            break;
        case UIImageOrientationRight:
            t1 = CGAffineTransformMakeTranslation(0 - cropOffX, 0 - cropOffY );
            t2 = CGAffineTransformRotate(t1, 0 );
            break;
        case UIImageOrientationLeft:
            t1 = CGAffineTransformMakeTranslation(clipVideoTrack.naturalSize.width - cropOffX, clipVideoTrack.naturalSize.height - cropOffY );
            t2 = CGAffineTransformRotate(t1, M_PI  );
            break;
        default:
            NSLog(@"no supported orientation has been found in this video");
            break;
    }

    CGAffineTransform finalTransform = t2;
    [transformer setTransform:finalTransform atTime:kCMTimeZero];

    //add the transformer layer instructions, then add to video composition
    instruction.layerInstructions = [NSArray arrayWithObject:transformer];
    videoComposition.instructions = [NSArray arrayWithObject: instruction];

    NSString *uuid = [NSUUID UUID].UUIDString;
    NSString *outputPath = [NSString stringWithFormat:@"%@%@.mp4", NSTemporaryDirectory(), uuid];
    NSURL *exportUrl = [NSURL fileURLWithPath:outputPath];

//    [[NSFileManager defaultManager]  removeItemAtURL:exportUrl error:nil];


    //Export
    self.exporter = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetHighestQuality] ;
    self.exporter.videoComposition = videoComposition;
    self.exporter.outputURL = exportUrl;
    self.exporter.outputFileType = AVFileTypeQuickTimeMovie;
    
    [self.exporter exportAsynchronouslyWithCompletionHandler:^
     {
         dispatch_async(dispatch_get_main_queue(), ^{
             //Call when finished
             block(exportUrl);
         });
     }];

}

@end

