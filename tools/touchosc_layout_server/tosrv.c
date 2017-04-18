// tosrv is based on tiny:
// https://github.com/shenfeng/tiny-web-server - a tiny web server in C, for daily use. 

// tosrv helps to deliver a layout file to a touchosc app running on a mobile device.
// /!\ tosrv is not useful as a generic http server.

// tosrv serves on the first GET / request:
//	-a given file in a given directory
// then quits.
// the file is delivered with content type "application/touchosc" as an attachment.

// see method serve_static()

// example call of tosrv (without using the Java TouchOSC GUI layout editor's sync):

// ./tosrv ../../scripts/cso/touchosc1/ cso_transport.touchosc
// in the TouchOSC app goto Layout/Add, set Editor Host to the IP address of this host
// tosrv will quit after one process cycle (no matter if it was successful or not)

//tb/1704

#include <arpa/inet.h>	/* inet_ntoa */
#include <signal.h>
#include <errno.h>
#include <fcntl.h>
#include <time.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/sendfile.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#define LISTENQ 1024	/* second argument to listen() */
#define MAXLINE 1024	/* max length of a line */
#define RIO_BUFSIZE 1024

//touchosc app will try on this port
int default_port = 9658;

typedef struct {
	int rio_fd;			/* descriptor for this buf */
	int rio_cnt;			/* unread byte in this buf */
	char *rio_bufptr;		/* next unread byte in this buf */
	char rio_buf[RIO_BUFSIZE];	/* internal buffer */
} rio_t;

/* Simplifies calls to bind(), connect(), and accept() */
typedef struct sockaddr SA;

typedef struct {
	char filename[512];
	off_t offset;			/* for support Range */
	size_t end;
} http_request;

char *filename_;

void rio_readinitb(rio_t *rp, int fd){
	rp->rio_fd = fd;
	rp->rio_cnt = 0;
	rp->rio_bufptr = rp->rio_buf;
}

ssize_t writen(int fd, void *usrbuf, size_t n){
	size_t nleft = n;
	ssize_t nwritten;
	char *bufp = usrbuf;

	while (nleft > 0){
		if ((nwritten = write(fd, bufp, nleft)) <= 0){
			if (errno == EINTR)	/* interrupted by sig handler return */
				nwritten = 0;	/* and call write() again */
			else
				return -1;	/* errorno set by write() */
		}
		nleft -= nwritten;
		bufp += nwritten;
	}
	return n;
}

/*
 * rio_read - This is a wrapper for the Unix read() function that
 *	transfers min(n, rio_cnt) bytes from an internal buffer to a user
 *	buffer, where n is the number of bytes requested by the user and
 *	rio_cnt is the number of unread bytes in the internal buffer. On
 *	entry, rio_read() refills the internal buffer via a call to
 *	read() if the internal buffer is empty.
 */
/* $begin rio_read */
static ssize_t rio_read(rio_t *rp, char *usrbuf, size_t n){
	int cnt;
	while (rp->rio_cnt <= 0){  /* refill if buf is empty */

		rp->rio_cnt = read(rp->rio_fd, rp->rio_buf, sizeof(rp->rio_buf));
		if (rp->rio_cnt < 0){
			if (errno != EINTR) /* interrupted by sig handler return */
				return -1;
		}
		else if (rp->rio_cnt == 0)  /* EOF */
			return 0;
		else
			rp->rio_bufptr = rp->rio_buf; /* reset buffer ptr */
	}

	/* Copy min(n, rp->rio_cnt) bytes from internal buf to user buf */
	cnt = n;
	if (rp->rio_cnt < n)
		cnt = rp->rio_cnt;
	memcpy(usrbuf, rp->rio_bufptr, cnt);
	rp->rio_bufptr += cnt;
	rp->rio_cnt -= cnt;
	return cnt;
}

/*
 * rio_readlineb - robustly read a text line (buffered)
 */
