/*
 ***************************************************************************
 * Copyright (C) 2005-2011 UC Mobile Limited. All Rights Reserved
 * File              : File.m
 *
 * Description    :
 *
 * Creation       : 2015/06/27
 * Author          : luyc@ucweb.com
 * History         :
 *                 Creation, 2015/06/27, luyc, Create the file
 ***************************************************************************
 **/


#import "File.h"

@implementation File

- (void)dealloc
{
    [_fileName release];
    _fileName = nil;
    
    [_filePath release];
    _filePath = nil;
    
    [super dealloc];
}

- (void)loadAttribute:(NSDictionary *)fileAttributes
{
    NSString *fileType = fileAttributes[NSFileType];
    if ([fileType isEqualToString:NSFileTypeDirectory])
    {
        self.fileType = FileTypeDirectory;
    }
    else if ([fileType isEqualToString:NSFileTypeRegular])
    {
        self.fileType = FileTypeRegular;
    }
    else
    {
        self.fileType = FileTypeOthers;
    }
}

@end