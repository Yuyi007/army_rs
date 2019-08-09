#include "skynet.h"

#include "skynet_socket.h"
#include "socket_server.h"
#include "skynet_server.h"
#include "skynet_mq.h"
#include "skynet_harbor.h"
#include "skynet_env.h"

#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <stdio.h>
#include <errno.h>

static struct socket_server * SOCKET_SERVER = NULL;

static int g_udpPort = 0;
static uint32_t g_udpgate_sockid = 0;
static int g_udpgate_pipe[2];
static uint32_t g_sessionid = 0;
static uint16_t g_systemPid = 0;

void udpgate_sendrequest(const void *buffer, uint8_t sz);

////////////////////////////////////////////////////////////////////////

void 
skynet_socket_init() {
	SOCKET_SERVER = socket_server_create();
}

void
skynet_socket_exit() {
	socket_server_exit(SOCKET_SERVER);
}

void
skynet_socket_free() {
	socket_server_release(SOCKET_SERVER);
	SOCKET_SERVER = NULL;
}

// mainloop thread
static void
forward_message(int type, bool padding, struct socket_message * result) {
	struct skynet_socket_message *sm;
	size_t sz = sizeof(*sm);
	if (padding) {
		if (result->data) {
			size_t msg_sz = strlen(result->data);
			if (msg_sz > 128) {
				msg_sz = 128;
			}
			sz += msg_sz;
		} else {
			result->data = "";
		}
	}

	/////////////////////////////////////////
	if (type == SKYNET_SOCKET_TYPE_UDP){
		//check package header: system pid
		if (result->opaque == 0){ //udp gate
			uint8_t* pSysid = &g_systemPid;
			uint8_t sysid_low = *((uint8_t*)pSysid);
			uint8_t sysid_high = *((uint8_t*)(pSysid+1));

			//printf("check pid: %d , %d : %d , %d\n", sysid_low, sysid_high, *((uint8_t*)result->data), *((uint8_t*)(result->data+1)));
			if ( (*((uint8_t*)result->data) != sysid_high) ||
			   (*((uint8_t*)(result->data+1)) != sysid_low) ){ //dicard invalid package
				skynet_free(result->data);
				return;
			}
		}

		int isShakePkg = 0;
		if (result->data[2] == 1){
			isShakePkg = 1;

			if (result->opaque == 0){ //pipe to gate thread			
				if (result->ud == 3){ //shakehand package size check
					uint8_t buffer[2];
					buffer[0] = 'S';
					buffer[1] = result->ud+7;
					//printf("####socket udp recv handshake: %d bytes\n", result->ud);
					udpgate_sendrequest((const void*)buffer, 2);
					udpgate_sendrequest(result->data, result->ud+7);
				}

				skynet_free(result->data);
				return;
			}
		}

		uint8_t protocol = *((uint8_t*)(result->data+result->ud));

		//redirect to agent service
		if (isShakePkg == 0 && protocol == 1 && result->opaque == 0){
			uint32_t agent = get_clientagent(result->opaque, result->data+result->ud, 7);

			if (agent > 0){
				result->opaque = agent;
				sz = result->ud + 7;

				struct skynet_message message;
				message.source = 0;
				message.session = 0;
				message.data = result->data;
				message.sz = sz | ((size_t)PTYPE_CLIENT << MESSAGE_TYPE_SHIFT);	
	
				if (skynet_context_push((uint32_t)result->opaque, &message)) {		
					skynet_free(result->data);
				}
				return;
			}
		}
	}
	///////////////////////////////////////////////

	sm = (struct skynet_socket_message *)skynet_malloc(sz);

	sm->type = type;
	sm->id = result->id;
	sm->ud = result->ud;
	if (padding) {
		sm->buffer = NULL;
		memcpy(sm+1, result->data, sz - sizeof(*sm));
	} else {
		sm->buffer = result->data;
	}

	struct skynet_message message;
	message.source = 0;
	message.session = 0;
	message.data = sm;
	message.sz = sz | ((size_t)PTYPE_SOCKET << MESSAGE_TYPE_SHIFT);	
	
	if (skynet_context_push((uint32_t)result->opaque, &message)) {
		skynet_free(sm->buffer);
		skynet_free(sm);
	}
}