ssize_t rio_readlineb(rio_t *rp, void *usrbuf, size_t maxlen){
	int n, rc;
	char c, *bufp = usrbuf;

	for (n = 1; n < maxlen; n++){
		if ((rc = rio_read(rp, &c, 1)) == 1){
			*bufp++ = c;
			if (c == '\n')
				break;
		} else if (rc == 0){
			if (n == 1)
				return 0; /* EOF, no data read */
			else
				break;	/* EOF, some data was read */
		} else
			return -1;	/* error */
	}
	*bufp = 0;
	return n;
}

void format_size(char* buf, struct stat *stat){
	if(S_ISDIR(stat->st_mode)){
		sprintf(buf, "%s", "[DIR]");
	} else {
		off_t size = stat->st_size;
		if(size < 1024){
			sprintf(buf, "%lu", size);
		} else if (size < 1024 * 1024){
			sprintf(buf, "%.1fK", (double)size / 1024);
		} else if (size < 1024 * 1024 * 1024){
			sprintf(buf, "%.1fM", (double)size / 1024 / 1024);
		} else {
			sprintf(buf, "%.1fG", (double)size / 1024 / 1024 / 1024);
		}
	}
}

int open_listenfd(int port){
	int listenfd, optval=1;
	struct sockaddr_in serveraddr;

	/* Create a socket descriptor */
	if ((listenfd = socket(AF_INET, SOCK_STREAM, 0)) < 0)
		return -1;

	/* Eliminates "Address already in use" error from bind. */
	if (setsockopt(listenfd, SOL_SOCKET, SO_REUSEADDR,
			(const void *)&optval , sizeof(int)) < 0)
		return -1;

	// 6 is TCP's protocol number
	// enable this, much faster : 4000 req/s -> 17000 req/s
	if (setsockopt(listenfd, 6, TCP_CORK,
			(const void *)&optval , sizeof(int)) < 0)
		return -1;

	/* Listenfd will be an endpoint for all requests to port
	   on any IP address for this host */
	memset(&serveraddr, 0, sizeof(serveraddr));
	serveraddr.sin_family = AF_INET;
	serveraddr.sin_addr.s_addr = htonl(INADDR_ANY);
	serveraddr.sin_port = htons((unsigned short)port);
	if (bind(listenfd, (SA *)&serveraddr, sizeof(serveraddr)) < 0)
		return -1;

	/* Make it a listening socket ready to accept connection requests */
	if (listen(listenfd, LISTENQ) < 0)
		return -1;
	return listenfd;
}

void url_decode(char* src, char* dest, int max) {
	char *p = src;
	char code[3] = { 0 };
	while(*p && --max) {
		if(*p == '%') {
			memcpy(code, ++p, 2);
			*dest++ = (char)strtoul(code, NULL, 16);
			p += 2;
		} else {
			*dest++ = *p++;
		}
	}
	*dest = '\0';
}

void parse_request(int fd, http_request *req){
	rio_t rio;
	char buf[MAXLINE], method[MAXLINE], uri[MAXLINE];
	req->offset = 0;
	req->end = 0;				/* default */

	rio_readinitb(&rio, fd);
	rio_readlineb(&rio, buf, MAXLINE);
	sscanf(buf, "%s %s", method, uri);	/* version is not cared */
	/* read all */
	while(buf[0] != '\n' && buf[1] != '\n') { /* \n || \r\n */
		rio_readlineb(&rio, buf, MAXLINE);
		if(buf[0] == 'R' && buf[1] == 'a' && buf[2] == 'n'){
			sscanf(buf, "Range: bytes=%lu-%lu", &req->offset, &req->end);
			// Range: [start, end]
			if( req->end != 0) req->end ++;
		}
	}
	char* filename = uri;
	if(uri[0] == '/'){
		filename = uri + 1;
		int length = strlen(filename);
		if (length == 0){
			filename = ".";
		} else {
			for (int i = 0; i < length; ++ i) {
				if (filename[i] == '?') {
					filename[i] = '\0';
					break;
				}
			}
		}
	}
	url_decode(filename, req->filename, MAXLINE);
}

