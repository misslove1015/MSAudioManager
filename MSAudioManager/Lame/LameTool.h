//
//  LameTool.h
//  LameTool
//
//  Created by zhoushaowen on 2017/2/16.
//  Copyright © 2017年 Yidu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LameTool : NSObject

+ (void)toMP3WithSourcePath:(NSString *)sourcePath
                     toPath:(NSString *)toPath
                    success:(void(^)(NSString *path))successBlock;

@end
