#include <stdlib.h>

typedef void (*progress_callback_t)(long long id, double progress, long long processed, long long total, int status, char* error);

void callProgressCallback(void* callback, long long id, double progress, long long processed, long long total, int status, char* error) {
    if (callback != NULL) {
        ((progress_callback_t)callback)(id, progress, processed, total, status, error);
    }
}
