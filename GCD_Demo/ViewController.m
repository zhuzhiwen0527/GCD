//
//  ViewController.m
//  GCD_Demo
//
//  Created by zzw on 2017/4/27.
//  Copyright © 2017年 zzw. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //串行队列
    [self serialQueue];
    
    //并发队列
    [self concurrentQueue];
    
    //全局并发队列
    [self globalQueue];
    
    //dispatch_set_target_queue
    
  /*  这个函数有两个作用：
    
    1.改变队列的优先级。
    2.防止多个串行队列的并发执行。
   */
    [self changePriority];
    
    //延时
    [self afterQueue];
    
    //预处理任务需要一个接一个的执行：
    [self serialGlobalQueue];
    
    //dispatch_barrier_async
    [self barrier];
    
    //死锁
//    [self dispatch_sync_3];
    
    
    //dispatch_apply
    [self dispatch_apply_1];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
   
}

//串行队列
- (void)serialQueue{

    //通过dispatch_queue_create函数可以创建队列，第一个函数为队列的名称，第二个参数是NULL和DISPATCH_QUEUE_SERIAL时，返回的队列就是串行队列。
    dispatch_queue_t queue = dispatch_queue_create("serial", NULL);
    for (NSInteger i = 0; i < 5; i++) {
        dispatch_async(queue, ^{
            NSLog(@"task index %ld in serial queue",i);
        });
    }

}
//并发队列
- (void)concurrentQueue{
    
    //扩展知识：iOS和OSX基于Dispatch Queue中的处理数，CPU核数，以及CPU负荷等当前系统的状态来决定Concurrent Dispatch Queue中并发处理的任务数。
    
    dispatch_queue_t queue = dispatch_queue_create("concurrent", DISPATCH_QUEUE_CONCURRENT);
    for (NSInteger i = 0; i < 5; i++) {
        dispatch_async(queue, ^{
            NSLog(@"task index %ld in concurrent queue",i);
        });
    }
    /*
     挂起函数调用后对已经执行的处理没有影响，但是追加到队列中但是尚未执行的处理会在此之后停止执行。
     */
    dispatch_suspend(queue);
    dispatch_resume(queue);
    
  
    
}

//全局并发队列
- (void)globalQueue{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        //下载图片。。
        
        
        //回到主线程刷新界面
        dispatch_async(dispatch_get_main_queue(), ^{
            
        });
        
        
    });
}

//生成一个后台的串行队列
- (void)changePriority{


    dispatch_queue_t queue = dispatch_queue_create("queue", NULL);
    
    dispatch_queue_t BQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    
    //第一个参数：需要改变优先级的队列；
    //第二个参数：目标队列
    dispatch_set_target_queue(queue, BQueue);
    
    
    
    //防止多个串行队列的并发执行
    
//    
//    NSMutableArray *array = [NSMutableArray array];
//    for (NSInteger index = 0; index < 5; index ++) {
//        //5个串行队列
//        dispatch_queue_t serial_queue = dispatch_queue_create("serial_queue", NULL);
//        [array addObject:serial_queue];
//    }
//    
//    [array enumerateObjectsUsingBlock:^(dispatch_queue_t queue, NSUInteger idx, BOOL * _Nonnull stop) {
//        
//        dispatch_async(queue, ^{
//            NSLog(@"任务%ld",idx);
//        });
//    }];
    
    //多个串行队列，设置了target queue
    NSMutableArray * array = [NSMutableArray array];
    dispatch_queue_t serial_queue_target = dispatch_queue_create("queue_target", NULL);
    
    for (NSInteger index = 0; index < 5; index ++) {
        
        //分别给每个队列设置相同的target queue
        dispatch_queue_t serial_queue = dispatch_queue_create("serial_queue", NULL);
        dispatch_set_target_queue(serial_queue, serial_queue_target);
        [array addObject:serial_queue];
    }
    
    [array enumerateObjectsUsingBlock:^(dispatch_queue_t queue, NSUInteger idx, BOOL * _Nonnull stop) {
        
        dispatch_async(queue, ^{
            NSLog(@"任务%ld",idx);
        });
    }];
}


//dispatch_after

- (void)afterQueue{

    
    /*注意：不是在3秒之后处理任务，准确来说是3秒之后追加到队列。所以说，如果这个线程的runloop执行1/60秒一次，那么这个block最快会在3秒后执行，最慢会在（3+1/60）秒后执行。而且，如果这个队列本身还有延迟，那么这个block的延迟执行时间会更多。*/
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"三秒后追加到队列");
    });


}
//预处理任务需要一个接一个的执行：
- (void)serialGlobalQueue{

    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    for (NSInteger index = 0; index < 5; index ++) {
        dispatch_group_async(group, queue, ^{
            NSLog(@"任务%ld",index);
        });
    }
    
    dispatch_group_notify(group, queue, ^{
        NSLog(@"最后的任务");
    });

}
//dispatch_barrier_async

- (void)barrier{


    dispatch_queue_t meetingQueue = dispatch_queue_create("com.meeting.queue", DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_async(meetingQueue, ^{
        NSLog(@"总裁查看合同");
    });
    
    dispatch_async(meetingQueue, ^{
        NSLog(@"董事1查看合同");
    });
    
    dispatch_async(meetingQueue, ^{
        NSLog(@"董事2查看合同");
    });
    
    dispatch_async(meetingQueue, ^{
        NSLog(@"董事3查看合同");
    });
    
    dispatch_barrier_async(meetingQueue, ^{
        NSLog(@"总裁签字");
    });
    
    dispatch_async(meetingQueue, ^{
        NSLog(@"总裁审核合同");
    });
    
    dispatch_async(meetingQueue, ^{
        NSLog(@"董事1审核合同");
    });
    
    dispatch_async(meetingQueue, ^{
        NSLog(@"董事2审核合同");
    });
    
    dispatch_async(meetingQueue, ^{
        NSLog(@"董事3审核合同");
    });
    
    /*
     在这里，我们可以将meetingQueue看成是会议的时间线。总裁签字这个行为相当于写操作，其他都相当于读操作。使用dispatch_barrier_async以后，之前的所有并发任务都会被dispatch_barrier_async里的任务拦截掉，就像函数名称里的“栅栏”一样。
     因此，使用Concurrent Dispatch Queue 和 dispatch_barrier_async 函数可以实现高效率的数据库访问和文件访问。
     */
}
//死锁
- (void)dispatch_sync_3
{
    NSLog(@"任务1");
    dispatch_queue_t queue = dispatch_get_main_queue();
    dispatch_sync(queue, ^{
        
        NSLog(@"任务2");
    });
    
    NSLog(@"任务3");
    /*
     上面的代码只能输出任务1，并形成死锁。
     因为任务2被追加到了主队列的最后，所以它需要等待任务3执行完成。
     但又因为是同步函数，任务3也在等待任务2执行完成。
     二者互相等待，所以形成了死锁。
     */

}


//dispatch_apply
- (void)dispatch_apply_1
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_apply(10, queue, ^(size_t index) {
        NSLog(@"%ld",index);
    });
    NSLog(@"完毕");
}



@end
