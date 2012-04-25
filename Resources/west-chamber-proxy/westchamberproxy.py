#!/usr/bin/env python
# -*- coding: utf-8 -*-

'''
    westchamberproxy by liruqi AT gmail.com
    Based on:
    PyGProxy helps you access Google resources quickly!!!
    Go through the G.F.W....
    gdxxhg AT gmail.com 110602
'''

from BaseHTTPServer import BaseHTTPRequestHandler, HTTPServer
from SocketServer import ThreadingMixIn
from httplib import HTTPResponse, BadStatusLine
import re, socket, struct, threading, traceback, sys, select, urlparse, signal, urllib, urllib2, json, time
import config

grules = []

gConfig = config.gConfig

gOptions = {}

gipWhiteList = []
domainWhiteList = [
    ".cn",
    ".am",
    ".pl",
    ".gl",
    "baidu.com",
    "mozilla.org",
    "mozilla.net",
    "mozilla.com",
    "wp.com",
    "qstatic.com",
    "serve.com",
    "qq.com",
    "qqmail.com",
    "soso.com",
    "weibo.com",
    "youku.com",
    "tudou.com",
    "ft.net",
    "ge.net",
    "no-ip.com",
    "nbcsandiego.com",
    "unity3d.com",
    ]

class ThreadingHTTPServer(ThreadingMixIn, HTTPServer): pass
class ProxyHandler(BaseHTTPRequestHandler):
    remote = None
    dnsCache = {}
    now = 0
    depth = 0

    def enableInjection(self, host, ip):
        self.depth += 1
        if self.depth > 3:
            if gOptions.log>0: print host + " looping, exit"
            return

        global gipWhiteList;
        print "check "+host + " " + ip
        if (host == ip):
            if gOptions.log>0: print host + ": do not inject ip or white list domain"
            return False
        
        for c in ip:
            if c!='.' and (c>'9' or c < '0'):
                if gOptions.log>0: print "recursive ip "+ip
                return True

        for r in gipWhiteList:
            ran,m2 = r.split("/");
            dip = struct.unpack('!I', socket.inet_aton(ip))[0]
            dran = struct.unpack('!I', socket.inet_aton(ran))[0]
            shift = 32 - int(m2)
            if (dip>>shift) == (dran>>shift):
                if gOptions.log > 1: 
                    print ip + " (" + host + ") is in China, matched " + (r)
                return False
        return True

    def isIp(self, host):
        return re.match(r'^([0-9]+\.){3}[0-9]+$', host) != None

    def getip(self, host):
        if self.isIp(host):
            return host

        for r in grules:
            if r[1].match(host) is not None:
                print ("Rule resolve: " + host + " => " + r[0])
                return r[0]

        print "Resolving " + host
        self.now = int( time.time() )
        if host in self.dnsCache:
            if self.now < self.dnsCache[host]["expire"]:
                if gOptions.log > 1: 
                    print "Cache: " + host + " => " + self.dnsCache[host]["ip"] + " / expire in %d (s)" %(self.dnsCache[host]["expire"] - self.now)
                return self.dnsCache[host]["ip"]

        if gConfig["SKIP_LOCAL_RESOLV"]:
            return self.getRemoteResolve(host, gConfig["REMOTE_DNS"])

        try:
            ip = socket.gethostbyname(host)
            fakeIp = {
                0x5d2e0859 : 1,
                0xcb620741 : 1,
                0x0807c62d : 1,
                0x4e10310f : 1,
                0x2e52ae44 : 1,
                0xf3b9bb27 : 1,
                0xf3b9bb1e : 1,
                0x9f6a794b : 1,
                0x253d369e : 1,
                0x9f1803ad : 1,
                0x3b1803ad : 1,
            }
            ChinaUnicom404 = {
                "202.106.199.37" : 1,
                "202.106.195.30" : 1,
            }
            packedIp = socket.inet_aton(ip)
            if struct.unpack('!I', packedIp)[0] in fakeIp:
                print ("Fake IP " + host + " => " + ip)
            elif ip in ChinaUnicom404:
                print ("ChinaUnicom404 " + host + " => " + ip + ", ignore")
            else:
                if gOptions.log > 1: 
                    print ("DNS system resolve: " + host + " => " + ip)
                return ip
        except:
            print "DNS system resolve Error: " + host
            ip = ""
        return self.getRemoteResolve(host, gConfig["REMOTE_DNS"])

    def getRemoteResolve(self, host, dnsserver):
        if gOptions.log > 1: 
            print "remote resolve " + host + " by " + dnsserver
        import DNS
        reqObj = DNS.Request()
        response = reqObj.req(name=host, qtype="A", protocol="tcp", server=dnsserver)
        #response.show()
        #print "answers: " + str(response.answers)
        for a in response.answers:
            if a["name"] == host:
                if gOptions.log > 1: 
                    print ("DNS remote resolve: " + host + " => " + str(a))
                if a['typename'] == 'CNAME':
                    return self.getip(a["data"])
                self.dnsCache[host] = {"ip":a["data"], "expire":self.now + a["ttl"]*2 + 60}
                return a["data"]
        if gOptions.log > 0: 
            print "authority: "+ str(response.authority)
        for a in response.authority:
            if a['typename'] != "NS":
                continue
            if type(a['data']) == type((1,2)):
                return self.getRemoteResolve(host, a['data'][0])
            else :
                return self.getRemoteResolve(host, a['data'])
        print ("DNS remote resolve failed: " + host)
        return host
    
    def proxy(self):
        doInject = False
        if gOptions.log > 0: print self.requestline
        port = 80
        host = self.headers["Host"]
        if host.find(":") != -1:
            port = int(host.split(":")[1])
            host = host.split(":")[0]

        try:
            redirectUrl = self.path
            while True:
                (scm, netloc, path, params, query, _) = urlparse.urlparse(redirectUrl)
                if gOptions.log > 2: print urlparse.urlparse(redirectUrl)

                if (netloc not in gConfig["REDIRECT_DOMAINS"]):
                    break
                prefixes = gConfig["REDIRECT_DOMAINS"][netloc].split('|')
                found = False
                for prefix in prefixes:
                    prefix = prefix + "="
                    for param in query.split('&') :
                        if param.find(prefix) == 0:
                            print "redirect to " + urllib.unquote(param[len(prefix):])
                            redirectUrl = urllib.unquote(param[len(prefix):])
                            found = True
                            continue 
                if not found:
                    break

            if (host in gConfig["HSTS_DOMAINS"]):
                redirectUrl = "https://" + self.path[7:]

            #redirect 
            if (redirectUrl != self.path):
                status = "HTTP/1.1 302 Found"
                self.wfile.write(status + "\r\n")
                self.wfile.write("Location: " + redirectUrl + "\r\n")
                return

            # Remove http://[host] , for google.com.hk
            path = self.path[self.path.find(netloc) + len(netloc):]

            connectHost = self.getip(host)
            if (host in gConfig["BLOCKED_DOMAINS"]) or (connectHost in gConfig["BLOCKED_IPS"]):
                gConfig["BLOCKED_DOMAINS"][host] = True
                if gOptions.log>0 : print "add ip "+ connectHost + " to block list"
                gConfig["BLOCKED_IPS"][connectHost] = True
                host = gConfig["PROXY_SERVER_SIMPLE"]
                connectHost = self.getip(host)
                path = self.path[len(scm)+2:]
                self.headers["Host"] = gConfig["PROXY_SERVER_SIMPLE"]
                print "use simple web proxy for " + path
            
            if True:
                inWhileList = False
                for d in domainWhiteList:
                    if host.endswith(d):
                        if gOptions.log > 1: print host + " in domainWhiteList: " + d
                        inWhileList = True

                doInject = self.enableInjection(host, connectHost)
                if True:
                    self.remote = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                    if gOptions.log > 1: print "connect to " + host + ":" + str(port)
                    self.remote.connect((connectHost, port))
                    if doInject: 
                        if gOptions.log > 0: print "inject http for "+host
                        self.remote.send("\r\n\r\n")
                # Send requestline
                if path == "":
                    path = "/"
                print " ".join((self.command, path, self.request_version)) + "\r\n"
                self.remote.send(" ".join((self.command, path, self.request_version)) + "\r\n")
                # Send headers
                if host[-12:] == ".appspot.com":
                    print "add version code " + gConfig["VERSION"] + " in HTTP header"
                    self.headers["X-WCProxy"] = gConfig["VERSION"]
                self.remote.send(str(self.headers) + "\r\n")
                # Send Post data
                if(self.command=='POST'):
                    self.remote.send(self.rfile.read(int(self.headers['Content-Length'])))
                response = HTTPResponse(self.remote, method=self.command)
                badStatusLine = False
                msg = "http405"
                try :
                    response.begin()
                    print host + " response: %d"%(response.status)
                    msg = "http%d"%(response.status)
                except BadStatusLine:
                    print host + " response: BadStatusLine"
                    msg = "badStatusLine"
                    badStatusLine = True
                except:
                    raise

                if doInject and (response.status == 400 or response.status == 405 or badStatusLine) and host != gConfig["PROXY_SERVER_SIMPLE"] and host != gConfig["PROXY_SERVER"][7:-1]:
                    self.remote.close()
                    self.remote = None
                    if gOptions.log > 0: print host + " seem not support inject, " + msg
                    domainWhiteList.append(host)
                    return self.proxy()

            # Reply to the browser
            status = "HTTP/1.1 " + str(response.status) + " " + response.reason
            self.wfile.write(status + "\r\n")
            h = ''
            for hh, vv in response.getheaders():
                if hh.upper()!='TRANSFER-ENCODING':
                    h += hh + ': ' + vv + '\r\n'
            self.wfile.write(h + "\r\n")

            dataLength = 0
            while True:
                response_data = response.read(8192)
                if(len(response_data) == 0): break
                if dataLength == 0 and (len(response_data) <= 320):
                    if response_data.find("<title>400 Bad Request") != -1 or response_data.find("<title>501 Method Not Implemented") != -1:
                        print host + " not supporting injection"
                        domainWhiteList.append(host)
                        response_data = gConfig["PAGE_RELOAD_HTML"]
                self.wfile.write(response_data)
                dataLength += len(response_data)
                if gOptions.log > 1: print "data length: %d"%dataLength
        except:
            if self.remote:
                self.remote.close()
                self.remote = None

            (scm, netloc, path, params, query, _) = urlparse.urlparse(self.path)
            status = "HTTP/1.1 302 Found"
            if (netloc == urlparse.urlparse( gConfig["PROXY_SERVER"] )[1]) or (netloc == gConfig["PROXY_SERVER_SIMPLE"]) or (scm.upper() != "HTTP"):
                msg = scm + "-" + netloc
                self.wfile.write(status + "\r\n")
                self.wfile.write("Location: http://westchamberproxy.appspot.com/#" + msg + "\r\n")
                return

            exc_type, exc_value, exc_traceback = sys.exc_info()

            if exc_type == socket.error:
                code, msg = str(exc_value).split('] ')
                code = code[1:].split(' ')[1]
                if code in ["32", "10053"]: #errno.EPIPE, 10053 is for Windows
                    if gOptions.log > 0: print "Detected remote disconnect: " + host
                    return
                if code in ["61"]: #server not support injection
                    if doInject:
                        print "try not inject " + host
                        domainWhiteList.append(host)
                        self.proxy()
                        return
            print "error in proxy: ", self.requestline
            print exc_type
            print str(exc_value) + " " + host
            if exc_type == socket.timeout or (exc_type == socket.error and code in ["60", "110", "10060"]): #timed out, 10060 is for Windows
                if gOptions.log > 0: print "add "+host+" to blocked domains"
                gConfig["BLOCKED_DOMAINS"][host] = True
                return self.proxy()
            
            traceback.print_tb(exc_traceback)
            if doInject:
                self.wfile.write(status + "\r\n")
                redirectUrl = gConfig["PROXY_SERVER"] + self.path[7:]
                if host in gConfig["HSTS_ON_EXCEPTION_DOMAINS"]:
                    redirectUrl = "https://" + self.path[7:]
                self.wfile.write("Location: " + redirectUrl + "\r\n")
            else :
                msg = scm + "-" + host 
                self.wfile.write(status + "\r\n")
                self.wfile.write("Location: http://westchamberproxy.appspot.com/#" + msg + "\r\n")
            print "client connection closed"

    
    def do_GET(self):
        #some sites(e,g, weibo.com) are using comet (persistent HTTP connection) to implement server push
        #after setting socket timeout, many persistent HTTP requests redirects to web proxy, waste of resource
        #socket.setdefaulttimeout(18)
        self.proxy()
    def do_POST(self):
        #socket.setdefaulttimeout(None)
        self.proxy()

    def do_CONNECT(self):
        host, port = self.path.split(":")
        host = self.getip(host)
        self.remote = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        print ("connect " + host + ":%d" % int(port))
        self.remote.connect((host, int(port)))

        Agent = 'WCProxy/1.0'
        self.wfile.write('HTTP/1.1'+' 200 Connection established\n'+
                         'Proxy-agent: %s\n\n'%Agent)
        self._read_write()
        return

    # reslove ssl from http://code.google.com/p/python-proxy/
    def _read_write(self):
        BUFLEN = 8192
        time_out_max = 60
        count = 0
        socs = [self.connection, self.remote]
        while 1:
            count += 1
            (recv, _, error) = select.select(socs, [], socs, 3)
            if error:
                print ("select error")
                break
            if recv:
                for in_ in recv:
                    data = in_.recv(BUFLEN)
                    if in_ is self.connection:
                        out = self.remote
                    else:
                        out = self.connection
                    if data:
                        out.send(data)
                        count = 0
            if count == time_out_max:
                if gOptions.log > 1: print ("select timeout")
                break


