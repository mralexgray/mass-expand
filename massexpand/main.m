#import <Foundation/Foundation.h>
#include <sys/stat.h>
#include <dirent.h>

static BOOL isDirectory(const char* inPath, const char* inItem);
static NSArray* getAllFilesWithinPathRecursive(NSString* path);


int main (int argc, const char * argv[])
{
    @autoreleasepool
    {
        BOOL writeToFiles = NO;
        
        if (argc < 2)
        {
            printf("No target directory specified, aborting.\n");
            return 1;
        }
        
        for (int argi = 2; argi < argc; argi++)
        {
            const char* arg = argv[argi];
            
            if (strcmp(arg, "--OVERWRITE") == 0)
            {
                writeToFiles = YES;
            }
            else
            {
                printf("Unknown paramater %s, aborting.\n", arg);
                return 1;
            }
        }
        
        NSString* targetPath = [NSString stringWithUTF8String:argv[1]];
        
        NSArray* potentialFilepaths = getAllFilesWithinPathRecursive(targetPath);
        
        if (potentialFilepaths == nil)
        {
            printf("Unable to read from target directory, aborting.\nTarget directory was %s\n", targetPath.UTF8String);
            
            return 1;
        }
        
        for (NSString* filepath in potentialFilepaths)
		{
			NSString* extension = [filepath pathExtension];
			
			if ([extension isEqualToString:@"m"] ||
				[extension isEqualToString:@"mm"] || 
				[extension isEqualToString:@"h"] || 
				[extension isEqualToString:@"c"] || 
                [extension isEqualToString:@"cpp"])
			{
                if (writeToFiles)
                {
                    {
                        NSString* systemString = [NSString stringWithFormat:@"expand -t 4 \"%@\" > tmp-expanded-output", filepath, filepath];
                        NSLog(@"systemString %@", systemString);
                        system(systemString.UTF8String);
                    }
                    
                    {
                        NSString* systemString = [NSString stringWithFormat:@"mv -f tmp-expanded-output %@", filepath];
                        NSLog(@"systemString %@", systemString);
                        system(systemString.UTF8String);
                    }
                }
                else
                {
                    NSString* systemString = [NSString stringWithFormat:@"expand -t 4 \"%@\"", filepath];
                    system(systemString.UTF8String);
                }
			}
		}
        
        system("rm tmp-expanded-output");
    }
    
    return 0;
}




static BOOL isDirectory(const char* inPath, const char* inItem)
{
	DIR *pdir = opendir(inPath);
	
	if (pdir)
	{
		BOOL done = NO;
		
		while (!done)
		{
			struct dirent *item = readdir(pdir);
			
			if (item != 0)
			{
				if (item->d_name == inItem)
				{
					switch(item->d_type)
					{
						case DT_REG:
							closedir(pdir);
							return NO;
							break;
							
						default: 
							closedir(pdir);
							return YES; 
							break;
					}
				}
			}
			else 
			{
				done = YES;
			}
		}			
	}			
	else
	{
		return NO;
	}
	
	return NO;
}

static NSArray* getAllFilesWithinPathRecursive(NSString* path)
{
	NSMutableArray* filepaths = [[NSMutableArray new] autorelease];
	
	if (path.length == 0)
	{
		return filepaths;
	}
	
	DIR *pdir = opendir([path UTF8String]);
	
	if (pdir)
	{
		while (true)
		{
			struct dirent *item = readdir(pdir);
			
			if (item != NULL)
			{ 	
				const char* itemName = item->d_name;
				
				if (itemName[0] != '.')
				{
					NSString* itemPath = [NSString stringWithFormat:@"%@/%s", path, itemName];
					
					BOOL isDirectory = NO;
					
					[[NSFileManager defaultManager] fileExistsAtPath:itemPath
														 isDirectory:&isDirectory];
					
					if (isDirectory)
					{
						NSArray* paths = getAllFilesWithinPathRecursive(itemPath);
						
						[filepaths addObjectsFromArray:paths];
					}
					else
					{
						[filepaths addObject:itemPath];
					}
				}
			}
			else 
			{
				break;
			}
		}
		
		closedir(pdir);
		
		return filepaths;
	}
	else
	{
		return nil;
	}
}