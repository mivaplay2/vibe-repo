#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#define WALLPAPER_PATH @"/var/mobile/Library/Application Support/VibeTendies/wallpaper.png"
#define LOG_PATH @"/tmp/vibetendies.log"

static void vlog(NSString *msg) {
    FILE *f = fopen([LOG_PATH UTF8String], "a");
    if (!f) return;
    NSString *line = [NSString stringWithFormat:@"%@\n", msg];
    fwrite([line UTF8String], 1, [line lengthOfBytesUsingEncoding:NSUTF8StringEncoding], f);
    fflush(f);
    fclose(f);
}

static void doPaint(void) {
    NSArray *windows = nil;
    for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if ([scene isKindOfClass:[UIWindowScene class]]) {
            UIWindowScene *ws = (UIWindowScene *)scene;
            if (ws.windows.count > 0) { windows = ws.windows; break; }
        }
    }
    if (windows.count == 0) { vlog(@"no windows"); return; }
    
    UIWindow *host = windows.firstObject;
    if (![[NSFileManager defaultManager] fileExistsAtPath:WALLPAPER_PATH]) {
        vlog(@"no wallpaper file"); return;
    }
    UIImage *img = [UIImage imageWithContentsOfFile:WALLPAPER_PATH];
    if (!img) { vlog(@"image load failed"); return; }
    
    for (UIView *v in host.subviews) {
        if (v.tag == 777777) [v removeFromSuperview];
    }
    UIImageView *iv = [[UIImageView alloc] initWithFrame:host.bounds];
    iv.image = img;
    iv.contentMode = UIViewContentModeScaleAspectFill;
    iv.clipsToBounds = YES;
    iv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    iv.tag = 777777;
    iv.userInteractionEnabled = NO;
    [host insertSubview:iv atIndex:0];
    vlog(@"IMAGE ADDED");
}

__attribute__((constructor))
static void vibinit(void) {
    vlog(@"=== CONSTRUCTOR ===");
    NSArray *delays = @[@3, @8, @15, @30];
    for (NSNumber *d in delays) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)([d doubleValue] * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            doPaint();
        });
    }
}
