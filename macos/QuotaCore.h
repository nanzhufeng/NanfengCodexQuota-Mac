#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
void *quota_open(const char *path, const char *cli);
char *quota_error(void);
void quota_string_free(char *value);
char *quota_snapshot(void *core);
void quota_refresh(void *core);
bool quota_configure(void *core, const char *json);
void quota_close(void *core);
size_t quota_render(int32_t remaining, uint32_t scale, uint8_t *output, size_t capacity);
