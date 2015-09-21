/*
 ***************************************************************************
 * Copyright (C) 2005-2011 UC Mobile Limited. All Rights Reserved
 * File              : File.h
 *
 * Description   : A small wrapping to describe the item on file system simply
 *
 * Creation       : 2015/06/27
 * Author          : luyc@ucweb.com
 * History         :
 *                 Creation, 2015/06/27, luyc, Create the file
 ***************************************************************************
 **/

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger , FileType)
{
    FileTypeRegular = 0,
    FileTypeDirectory,
    FileTypeOthers,
};

@interface File : NSObject

@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, assign) FileType fileType;

- (void)loadAttribute:(NSDictionary *)fileAttributes;

@end
