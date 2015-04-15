/*
$Id: ledindicator.c 1 2015-04-14 10:48:32Z andywhite $
part of t1n1wall (http://t1n1wall.com)
Copyright (C) 2015 Andrew White <andywhite@t1n1wall.com>
All rights reserved.
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
1. Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.
THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
*/
#include <signal.h>
#include <sys/types.h>
#include <sys/sysctl.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <netinet/in.h>
#include <netinet/ip.h>
#include <netinet/ip_var.h>
#include <inttypes.h>
#include <string.h>
#include <unistd.h>
#include <sys/dkstat.h>
#include <pthread.h>
static volatile int run = 0;
pthread_t tid[3];
void term(int signum)
{
    run = 1;
}
void * kaled()
{
    if( access( "/dev/led/led3", W_OK ) != -1 )
    {
        FILE *fp;
        while (!run)
        {
            fp = fopen("/dev/led/led3", "w+");
            fprintf(fp, "1");
            fclose(fp);
            sleep(5);
            fp = fopen("/dev/led/led3", "w+");
            fprintf(fp, "0");
            fclose(fp);
            sleep(5);
        }
        fp = fopen("/dev/led/led3", "w+");
        fprintf(fp, "0");
        fclose(fp);
    }
    return 0;
}
void * cpuled()
{
    if( access( "/dev/led/led2", W_OK ) != -1 )
    {
        FILE *fp;
        /* get initial value for cpuload */
        long cp_time1[CPUSTATES], cp_time2[CPUSTATES];
        long total1, total2;
        size_t len;
        double cpuload;
        len = sizeof(cp_time1);
        len = sizeof(cp_time2);
        int ledval = 0 ;
        while (!run)
        /* int i; */
        /* for (i = 0; i < 30; i++) */
        {
            if (sysctlbyname("kern.cp_time", &cp_time1, &len, NULL, 0) < 0) exit(1);
            sleep(1);
            /* led 2 for cpu utilisation */
            if (sysctlbyname("kern.cp_time", &cp_time2, &len, NULL, 0) < 0) exit(1);
            total1 = cp_time1[CP_USER] + cp_time1[CP_NICE] + cp_time1[CP_SYS] +
            cp_time1[CP_INTR] + cp_time1[CP_IDLE];
            total2 = cp_time2[CP_USER] + cp_time2[CP_NICE] + cp_time2[CP_SYS] +
            cp_time2[CP_INTR] + cp_time2[CP_IDLE];
            cpuload = 1 - ((double)(cp_time2[CP_IDLE] - cp_time1[CP_IDLE]) / (double)(total2 - total1));

            if (cpuload*100 < 10)
            {
                if (ledval != 1 ) {
                    fp = fopen("/dev/led/led2", "w+");
                    fprintf(fp, "f6");
                    fclose(fp);
                    ledval=1;
                 }
            } else if (cpuload*100 < 50)
            {
                if (ledval != 2) {
                    fp = fopen("/dev/led/led2", "w+");
                    fprintf(fp, "f3");
                    fclose(fp);
                    ledval=2;
                }
            } else
            {
                if (ledval != 3) {
                    fp = fopen("/dev/led/led2", "w+");
                    fprintf(fp, "f1");
                    fclose(fp);
                    ledval=3;
                }
            }
        }
        fp = fopen("/dev/led/led2", "w+");
        fprintf(fp, "0");
        fclose(fp);
    }
    return 0;
}
void * fwdpktled()
{
    if( access( "/dev/led/led1", W_OK ) != -1 )
    {
        FILE *fp;
        /* get initial value for packet forwarding rate calc */
        struct ipstat * c;
        struct ipstat * p;
        int a;
        int b;
        void * oldp = malloc(1024);
        size_t oldlen = sizeof(struct ipstat), newlen;
        void * newp = NULL;
        int ledval=0;
        if (sysctlbyname("net.inet.ip.stats", oldp, &oldlen, newp, newlen) < 0) exit(1);
        p = oldp;
        b=p->ips_forward;
        while (!run)
        {
            sleep(1);
            /* led 1 for packet forward rate */
            if (sysctlbyname("net.inet.ip.stats", oldp, &oldlen, newp, newlen) < 0) exit(1);
            c = oldp;
            a = c->ips_forward;
            int rate = a - b;
            b = a;
            if (rate < 1000)
            {
                if (ledval != 1) {
                    fp = fopen("/dev/led/led1", "w+");
                    fprintf(fp, "f6");
                    ledval=1;
                    fclose(fp);
                }
            } else if (rate < 10000)
            {
                if (ledval != 2) {
                   fp = fopen("/dev/led/led1", "w+");
                   fprintf(fp, "f3");
                   ledval=2;
                   fclose(fp);
                }
                ledval=2;
            } else
            {
                if (ledval != 3) {
                    fp = fopen("/dev/led/led1", "w+");
                    fprintf(fp, "f1");
                    ledval=3;
                    fclose(fp);
                }
            }
        }
        fp = fopen("/dev/led/led1", "w+");
        fprintf(fp, "0");
        fclose(fp);
    }
    return 0;
}
int main(int argc, char *argv[])
{
    /* handle signals */
    struct sigaction action;
    memset(&action, 0, sizeof(struct sigaction));
    action.sa_handler = term;
    sigaction(SIGTERM, &action, NULL);
    /* go into background */
    if (daemon(0, 0) == -1)
    exit(1);
    /* write PID to file */
    FILE *pidfd;
    pidfd = fopen(argv[1], "w");
    if (pidfd)
    {
        fprintf(pidfd, "%dn", getpid());
        fclose(pidfd);
    }
    /* launch threads */
    (void) pthread_create(&(tid[0]), NULL, &fwdpktled, NULL);
    (void) pthread_create(&(tid[1]), NULL, &cpuled, NULL);
    (void) pthread_create(&(tid[2]), NULL, &kaled, NULL);
    while (!run)
    {
        sleep(1);
    }
    (void) pthread_join(tid[0], NULL);
    (void) pthread_join(tid[1], NULL);
    (void) pthread_join(tid[2], NULL);
    return 0;
}
