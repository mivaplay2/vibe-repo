#import "RootListController.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import <spawn.h>
#import <sys/wait.h>

extern char **environ;

@implementation RootListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        NSMutableArray *specs = [NSMutableArray new];
        
        PSSpecifier *g1 = [PSSpecifier groupSpecifierWithName:@"VibeTendies"];
        [g1 setProperty:@"Выберите картинку или .tendies файл" forKey:@"footerText"];
        [specs addObject:g1];
        
        PSSpecifier *btn1 = [PSSpecifier preferenceSpecifierNamed:@"Выбрать картинку (PNG/JPG)"
                                                           target:self
                                                              set:nil
                                                              get:nil
                                                           detail:nil
                                                             cell:PSButtonCell
                                                             edit:nil];
        btn1->action = @selector(selectImage);
        [specs addObject:btn1];
        
        PSSpecifier *btn2 = [PSSpecifier preferenceSpecifierNamed:@"Импорт .tendies"
                                                           target:self
                                                              set:nil
                                                              get:nil
                                                           detail:nil
                                                             cell:PSButtonCell
                                                             edit:nil];
        btn2->action = @selector(selectTendies);
        [specs addObject:btn2];
        
        PSSpecifier *g2 = [PSSpecifier groupSpecifierWithName:@""];
        [specs addObject:g2];
        
        PSSpecifier *btn3 = [PSSpecifier preferenceSpecifierNamed:@"Перезапустить SpringBoard"
                                                           target:self
                                                              set:nil
                                                              get:nil
                                                           detail:nil
                                                             cell:PSButtonCell
                                                             edit:nil];
        btn3->action = @selector(doRespring);
        [specs addObject:btn3];
        
        _specifiers = specs;
    }
    return _specifiers;
}

- (void)selectImage {
    NSLog(@"[VibeTendies] selectImage");
    UIDocumentPickerViewController *p = [[UIDocumentPickerViewController alloc]
        initForOpeningContentTypes:@[UTTypeImage]];
    p.delegate = self;
    [self presentViewController:p animated:YES completion:nil];
}

- (void)selectTendies {
    NSLog(@"[VibeTendies] selectTendies");
    UIDocumentPickerViewController *p = [[UIDocumentPickerViewController alloc]
        initForOpeningContentTypes:@[UTTypeData]];
    p.delegate = self;
    [self presentViewController:p animated:YES completion:nil];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller
    didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    NSURL *u = urls.firstObject;
    if (!u) return;
    
    NSString *dir = @"/var/mobile/Library/Application Support/VibeTendies";
    [[NSFileManager defaultManager] createDirectoryAtPath:dir
                              withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *dst = [dir stringByAppendingPathComponent:@"wallpaper.png"];
    NSString *ext = [[u.path pathExtension] lowercaseString];
    
    if ([ext isEqualToString:@"tendies"]) {
        [self importTendies:u.path to:dst];
    } else {
        [[NSFileManager defaultManager] removeItemAtPath:dst error:nil];
        NSError *err = nil;
        [[NSFileManager defaultManager] copyItemAtPath:u.path toPath:dst error:&err];
        [self showAlert:err ? err.localizedDescription : @"Сохранено! Жми Respring."];
    }
}

- (void)importTendies:(NSString *)src to:(NSString *)dst {
    NSString *tmpDir = [NSTemporaryDirectory() stringByAppendingPathComponent:@"tendies_extract"];
    [[NSFileManager defaultManager] removeItemAtPath:tmpDir error:nil];
    [[NSFileManager defaultManager] createDirectoryAtPath:tmpDir
                              withIntermediateDirectories:YES attributes:nil error:nil];
    
    pid_t pid;
    const char *args[] = {"unzip", "-o", [src UTF8String], "-d", [tmpDir UTF8String], NULL};
    posix_spawn(&pid, "/usr/bin/unzip", NULL, NULL, (char *const *)args, environ);
    int status; waitpid(pid, &status, 0);
    
    if (status != 0) { [self showAlert:@"Ошибка распаковки .tendies"]; return; }
    
    NSString *found = nil;
    NSDirectoryEnumerator *en = [[NSFileManager defaultManager] enumeratorAtPath:tmpDir];
    for (NSString *f in en) {
        NSString *e = [[f pathExtension] lowercaseString];
        if ([e isEqualToString:@"png"] || [e isEqualToString:@"jpg"] || [e isEqualToString:@"jpeg"]) {
            found = [tmpDir stringByAppendingPathComponent:f];
            break;
        }
    }
    if (!found) {
        [self showAlert:@"В .tendies нет PNG/JPG. Это дескриптор, не картинка."];
        return;
    }
    
    [[NSFileManager defaultManager] removeItemAtPath:dst error:nil];
    NSError *err = nil;
    [[NSFileManager defaultManager] copyItemAtPath:found toPath:dst error:&err];
    [self showAlert:err ? err.localizedDescription : @"Картинка из .tendies сохранена! Жми Respring."];
}

- (void)showAlert:(NSString *)msg {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *a = [UIAlertController alertControllerWithTitle:@"VibeTendies"
                                                                  message:msg
                                                           preferredStyle:UIAlertControllerStyleAlert];
        [a addAction:[UIAlertAction actionWithTitle:@"Ок" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:a animated:YES completion:nil];
    });
}

- (void)doRespring {
    NSString *k = @"/var/jb/usr/bin/killall";
    if (![[NSFileManager defaultManager] fileExistsAtPath:k]) k = @"/usr/bin/killall";
    pid_t pid;
    const char *args[] = {"killall", "-9", "SpringBoard", NULL};
    posix_spawn(&pid, [k UTF8String], NULL, NULL, (char *const *)args, environ);
}

@end
