#import <UIKit/UIKit.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import <spawn.h>

extern char **environ;

@interface VibeTendiesController : PSListController <UIDocumentPickerDelegate>
@end

@implementation VibeTendiesController

- (NSArray *)specifiers {
    if (!_specifiers) {
        NSMutableArray *specs = [NSMutableArray new];
        
        PSSpecifier *group = [PSSpecifier groupSpecifierWithName:@"VibeTendies"];
        [group setProperty:@"Импортируйте .tendies файл для наложения обоев" forKey:@"footerText"];
        [specs addObject:group];
        
        PSSpecifier *selectBtn = [PSSpecifier preferenceSpecifierNamed:@"Импортировать .tendies"
                                                                target:self
                                                                   set:nil
                                                                   get:nil
                                                                detail:nil
                                                                  cell:PSButtonCell
                                                                  edit:nil];
        [selectBtn setProperty:NSStringFromSelector(@selector(selectFile)) forKey:@"action"];
        [specs addObject:selectBtn];
        
        PSSpecifier *respringBtn = [PSSpecifier preferenceSpecifierNamed:@"Сделать Respring"
                                                                target:self
                                                                   set:nil
                                                                   get:nil
                                                                detail:nil
                                                                  cell:PSButtonCell
                                                                  edit:nil];
        [respringBtn setProperty:NSStringFromSelector(@selector(doRespring)) forKey:@"action"];
        [specs addObject:respringBtn];
        
        _specifiers = specs;
    }
    return _specifiers;
}

- (void)selectFile {
    UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc]
        initForOpeningContentTypes:@[[UTType typeWithIdentifier:@"public.data"]]];
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller
    didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    NSURL *url = urls.firstObject;
    if (!url) return;
    
    NSString *dir = @"/var/mobile/Library/Application Support/VibeTendies";
    [[NSFileManager defaultManager] createDirectoryAtPath:dir
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];
    
    // Копируем .tendies
    NSString *destPath = [dir stringByAppendingPathComponent:@"wallpaper.tendies"];
    [[NSFileManager defaultManager] removeItemAtPath:destPath error:nil];
    [[NSFileManager defaultManager] copyItemAtPath:url.path toPath:destPath error:nil];
    
    // Распаковываем ZIP
    [self unzipTendies:destPath toDir:dir];
    
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"VibeTendies"
        message:@"Файл импортирован! Сделайте Respring."
        preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Ок" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)unzipTendies:(NSString *)zipPath toDir:(NSString *)dir {
    // Простая распаковка через unzip (если установлен)
    pid_t pid;
    const char *args[] = {"unzip", "-o", [zipPath UTF8String], "-d", [dir UTF8String], NULL};
    posix_spawn(&pid, "/usr/bin/unzip", NULL, NULL, (char *const *)args, environ);
}

- (void)doRespring {
    pid_t pid;
    const char *args[] = {"killall", "-9", "SpringBoard", NULL};
    posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char *const *)args, environ);
}

@end
