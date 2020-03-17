//
//  TOUtility.h
//  CameraOBJC
//
//  Created by harsh on 13/03/20.
//  Copyright © 2020 harsh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TOUtility : NSObject
typedef void(^AddWatermarkCompletion)(NSURL *assetURL,NSError *error);
typedef void(^ResizeVideoCompletion)(NSURL *new_assetURL,NSError *error);
+(void)addWatermarkToVideo:(NSURL *)assetURL image:(UIImage *)image completion:(AddWatermarkCompletion)block;
+ (NSURL *)applicationDocumentsDirectory;
+(void)resizeVideo:(NSURL*)videoUrl withcompletion:(ResizeVideoCompletion)block;
@end

NS_ASSUME_NONNULL_END
