/*
 ***************************************************************************
 * Copyright (C) 2005-2011 UC Mobile Limited. All Rights Reserved
 * File              : FilePathManager.m
 *
 * Description   :
 *
 * Creation       : 2015/06/27
 * Author          : luyc@ucweb.com
 * History         :
 *                 Creation, 2015/06/27, luyc, Create the file
 ***************************************************************************
 **/

#import "FilePathManager.h"
#import "File.h"

@interface FilePathManager ()

@property (nonatomic, copy) NSString *currentPath;
@property (nonatomic, retain) NSMutableArray *fileContentInCurrentDir;

@end


@implementation FilePathManager

- (instancetype)init
{
    if ((self = [super init]))
    {
        _rootDirectory = NSDocumentDirectory;
    }
    
    return self;
}

- (void)dealloc
{
    [_currentPath release];
    _currentPath = nil;
    
    [_fileContentInCurrentDir release];
    _fileContentInCurrentDir = nil;
    
    [super dealloc];
}

- (NSString *)makePath:(NSString *)item
{
    return [self.currentPath stringByAppendingPathComponent:item];
}

- (void)addFileWithName:(NSString *)fileName andFileType:(FileType)fileType
{
    File *file = [[File alloc] init];
    file.fileName = fileName;
    file.filePath = self.currentPath;
    file.fileType = fileType;
    
    if (self.fileContentInCurrentDir == nil)
    {
        self.fileContentInCurrentDir = [NSMutableArray array];
    }
    
    if (file.fileType == FileTypeDirectory)
    {
        [self.fileContentInCurrentDir insertObject:file atIndex:0];
    }
    else
    {
        [self.fileContentInCurrentDir addObject:file];
    }
    
    [file release];
}

- (void)removeFileWithNameFromInteralArray:(NSString *)fileName
{
    for (File *file in self.fileContentInCurrentDir)
    {
        if ([file.fileName isEqualToString:fileName])
        {
            [self.fileContentInCurrentDir removeObject:file];
            break;
        }
    }
}

- (NSString *)currentDirectory
{
    return self.currentPath;
}

- (BOOL)canGoBack
{
    NSString *rootDir = [NSSearchPathForDirectoriesInDomains(self.rootDirectory, NSUserDomainMask, YES) lastObject];
    if ([self.currentPath isEqualToString:rootDir])
    {
        return NO;
    }
    
    return YES;
}

- (void)setWorkDirectory:(NSSearchPathDirectory)workDir
{
    NSString *workDirectoryPath = [NSSearchPathForDirectoriesInDomains(workDir, NSUserDomainMask, YES) lastObject];    
    self.currentPath = workDirectoryPath;
}

- (BOOL)changeToAbsoluteFilePath:(NSString *)filePath
{
    BOOL isDirectory = NO;
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory])
    {
        if (isDirectory)
        {
            self.currentPath = filePath;
            
            /* Every time we change the directory, empty the ls result list */
            if (self.fileContentInCurrentDir != nil)
            {
                [_fileContentInCurrentDir release];
                _fileContentInCurrentDir = nil;
            }
            
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)changeToParentDirectory
{
    if (![self canGoBack])
    {
        return NO;
    }
    
    /* Change from current directory to another */
    NSString *parentPath = [self.currentPath stringByDeletingLastPathComponent];
    return [self changeToAbsoluteFilePath:parentPath];
}

- (BOOL)changeToSubDirectory:(NSString *)subDirectory
{
    NSString *subPath = [self makePath:subDirectory];
    return [self changeToAbsoluteFilePath:subPath];
}

- (NSArray*)fileList
{
    if (self.fileContentInCurrentDir != nil)
    {
        return self.fileContentInCurrentDir;
    }
    
    NSError *error = nil;
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.currentPath error:&error];
    
    if (error != nil)
    {
        return nil;
    }
    
    self.fileContentInCurrentDir = [NSMutableArray array];
    for (NSString *fileName in contents)
    {
        NSString *filePath = [self makePath:fileName];
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];

        /* We have File to copy the content simply here */
        File *file = [[File alloc] init];
        file.fileName = fileName;
        file.filePath = self.currentPath;
        [file loadAttribute:fileAttributes];
        
        if (file.fileType == FileTypeDirectory && self.fileContentInCurrentDir.count != 0)
        {
            [self.fileContentInCurrentDir insertObject:file atIndex:0];
        }
        else
        {
            [self.fileContentInCurrentDir addObject:file];
        }
        
        [file release];
    }
    
    return self.fileContentInCurrentDir;
}

- (BOOL)createDirectory:(NSString *)directoryName
{
    NSString *path = [self makePath:directoryName];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path])    /* Forbid repeated directory name */
    {
        if([[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil])
        {
            [self addFileWithName:directoryName andFileType:FileTypeDirectory];
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)createFile:(NSString *)fileName
{
    NSString *path = [self makePath:fileName];
    if ([[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil])
    {
        [self addFileWithName:fileName andFileType:FileTypeRegular];
        return YES;
    }
    
    return  NO;
}

- (BOOL)removeItem:(NSString *)itemName
{
    NSString *path = [self makePath:itemName];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:path])
    {
        return YES;
    }
    
    if ([[NSFileManager defaultManager] removeItemAtPath:path error:nil])
    {
        [self removeFileWithNameFromInteralArray:itemName];
        return YES;
    }
    
    return NO;
}


@end