void log_access(int status, struct sockaddr_in *c_addr, http_request *req){
	printf("%s:%d %d - %s\n", inet_ntoa(c_addr->sin_addr),
		ntohs(c_addr->sin_port), status, req->filename);
}

void client_error(int fd, int status, char *msg, char *longmsg){
	char buf[MAXLINE];
	sprintf(buf, "HTTP/1.1 %d %s\r\n", status, msg);
	sprintf(buf + strlen(buf),
			"Content-length: %lu\r\n\r\n", strlen(longmsg));
	sprintf(buf + strlen(buf), "%s", longmsg);
	writen(fd, buf, strlen(buf));
}

void serve_static(int out_fd, int in_fd, http_request *req,
				  size_t total_size){
	char buf[256];

	sprintf(buf, "HTTP/1.0 200 OK\r\n");
	sprintf(buf + strlen(buf), "Content-Type: %s\r\n",
		"application/touchosc"
	);

	///
	sprintf(buf + strlen(buf), "Date: %s\r\n",
		"Date: Sat, 12 Apr 2024 20:30:06 GMT"
	);

	sprintf(buf + strlen(buf), "Content-Disposition: attachment; filename=\"%s\"\r\n\r\n"
		,req->filename);

	writen(out_fd, buf, strlen(buf));
	off_t offset = req->offset;	/* copy */
	while(offset < req->end){
		if(sendfile(out_fd, in_fd, &offset, req->end - req->offset) <= 0) {
			break;
		}
		close(out_fd);
		break;
	}
}

void process(int fd, struct sockaddr_in *clientaddr){
	printf("accept request, fd is %d, pid is %d\n", fd, getpid());

	int status=404;

	http_request req;
	parse_request(fd, &req);

	fprintf(stderr,"req.filename: %s\n",req.filename);
	if(!strcmp(req.filename, "."))
	{
		strcpy(req.filename, filename_);
	}
	else
	{
		fprintf(stderr,"request was not '/.'\n");
		status = 400;
		char *msg="File not found";
		client_error(fd, status, "Not found", msg);
		goto done;
	}

	struct stat sbuf;
	status = 200;
	int ffd = open(req.filename, O_RDONLY, 0);
	if(ffd <= 0){
		status = 404;
		char *msg = "File not found";
		client_error(fd, status, "Not found", msg);
	} else {
		fstat(ffd, &sbuf);
		if(S_ISREG(sbuf.st_mode)){
			if (req.end == 0){
				req.end = sbuf.st_size;
			}
			serve_static(fd, ffd, &req, sbuf.st_size);
		} else {
			status = 400;
			char *msg = "Unknow Error";
			client_error(fd, status, "Error", msg);
		}
		close(ffd);
	}

done:

	log_access(status, clientaddr, &req);
}

//=============================================================================
int main(int argc, char** argv){
	struct sockaddr_in clientaddr;

	int listenfd,connfd;

	socklen_t clientlen = sizeof clientaddr;

	if(argc!=3 || (argc==2 && ((!strcmp(argv[1],"-h")) || (!strcmp(argv[1],"--help")))))
	{
		fprintf(stderr,"tosrv httpd help:\n");
		fprintf(stderr,"tosrv <directory to serve> <filename>\n");
		fprintf(stderr,"listening on port: %d\n", default_port);
		exit(0);
	}

	if(chdir(argv[1]) != 0) {
		perror(argv[1]);
		exit(1);
	}	
	filename_=argv[2];

	listenfd = open_listenfd(default_port);
	if (listenfd > 0) {
		printf("listen on port %d, fd is %d\n", default_port, listenfd);
	printf("directory %s, file %s\n", argv[1], argv[2] );
	} else {
		perror("ERROR");
		exit(listenfd);
	}
	// Ignore SIGPIPE signal, so if browser cancels the request, it
	// won't kill the whole process.
	signal(SIGPIPE, SIG_IGN);

//	while(1){
		connfd = accept(listenfd, (SA *)&clientaddr, &clientlen);
		process(connfd, &clientaddr);
		close(connfd);
//	}

	return 0;
}
