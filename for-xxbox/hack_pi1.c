#include <stdarg.h>
#include <sys/syscall.h>
#include <syscall.h>
#include <unistd.h>
#include <stddef.h>
#include <stdio.h>


int __snprintf(char *a1, int a2, char * fmt, ...)
{
  va_list varg_r3; // [sp+14h] [bp-4h] BYREF
  va_start(varg_r3, fmt);
  return vsnprintf(a1, a2, fmt, varg_r3);
}

long getrandom(void *buf, size_t buflen, unsigned int flags)
{
	return syscall(SYS_getrandom, buf, buflen,flags);
}

void atexit(int (*f)())
{
	//ignore.
}