int 
skynet_socket_poll() {
	struct socket_server *ss = SOCKET_SERVER;
	assert(ss);
	struct socket_message result;
	int more = 1;
	int type = socket_server_poll(ss, &result, &more);
	switch (type) {
	case SOCKET_EXIT:
		return 0;
	case SOCKET_DATA:
		forward_message(SKYNET_SOCKET_TYPE_DATA, false, &result);
		break;
	case SOCKET_CLOSE:
		forward_message(SKYNET_SOCKET_TYPE_CLOSE, false, &result);
		break;
	case SOCKET_OPEN:
		forward_message(SKYNET_SOCKET_TYPE_CONNECT, true, &result);
		break;
	case SOCKET_ERR:
		forward_message(SKYNET_SOCKET_TYPE_ERROR, true, &result);
		break;
	case SOCKET_ACCEPT:
		forward_message(SKYNET_SOCKET_TYPE_ACCEPT, true, &result);
		break;
	case SOCKET_UDP:
		forward_message(SKYNET_SOCKET_TYPE_UDP, false, &result);
		break;
	case SOCKET_WARNING:
		forward_message(SKYNET_SOCKET_TYPE_WARNING, false, &result);
		break;
	default:
		skynet_error(NULL, "Unknown socket message type %d.",type);
		return -1;
	}
	if (more) {
		return -1;
	}
	return 1;
}

int
skynet_socket_send(struct skynet_context *ctx, int id, void *buffer, int sz) {
	return socket_server_send(SOCKET_SERVER, id, buffer, sz);
}

int
skynet_socket_send_lowpriority(struct skynet_context *ctx, int id, void *buffer, int sz) {
	return socket_server_send_lowpriority(SOCKET_SERVER, id, buffer, sz);
}

int 
skynet_socket_listen(struct skynet_context *ctx, const char *host, int port, int backlog) {
	uint32_t source = skynet_context_handle(ctx);
	return socket_server_listen(SOCKET_SERVER, source, host, port, backlog);
}

int 
skynet_socket_connect(struct skynet_context *ctx, const char *host, int port) {
	uint32_t source = skynet_context_handle(ctx);
	return socket_server_connect(SOCKET_SERVER, source, host, port);
}

int 
skynet_socket_bind(struct skynet_context *ctx, int fd) {
	uint32_t source = skynet_context_handle(ctx);
	return socket_server_bind(SOCKET_SERVER, source, fd);
}

void 
skynet_socket_close(struct skynet_context *ctx, int id) {
	uint32_t source = skynet_context_handle(ctx);
	socket_server_close(SOCKET_SERVER, source, id);
}

void 
skynet_socket_shutdown(struct skynet_context *ctx, int id) {
	uint32_t source = skynet_context_handle(ctx);
	socket_server_shutdown(SOCKET_SERVER, source, id);
}

void 
skynet_socket_start(struct skynet_context *ctx, int id) {
	uint32_t source = skynet_context_handle(ctx);
	socket_server_start(SOCKET_SERVER, source, id);
}

void
skynet_socket_nodelay(struct skynet_context *ctx, int id) {
	socket_server_nodelay(SOCKET_SERVER, id);
}

int 
skynet_socket_udp(struct skynet_context *ctx, const char * addr, int port) {
	uint32_t source = skynet_context_handle(ctx);
	return socket_server_udp(SOCKET_SERVER, source, addr, port);
}

int 
skynet_socket_udp_connect(struct skynet_context *ctx, int id, const char * addr, int port) {
	return socket_server_udp_connect(SOCKET_SERVER, id, addr, port);
}

int 
skynet_socket_udp_send(struct skynet_context *ctx, int id, const char * address, const void *buffer, int sz) {
	return socket_server_udp_send(SOCKET_SERVER, id, (const struct socket_udp_address *)address, buffer, sz);
}

const char *
skynet_socket_udp_address(struct skynet_socket_message *msg, int *addrsz) {
	if (msg->type != SKYNET_SOCKET_TYPE_UDP) {
		return NULL;
	}
	struct socket_message sm;
	sm.id = msg->id;
	sm.opaque = 0;
	sm.ud = msg->ud;
	sm.data = msg->buffer;
	return (const char *)socket_server_udp_address(SOCKET_SERVER, &sm, addrsz);
}

