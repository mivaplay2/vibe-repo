#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <spawn.h>
#import <sys/wait.h>

#define TENDIES_PATH @"/var/mobile/Containers/Shared/AppGroup/06EE6883-02C3-43F5-A789-6A215935F725/File Provider Storage/Kaneki_Ken.tendies"
#define EXTRACT_DIR @"/tmp/vibetendies_extract"
#define LOG_PATH @"/tmp/vibetendies.log"

extern char **environ;

static void vlog(NSString *msg) {
    FILE *f = fopen([LOG_PATH UTF8String], "a");
    if (!f) return;
    NSString *line = [NSString stringWithFormat:@"%@\n", msg];
    fwrite([line UTF8String], 1, [line lengthOfBytesUsingEncoding:NSUTF8StringEncoding], f);
    fflush(f);
    fclose(f);
}

static UIImage *gImg = nil;

static UIImage *extractWallpaperFromTendies(void) {
    // Если .tendies нет — выходим
    if (![[NSFileManager defaultManager] fileExistsAtPath:TENDIES_PATH]) {
        vlog(@"no .tendies");
        return nil;
    }
    
    // Чистим папку
    [[NSFileManager defaultManager] removeItemAtPath:@EXTRACT_DIR error:nil];
    [[NSFileManager defaultManager] createDirectoryAtPath:@EXTRACT_DIR
                              withIntermediateDirectories:YES attributes:nil error:nil];
    
    // Копируем .tendies как .zip
    NSString *zip = @"/tmp/vibe.zip";
    [[NSFileManager defaultManager] removeItemAtPath:zip error:nil];
    [[NSFileManager defaultManager] copyItemAtPath:TENDIES_PATH toPath:zip error:nil];
    
    // Распаковываем
    pid_t pid;
    const char *args[] = {"unzip", "-o", [zip UTF8String], "-d", @EXTRACT_DIR, NULL};
    NSString *unzip = @"/var/jb/usr/bin/unzip";
    if (![[NSFileManager defaultManager] fileExistsAtPath:unzip]) unzip = @"/usr/bin/unzip";
    posix_spawn(&pid, [unzip UTF8String], NULL, NULL, (char *const *)args, environ);
    int status; waitpid(pid, &status, 0);
    if (status != 0) { vlog(@"unzip failed"); return nil; }
    
    // Ищем самый большой файл-картинку
    NSString *bestPath = nil;
    unsigned long long bestSize = 0;
    NSDirectoryEnumerator *en = [[NSFileManager defaultManager] enumeratorAtPath:@EXTRACT_DIR];
    for (NSString *f in en) {
        NSString *e = [[f pathExtension] lowercaseString];
        if ([e isEqualToString:@"png"] || [e isEqualToString:@"jpg"] ||
            [e isEqualToString:@"jpeg"] || [e isEqualToString:@"heic"]) {
            NSString *full = [@EXTRACT_DIR stringByAppendingPathComponent:f];
            NSDictionary *a = [[NSFileManager defaultManager] attributesOfItemAtPath:full error:nil];
            unsigned long long s = [a fileSize];
            if (s > bestSize) { bestSize = s; bestPath = full; }
        }
    }
    if (!bestPath) { vlog(@"no image in .tendies"); return nil; }
    vlog([NSString stringWithFormat:@"picked: %@ (%llu KB)", [bestPath lastPathComponent], bestSize/1024]);
    
    return [UIImage imageWithContentsOfFile:bestPath];
}

static void applyOverlay(void) {
    if (!gImg) gImg = extractWallpaperFromTendies();
    if (!gImg) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        int added = 0;
        for (UIWindow *w in [UIApplication sharedApplication].windows) {
            if (w.windowLevel > UIWindowLevelNormal) continue;
            if (w.hidden) continue;
            if (w.bounds.size.width < 200) continue;
            
            // Удаляем старый overlay
            for (UIView *sub in w.subviews) {
                if (sub.tag == 777777) [sub removeFromSuperview];
            }
            
            // Находим подходящее место — над wallpaper, но под иконками
            // Ищем SBFWallpaperView в поддереве и добавляем в него
            UIView *wallpaper = nil;
            for (UIView *v in w.subviews) {
                NSString *cls = NSStringFromClass([v class]);
                if ([cls containsString:@"Wallpaper"]) { wallpaper = v; break; }
            }
            
            UIImageView *iv = [[UIImageView alloc] initWithFrame:w.bounds];
            iv.image = gImg;
            iv.contentMode = UIViewContentModeScaleAspectFill;
            iv.clipsToBounds = YES;
            iv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            iv.tag = 777777;
            iv.userInteractionEnabled = NO;
            
            if (wallpaper) {
                [wallpaper addSubview:iv];  // поверх wallpaper view
                vlog(@"added to wallpaper view");
            } else {
                // Если не нашли — добавляем поверх всего, но с высоким level
                [w addSubview:iv];
                vlog(@"added to main window");
            }
            added++;
        }
        vlog([NSString stringWithFormat:@"added to %d windows", added]);
    });
}

__attribute__((constructor))
static void init(void) {
    vlog(@"=== CONSTRUCTOR ===");
    for (NSNumber *d in @[@3, @5, @10, @20]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)([d doubleValue] * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            applyOverlay();
        });
    }
}
