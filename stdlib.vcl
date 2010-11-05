/** 
 * Standard library of common Varnish functions
 * 
 * Assembled mainly from http://www.varnish-cache.org/trac/wiki/VCLExamples
 */
C{
#include <errno.h>
#include <limits.h>
}C

/**
 *   {{{ sub std_normalise_accept_encoding | vcl_recv
 *
 *   Normalise the incoming Accept-Encoding header
 *
 */
sub std_normalise_accept_encoding 
{
    if (req.http.Accept-Encoding) {
        if (req.url ~ "\.(jpg|jpeg|png|gif|gz|tgz|bz2|tbz|mp3|ogg|swf|mp4|flv|wmv|zip|7z)$") {
            // don't try to compress already compressed files
            unset req.http.Accept-Encoding;
        } elsif (req.http.Accept-Encoding ~ "gzip") {
            set req.http.Accept-Encoding = "gzip";
        } elsif (req.http.Accept-Encoding ~ "deflate") {
            set req.http.Accept-Encoding = "deflate";
        } else {
            // unkown algorithm
            unset req.http.Accept-Encoding;
        }
    }
}
/* }}} */

/**
 *   {{{ sub std_extend_cache_control | vcl_fetch
 *
 *   Adds custom Cache-Control directive to control how long Varnish
 *   keeps the item in cache. This allows using v-maxage as part of 
 *   Cache-Control header to override the cache lifetime internally
 */
sub std_extended_cache_control
{   
    if (beresp.http.Cache-Control ~ "v-max-age=[0-9]+") {
        /* Copy the ttl part from original header */
        set obj.http.X-Cache-Control-TTL = regsub(obj.http.Cache-Control, ".*v-maxage=([0-9]+).*", "\1");
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

/**
 *   {{{ sub std_normalise_request | vcl_recv
 *
 *   From http://www.varnish-cache.org/trac/wiki/VCLExampleNormalizingReqUrl
 */
sub std_normalise_request 
{
    // clean out requests sent via curls -X mode and LWP
    if (req.url ~ "^http://") {
        set req.url = regsub(req.url, "http://[^/]*", "");
    }
}
/* }}} */

/** 
 *   {{{ sub std_add_x_cache_header | vcl_deliver
 * 
 *   Adds header whether the request was a HIT or a MISS
 */
sub std_add_x_cache_header
{
    if (obj.hits > 0) {
        set resp.http.X-Cache = "HIT (" obj.hits ")";
    } else {
        set resp.http.X-Cache = "MISS";
    }
}
/* }}} */

/** 
 *   {{{ sub std_allow_force_refresh | vcl_hit
 *
 *   Allows clients to force refresh of the content
 */
sub std_allow_force_refresh 
{
    if (!obj.cacheable) {
        return (pass);
    }

    if (req.http.Cache-Control ~ "no-cache") {
        if (!(req.http.Via || req.http.User-Agent ~ "bot|MSIE")) {
            set obj.ttl = 0s;
            return (restart);
        } 
    }
    return (deliver);
}
/* }}} */
