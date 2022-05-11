struct stat;

int __xstat (int __ver,
             const char *__filename,
             struct stat *__stat_buf);

int __lxstat (int __ver,
              const char *__filename,
              struct stat *__stat_buf);
int __fxstat (int __ver,
              int __filedesc,
              struct stat *__stat_buf);

int fcntl(int fildes, int cmd, ...);


int stat64(const char *__restrict __file, struct stat * a)
{
	return __xstat(3,__file, a);
}
int fstat64(int f, struct stat*a)
{
	return __fxstat(3, f, a);
}

int fcntl64(int a, int b, int c)
{
	return fcntl(a,b,c);
}

int __aeabi_read_tp()
{
	return 0;
}

extern void * memset(void* , int , long);

void explicit_bzero(void *b, long len)
{
	memset(b, 0, len);
}

void __explicit_bzero_chk(void * b, long len)
	__attribute__((weak, alias("explicit_bzero")));


extern int open(char* a, int b, int c);
extern int close(int a);

int __open_nocancel(char * a, int b, int c)
{
	return open(a,b,c);
}
int __close_nocancel(int a)
{
	return close(a);
}

extern long read(int fildes, void *buf, long nbyte);
long __read_nocancel(int a, void* b, long c)
{
	return read(a,b,c);
}

