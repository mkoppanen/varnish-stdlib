C{
#include <stdlib.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <unistd.h>
#include <fcntl.h>

static char *std_error_page_404 = NULL;
static char *std_error_page_500 = NULL;

#define STD_DELIVER_ERROR_PAGE(code) \
    if (std_error_page_##code) { \
        VRT_SetHdr(sp, HDR_OBJ, "\015Content-Type:", "text/html; charset=utf-8", vrt_magic_string_end); \
        VRT_synth_page(sp, 0, std_error_page_##code, "<!-- XID: ", VRT_r_req_xid(sp), " -->", vrt_magic_string_end); \
        VRT_done(sp, VCL_RET_DELIVER); \
    }

static char *std_mmap_error_page(const char *filename)
{
    char *ptr;
    struct stat st_buf;
    int fildes;
    size_t filesize;
    
    if (stat(filename, &st_buf) == -1) {
        return NULL;
    }

    fildes = open(filename, O_RDONLY);
    
    if (fildes == -1) {
        return NULL;
    }
    
    ptr = mmap(0, st_buf.st_size, PROT_READ, MAP_PRIVATE, fildes, 0);
    (void) close(fildes);
    
    if (ptr == MAP_FAILED) {    
        return NULL;
    }
    return ptr;
}

__attribute__((constructor)) void std_load_error_pages()
{
    std_error_page_404 = std_mmap_error_page("/etc/varnish/error-404.html");
    std_error_page_500 = std_mmap_error_page("/etc/varnish/error-500.html");
}
}C

/** 
 *   {{{ sub std_error_page | vcl_error
 *
 *   Show error page from a file
 */
sub std_error_page 
{
    if (obj.status == 404) {
C{    
        STD_DELIVER_ERROR_PAGE(404);
}C    
    } elsif (obj.status == 500) {
C{    
        STD_DELIVER_ERROR_PAGE(500);
}C
    }
}
/* }}} */