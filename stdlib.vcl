/** 
 * Standard library of common Varnish functions
 * 
 * Assembled mainly from http://www.varnish-cache.org/trac/wiki/VCLExamples
 */

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
