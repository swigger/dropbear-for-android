#include <stdarg.h>

extern int vsnprintf(char *a1, int a2, char *fmt, va_list ap);

int __snprintf(char *a1, int a2, char * fmt, ...)
{
  va_list varg_r3; // [sp+14h] [bp-4h] BYREF
  va_start(varg_r3, fmt);
  return vsnprintf(a1, a2, fmt, varg_r3);
}