//////////////////////////////////////////////////////////////////////////////////

void skynet_sendsocketrequest_ext(const void *buffer, int sz){
	if (sz > 256){
		return;
	}
	socket_server_sendrequest_ext(SOCKET_SERVER, buffer, sz);
}

void skynet_udpgate_init(){
	char* cport = skynet_getenv("udpport");
	if (cport != NULL){
		g_udpPort = atoi(cport);
	}

	cport = skynet_getenv("udppid");
	if (cport != NULL){
		g_systemPid = atoi(cport);
	}	

	if (pipe(g_udpgate_pipe)) {
		fprintf(stderr, "udpgate: create pipe pair failed.\n");
	}
}

static void
gate_readpipe(int pipefd, void *buffer, int sz) {
	for (;;) {
		int n = read(pipefd, buffer, sz);
		if (n<0) {
			if (errno == EINTR)
				continue;
			fprintf(stderr, "udp_gate : read pipe error %s.\n",strerror(errno));
			return;
		}
		// must atomic read from a pipe
		assert(n == sz);
		return;
	}
}

struct SG_REGINFO
{
	uint32_t gateHandle;
	uint32_t port;
	uint32_t ip;
	uint32_t agent;
};

void udpgate_sendrequest(const void *buffer, uint8_t sz){
	if (g_udpgate_sockid == 0) {
		return;
	}

	int fd = g_udpgate_pipe[1];
	
	for (;;) {
		ssize_t n = write(fd, buffer, sz);
		if (n<0) {
			if (errno != EINTR) {
				fprintf(stderr, "socket-server : send ctrl command error %s.\n", strerror(errno));
			}
			continue;
		}
		assert(n == sz);
		return;
	}
}

int skynet_udpgate_poll(){
	//printf("skynet_udpgate_poll");
	int recv_fd = g_udpgate_pipe[0];

	//init udp 
	if (g_udpgate_sockid == 0){
		g_udpgate_sockid = socket_server_udp(SOCKET_SERVER, 0, "0.0.0.0", g_udpPort);
		printf("--udpgate begin: %d\n", g_udpPort);
	}

	uint8_t buffer[256];
	uint8_t header[2];

	gate_readpipe(recv_fd, header, sizeof(header));

	int type = header[0];
	int len = header[1];
	gate_readpipe(recv_fd, buffer, len);

	if (type == 'S'){
		//printf("udpgate recv ...\n");
		struct skynet_context *ctx = skynet_context_new("snlua", "udpagent");
		if (ctx == NULL) {
			skynet_error(NULL, "udpagent error : snlua udpagent\n");
			return 0;
		}
		//printf("udpgate service %d\n", skynet_context_handle(ctx));

		struct SG_REGINFO si;
		uint8_t sz = sizeof(struct SG_REGINFO);

		si.agent = skynet_context_handle(ctx); 
		si.gateHandle = 0;
		si.port = *((uint16_t*)(buffer+len-6));
		si.port = ntohs(si.port);
		si.ip = *((uint32_t*)(buffer+len-4));

		uint8_t buf[56];
		buf[0] = 'R';
		buf[1] = sz;
		memcpy(buf+2, &si, sz);
		skynet_sendsocketrequest_ext((const void*)buf, sz+2);

		g_sessionid = g_sessionid + 1;

		uint8_t* msgData = skynet_malloc(len + 8);
		memcpy(msgData, buffer, len-7);
		memcpy(msgData+len-7, &g_sessionid, 4);
		memcpy(msgData+len-7+4, &g_udpgate_sockid, 4);
		memcpy(msgData+len-7+4+4, buffer+len-7, 7);
		
		struct skynet_message message;
		size_t szMsg = len + 8;
		message.source = 0;
		message.session = 0;
		message.data = msgData;
		message.sz = szMsg | ((size_t)PTYPE_CLIENT << MESSAGE_TYPE_SHIFT);	
	
		if (skynet_context_push(si.agent, &message)) {
			//printf("--udpgate redirect handshake message failed!");
		
			skynet_free(msgData);
		}
	}
}

