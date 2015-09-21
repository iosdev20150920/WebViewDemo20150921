/*
 ***************************************************************************
 * Copyright (C) 2005-2011 UC Mobile Limited. All Rights Reserved
 * File              : FilePathManager.h
 *
 * Description   : FilePathManager helps to surfing the file system, simply like command on terminal cd, rm, mkdir and ls
 *
 * Creation       : 2015/06/27
 * Author          : luyc@ucweb.com
 * History         :
 *                 Creation, 2015/06/27, luyc, Create the file
 ***************************************************************************
 **/


#import <Foundation/Foundation.h>

@interface FilePathManager : NSObject

@property (nonatomic, assign) NSSearchPathDirectory rootDirectory;

- (NSString *)currentDirectory;

- (BOOL)canGoBack;

- (void)setWorkDirectory:(NSSearchPathDirectory)workDir;  // Go to some particular paths
- (BOOL)changeToAbsoluteFilePath:(NSString *)filePath;  // Go to the specific path

/* Go backward or go forward */
- (BOOL)changeToSubDirectory:(NSString *)subDirectory;
- (BOOL)changeToParentDirectory;

/* list the contents of current directory, the instance in returned array is Files */
- (NSArray *)fileList;

/* Creation and deleting file or directory under current directory */
- (BOOL)createDirectory:(NSString *)directoryName;
- (BOOL)createFile:(NSString *)fileName;

- (BOOL)removeItem:(NSString*)itemName;


@end
