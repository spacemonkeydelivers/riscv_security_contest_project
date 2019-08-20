#include <stdlib.h>
#include <stdio.h>

int fib(int n)
{
    if (n > 1) {
        int result =  (fib(n-1) + fib(n-2));
        printf("fib(%d) = %d\n", n, result);
        return result;
    }
    printf("fib(%d) = %d\n", n, n);
    return n;
}

int main()
{
    int x = 6;
    int result = fib(x);
    const int EXPECTED = 8;
    if (result != EXPECTED) {
        printf("FAILURE: fib(%d) is expected to be %d, got %d", x, EXPECTED, result);
        exit(EXIT_FAILURE);
    }
    printf("fib(%d) = %d\n", x, result);
    return EXIT_SUCCESS;
}
