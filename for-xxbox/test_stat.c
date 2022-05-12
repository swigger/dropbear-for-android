#include <sys/stat.h>
#include <stdio.h>

int main(int argc, char ** argv)
{
	if (argc == 2)
	{
	struct stat st = {};
	stat(argv[1], &st);
	printf("%llu\n", st.st_size+0llu);
	}
	return 0;
}
