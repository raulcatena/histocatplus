//
//  memusage.m
//  3DIMC
//
//  Created by Raul Catena on 1/31/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "memusage.h"
#import <sys/sysctl.h>
#import <mach/host_info.h>
#import <mach/mach_host.h>
#import <mach/task_info.h>
#import <mach/task.h>

@implementation memusage

+(NSInteger)memUsage:(MEM_INFO)memInfo{
    int mib[6];
    mib[0] = CTL_HW;
    mib[1] = HW_PAGESIZE;
    
    int pagesize;
    size_t length;
    length = sizeof (pagesize);
    if (sysctl (mib, 2, &pagesize, &length, NULL, 0) < 0)
    {
        fprintf (stderr, "getting page size");
    }
    
    mach_msg_type_number_t count = HOST_VM_INFO_COUNT;
    
    vm_statistics_data_t vmstat;
    if (host_statistics (mach_host_self (), HOST_VM_INFO, (host_info_t) &vmstat, &count) != KERN_SUCCESS)
    {
        fprintf (stderr, "Failed to get VM statistics.");
    }
    
    double total = vmstat.wire_count + vmstat.active_count + vmstat.inactive_count + vmstat.free_count;
    double wired = vmstat.wire_count / total;
    double active = vmstat.active_count / total;
    double inactive = vmstat.inactive_count / total;
    double free = vmstat.free_count / total;
    
    task_basic_info_64_data_t info;
    unsigned size = sizeof (info);
    task_info (mach_task_self (), TASK_BASIC_INFO_64, (task_info_t) &info, &size);
    
    double unit = 1024 * 1024 * 1024;
    
    NSString *memDiagnostics = [NSString stringWithFormat: @" %3.1f GB FREE %3.1f GB FREE + Inactive %f GB resident size", vmstat.free_count * pagesize / unit, (vmstat.free_count + vmstat.inactive_count) * pagesize / unit, info.resident_size / (unit)];
    
    NSLog(@"Mem %@", memDiagnostics);
    NSLog(@"Total %.2f", total * pagesize/unit);
    NSLog(@"Wired %.2f %.2f%%", total * wired * pagesize/unit, wired * 100);
    NSLog(@"Active %.2f %.2f%%", total * active * pagesize/unit, active * 100);
    NSLog(@"Inactive %.2f %.2f%%", total * inactive * pagesize/unit, inactive * 100);
    NSLog(@"Free %.2f %.2f%%", total * free * pagesize/unit, free * 100);
    NSLog(@"Page size %i", pagesize);
    
    switch (memInfo) {
        case MEM_INFO_TOTAL:
            return total * pagesize;
        case MEM_INFO_WIRED:
            return total * wired * pagesize;
        case MEM_INFO_ACTIVE:
            return total * active * pagesize;
        case MEM_INFO_INACTIVE:
            return total * inactive * pagesize;
        case MEM_INFO_FREE:
            return total * free * pagesize;
            
        default:
            break;
    }
    return 0;
}

+(float)toKB:(NSInteger)bytes{
    return bytes/pow(2.0f, 10.0f);
}

+(float)toMB:(NSInteger)bytes{
    return bytes/pow(2.0f, 20.0f);
}

+(float)toGB:(NSInteger)bytes{
    return bytes/pow(2.0f, 30.0f);
}

@end
