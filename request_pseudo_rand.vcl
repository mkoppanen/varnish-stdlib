C{
#include <errno.h>
#include <limits.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#define STD_RAND_MAX_DEFAULT 10

__attribute__((constructor)) void std_init_prng()
{
    srand(time(NULL));
}
}C

/**
 *   {{{ sub std_request_pseudo_rand | vcl_recv / vcl_hash
 *
 *   Generate "random number" and add it to req.http.X-Varnish-Rand
 *   
 *   By default takes random number between 1 - 10. 
 *
 *   @parameter req.http.X-Varnish-Rand-Max integer   This parameter controls the random number range
 *
 */
sub std_request_pseudo_rand
{
C{
    const char *rand_max_hdr;
    char str_buf[48];
    int num_len;
    long rand_max = STD_RAND_MAX_DEFAULT;

    rand_max_hdr = VRT_GetHdr(sp, HDR_REQ, "\023X-Varnish-Rand-Max:");

    if (rand_max_hdr) {
        char *end = 0;

        rand_max = strtol(rand_max_hdr, &end, 0);
        
        if (ERANGE == errno || end == rand_max_hdr || rand_max < 0 || rand_max > INT_MAX) {
            rand_max = STD_RAND_MAX_DEFAULT;
        }
    }
    num_len = sprintf(str_buf, "%d", (int)(rand() % rand_max + 1));
    VRT_SetHdr(sp, HDR_REQ, "\017X-Varnish-Rand:", str_buf, vrt_magic_string_end);
}C
    unset req.http.X-Varnish-Rand-Max;
}

