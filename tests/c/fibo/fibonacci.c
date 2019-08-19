#include <stdlib.h>
#include <stdio.h>

int fib(int n)
{
    if (n > 1)
        return (fib(n-1) + fib(n-2));
    return n;
}

int main()
{
    int x = 10;
    int result = fib(x);
    if (result != 55) {
        exit(EXIT_FAILURE);
    }
    printf("fib(%d) = %d", x, result);
    return EXIT_SUCCESS;
}
