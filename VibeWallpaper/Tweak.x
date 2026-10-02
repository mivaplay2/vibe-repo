#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define DESCRIPTORS_PATH @"/var/mobile/Containers/Data/Application/%@/Library/Application Support/PRBPosterExtensionDataStore/59/Extensions/com.apple.WallpaperKit.CollectionsPoster/descriptors"

NSString *findPosterBoardUUID() {
    NSString *appsDir = @"/var/mobile/Containers/Data/Application";
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *uuids = [fm contentsOfDirectoryAtPath:appsDir error:nil];
    for (NSString *uuid in uuids) {
        NSString *infoPath = [appsDir stringByAppendingPathComponent:[uuid stringByAppendingPathComponent:@"Info.plist"]];
        NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:infoPath];
        if ([info[@"CFBundleIdentifier"] isEqualToString:@"com.apple.PosterBoard"]) {
            return uuid;
        }
    }
    return nil;
}

BOOL injectTendies(NSString *tendiesPath) {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *pbUUID = findPosterBoardUUID();
    if (!pbUUID) {
        NSLog(@"[VibeWallpaper] PosterBoard не найден");
        return NO;
    }
    NSString *descriptorsDir = [NSString stringWithFormat:DESCRIPTORS_PATH, pbUUID];
    NSString *newUUID = [[NSUUID UUID] UUIDString];
    NSString *destPath = [descriptorsDir stringByAppendingPathComponent:newUUID];
    NSError *error = nil;
    [fm createDirectoryAtPath:destPath withIntermediateDirectories:YES attributes:nil error:&error];
    if (error) {
        NSLog(@"[VibeWallpaper] Ошибка: %@", error);
        return NO;
    }
    NSLog(@"[VibeWallpaper] Распаковка в %@", destPath);
    // TODO: распаковка ZIP через SSZipArchive
    return YES;
}

%hook SpringBoard
- (void)applyTendiesWallpaper:(NSString *)path {
    injectTendies(path);
}
%end
