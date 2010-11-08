C{
#include <errno.h>
#include <limits.h>
}C

/**
 *   {{{ sub std_extend_cache_control | vcl_fetch
 *
 *   Adds custom Cache-Control directive to control how long Varnish
 *   keeps the item in cache. This allows using v-maxage as part of 
 *   Cache-Control header to override the cache lifetime internally
 *
 *   Usage: Cache-Control: public, max-age=10, s-maxage=10, v-maxage=3600
 *
 *   This would cause normal caches to cache for 10 seconds and Varnish 
 *   for 3600 seconds
 */
sub std_extended_cache_control
{   
    if (beresp.http.Cache-Control ~ "v-maxage=[0-9]+") {
        /* Copy the ttl part from original header */
        set obj.http.X-Cache-Control-TTL = regsub(beresp.http.Cache-Control, ".*v-maxage=([0-9]+).*", "\1");
C{
        {   
            char *x_end = 0;
            const char *x_hdr_val = VRT_GetHdr(sp, HDR_BERESP, "\024X-Cache-Control-TTL:");
            if (x_hdr_val) {
                long x_cache_ttl = strtol(x_hdr_val, &x_end, 0);
                if (ERANGE != errno && x_end != x_hdr_val && x_cache_ttl >= 0 && x_cache_ttl < INT_MAX) {
                    VRT_l_beresp_ttl(sp, (x_cache_ttl * 1));
                }
            }
        }
}C
        unset obj.http.X-Cache-Control-TTL;
    }
}
/* }}} */