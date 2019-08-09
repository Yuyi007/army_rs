#include "skynet.h"

#include <syslog.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

struct sys_logger {
	char * pszAppName;
};

struct sys_logger *
syslogger_create(void)
{
	struct sys_logger * inst = skynet_malloc(sizeof(*inst));
	inst->pszAppName = NULL;
	return inst;
}

void 
syslogger_release(struct sys_logger * inst)
{
	closelog();
	skynet_free(inst->pszAppName);
	skynet_free(inst);
}


static int
syslogger_cb(struct skynet_context * context, void *ud, int type, int session, uint32_t source, const void * msg, size_t sz)
{
	struct logger * inst = ud;
	
	//|log level | log msg |
	//	 int        char    
	//LOG_EMERG	0	/* system is unusable */
	//LOG_ALERT	1	/* action must be taken immediately */
	//LOG_CRIT	2	/* critical conditions */
	//LOG_ERR		3	/* error conditions */
	//LOG_WARNING	4	/* warning conditions */
	//LOG_NOTICE	5	/* normal but significant condition */
	//LOG_INFO	6	/* informational */
	//LOG_DEBUG	7	/* debug-level messages */
	char c = ((const char*)msg)[0];
	int t = (int)c;
	const char *pszMsg = (const char *)(msg + 1);
	syslog (t, pszMsg);

	return 0;
}

int 
syslogger_init(struct sys_logger * inst, struct skynet_context *ctx, const char * parm)
{
	if (parm) 
	{
		inst->pszAppName = skynet_malloc(strlen(parm)+1);
		strcpy(inst->pszAppName, parm);

		int option = LOG_PID | LOG_CONS;
		openlog(inst->pszAppName, option, LOG_LOCAL5);

		skynet_callback(ctx, inst, syslogger_cb);
		//".xxx" means register a service named "xxx"
		skynet_command(ctx, "REG", ".syslogger"); 
		return 0;
	}
	return 1;
}