def start():
    # Read Configuration
    try:
        s = urllib2.urlopen('http://liruqi.sinaapp.com/mirror.php?u=aHR0cDovL3NtYXJ0aG9zdHMuZ29vZ2xlY29kZS5jb20vc3ZuL3RydW5rL2hvc3Rz')
        for line in s.readlines():
            line = line.strip()
            line = line.split("#")[0]
            d = line.split()
            if (len(d) != 2): continue
            if gOptions.log > 1: print "read "+line
            regexp = d[1].replace(".", "\.").replace("*", ".*")
            try: grules.append((d[0], re.compile(regexp)))
            except: print "Invalid rule:", d[1]
        s.close()
    except:
        print "read onine hosts fail"
    
    try:
        global gipWhiteList;
        s = open(gConfig["CHINA_IP_LIST_FILE"])
        gipWhiteList = json.loads( s.read() )
        print "load %d ip range rules" % len(gipWhiteList);
        s.close()
    except:
        print "load ip-range config fail"

    try:
        s = urllib2.urlopen(gConfig["BLOCKED_DOMAINS_URI"])
        for line in s.readlines():
            line = line.strip()
            gConfig["BLOCKED_DOMAINS"][line] = True
        s.close()
    except:
        print "load blocked domains failed"

    print "Loaded", len(grules), " dns rules."
    print "Set your browser's HTTP/HTTPS proxy to 127.0.0.1:%d"%(gOptions.port)
    server = ThreadingHTTPServer(("0.0.0.0", gOptions.port), ProxyHandler)
    try: server.serve_forever()
    except KeyboardInterrupt: exit()
    
if __name__ == "__main__":
    try :
        import argparse
        parser = argparse.ArgumentParser(description='west chamber proxy')
        parser.add_argument('--port', default=gConfig["LOCAL_PORT"], type=int,
                   help='local port')
        parser.add_argument('--log', default=1, type=int, help='log level, 0-3')
        parser.add_argument('--pidfile', default='', help='pid file')
        gOptions = parser.parse_args()
        if gOptions.pidfile != "":
            import os
            pid = str(os.getpid())
            f = open(gOptions.pidfile,'w')
            print "Writing pid " + pid + " to "+gOptions.pidfile
            f.write(pid)
            f.close()
    except :
        #import argparse error, e.g. python26
        print "import argparse error"
        class option:
            def __init__(self): 
                self.log = 1
                self.port = gConfig["LOCAL_PORT"]
        gOptions = option()
    start()
