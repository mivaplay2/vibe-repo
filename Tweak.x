#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#define WALLPAPER_PATH @"/var/mobile/Library/Application Support/VibeTendies/wallpaper.png"

@interface SBFWallpaperView : UIView
@end

static UIImage *loadWallpaper(void) {
    if (![[NSFileManager defaultManager] fileExistsAtPath:WALLPAPER_PATH]) {
        NSLog(@"[VibeTendies] No file");
        return nil;
    }
    return [UIImage imageWithContentsOfFile:WALLPAPER_PATH];
}

static void attachImage(UIView *host, NSString *tag) {
    if (!host) return;
    UIImage *img = loadWallpaper();
    if (!img) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        for (UIView *sub in host.subviews) {
            if (sub.tag == 999999) [sub removeFromSuperview];
        }
        UIImageView *iv = [[UIImageView alloc] initWithFrame:host.bounds];
        iv.image = img;
        iv.contentMode = UIViewContentModeScaleAspectFill;
        iv.clipsToBounds = YES;
        iv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        iv.tag = 999999;
        iv.userInteractionEnabled = NO;
        [host insertSubview:iv atIndex:0];
        NSLog(@"[VibeTendies] Attached (%@)", tag);
    });
}

%hook SBFWallpaperView
- (void)didMoveToWindow {
    %orig;
    attachImage(self, @"wallpaper");
}
%end
