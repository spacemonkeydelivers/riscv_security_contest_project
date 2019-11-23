#include <stdlib.h>
#include <string.h>

int main() {
    char* a = "abcde";
    char b = 'f';
    char c = 'a';
    
    if (strchr(a, b))
        return EXIT_FAILURE;
    if (!strchr(a,c ))
        return EXIT_FAILURE;

    return EXIT_SUCCESS;
}
