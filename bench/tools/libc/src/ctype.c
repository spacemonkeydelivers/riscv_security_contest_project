
int isalpha(int c) {
    return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z');
}

int isdigit(int c) {
    if (c >= '0' && c <= '9')
        return c;
    else
        return 0;
}

int isxdigit(int c) {
    return ((c >= '0') && (c <= '9')) || ((c >= 'A') && (c <= 'F')) || ((c >= 'a') && (c <= 'f'));
}

int isspace(int c) {
    return ((c == ' ') || (c == '\t'));
}

int tolower(int c) {
    if (!isalpha(c))
        return c;
    return (c >= 'A' && c <= 'Z') ? c - 'A' : c;
}
