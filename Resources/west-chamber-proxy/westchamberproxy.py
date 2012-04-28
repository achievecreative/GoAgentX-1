#!/usr/bin/env python
# -*- coding: utf-8 -*-

'''
    westchamberproxy by liruqi@gmail.com
    Based on:
    PyGProxy by gdxxhg@gmail.com 
    GoAgent by {phus.lu,hewigovens}@gmail.com (Phus Lu and Hewig Xu)
'''

from BaseHTTPServer import BaseHTTPRequestHandler, HTTPServer
from SocketServer import ThreadingMixIn
from httplib import HTTPResponse, BadStatusLine
import os, re, socket, struct, threading, traceback, sys, select, urlparse, signal, urllib, urllib2, time, hashlib, binascii, zlib, httplib, errno
try:
    import OpenSSL
except ImportError:
    OpenSSL = None

class SimpleLogging(object):
    CRITICAL = 50
    FATAL = CRITICAL
    ERROR = 40
    WARNING = 30
    WARN = WARNING
    INFO = 20
    DEBUG = 10
    NOTSET = 0
    def __init__(self, *args, **kwargs):
        self.level = SimpleLogging.DEBUG
        self.__write = sys.stdout.write
    def basicConfig(self, *args, **kwargs):
        self.level = kwargs.get('level', SimpleLogging.INFO)
        if self.level > SimpleLogging.DEBUG:
            self.debug = self.dummy
    def log(self, level, fmt, *args):
        self.__write('%s - - [%s] %s\n' % (level, time.ctime()[4:-5], fmt%args))
    def dummy(self, *args):
        pass
    def debug(self, fmt, *args):
        self.log('DEBUG', fmt, *args)
    def info(self, fmt, *args):
        self.log('INFO', fmt, *args)
    def warning(self, fmt, *args):
        self.log('WARNING', fmt, *args)
    def warn(self, fmt, *args):
        self.log('WARNING', fmt, *args)
    def error(self, fmt, *args):
        self.log('ERROR', fmt, *args)
    def exception(self, fmt, *args):
        self.log('ERROR', fmt, *args)
    def critical(self, fmt, *args):
        self.log('CRITICAL', fmt, *args)

logging = SimpleLogging()

import config

gConfig = config.gConfig

grules = { gConfig["GOAGENT_FETCHHOST"]: "203.208.46.6" }

gConfig["BLACKHOLES"] = [
    '243.185.187.30', 
    '243.185.187.39', 
    '46.82.174.68', 
    '78.16.49.15', 
    '93.46.8.89', 
    '37.61.54.158', 
    '159.24.3.173', 
    '203.98.7.65', 
    '8.7.198.45', 
    '159.106.121.75', 
    '59.24.3.173'
]

def socket_create_connection((host, port), timeout=None, source_address=None):
    logging.debug('socket_create_connection connect (%r, %r)', host, port)
    if host == gConfig["GOAGENT_FETCHHOST"]:
        msg = 'socket_create_connection returns an empty list'
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.connect((grules[host],port))
            sock.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, True)
            return sock
        except socket.error, msg:
            logging.error('socket_create_connection connect fail: (%r, %r)', grules[host], port)
            sock = None
        if not sock:
            raise socket.error, msg
    else:
        msg = 'getaddrinfo returns an empty list'
        for res in socket.getaddrinfo(host, port, 0, socket.SOCK_STREAM):
            af, socktype, proto, canonname, sa = res
            sock = None
            try:
                sock = socket.socket(af, socktype, proto)
                if isinstance(timeout, (int, float)):
                    sock.settimeout(timeout)
                if source_address is not None:
                    sock.bind(source_address)
                sock.connect(sa)
                return sock
            except socket.error, msg:
                if sock is not None:
                    sock.close()
        raise socket.error, msg
socket.create_connection = socket_create_connection


class SimpleMessageClass(object):
    def __init__(self, fp, seekable = 0):
        self.dict = dict = {}
        self.headers = headers = []
        readline = getattr(fp, 'readline', None)
        headers_append = headers.append
        if readline:
            while 1:
                line = readline(8192)
                if not line or line == '\r\n':
                    break
                key, _, value = line.partition(':')
                if value:
                    headers_append(line)
                    dict[key.title()] = value.strip()
        else:
            for key, value in fp:
                key = key.title()
                dict[key] = value
                headers_append('%s: %s\r\n' % (key, value))

    def getheader(self, name, default=None):
        return self.dict.get(name.title(), default)

    def getheaders(self, name, default=None):
        return [self.getheader(name, default)]

    def addheader(self, key, value):
        self[key] = value

    def get(self, name, default=None):
        return self.dict.get(name.title(), default)

    def iteritems(self):
        return self.dict.iteritems()

    def iterkeys(self):
        return self.dict.iterkeys()

    def itervalues(self):
        return self.dict.itervalues()

    def keys(self):
        return self.dict.keys()

    def values(self):
        return self.dict.values()

    def items(self):
        return self.dict.items()

    def __getitem__(self, name):
        return self.dict[name.title()]

    def __setitem__(self, name, value):
        name = name.title()
        self.dict[name] = value
        headers = self.headers
        try:
            i = (i for i, line in enumerate(headers) if line.partition(':')[0].title() == name).next()
            headers[i] = '%s: %s\r\n' % (name, value)
        except StopIteration:
            headers.append('%s: %s\r\n' % (name, value))

    def __delitem__(self, name):
        name = name.title()
        del self.dict[name]
        headers = self.headers
        for i in reversed([i for i, line in enumerate(headers) if line.partition(':')[0].title() == name]):
            del headers[i]

    def __contains__(self, name):
        return name.title() in self.dict

    def __len__(self):
        return len(self.dict)

    def __iter__(self):
        return iter(self.dict)

    def __str__(self):
        return ''.join(self.headers)

gOptions = {}

gipWhiteList = []
domainWhiteList = [
    ".cn",
    "renren.com",
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
    "opswat.com"
    ]

def isIpBlocked(ip):
    if "BLOCKED_IPS" in gConfig:
        if ip in gConfig["BLOCKED_IPS"]:
            return True
    if "BLOCKED_IPS_M16" in gConfig:
        ipm16 = ".".join(ip.split(".")[:2])
        if ipm16 in gConfig["BLOCKED_IPS_M16"]:
            if gOptions.log > 0: print ip+" is blocked."
            return True
    if "BLOCKED_IPS_M24" in gConfig:
        ipm24 = ".".join(ip.split(".")[:3])
        if ipm24 in gConfig["BLOCKED_IPS_M24"]:
            if gOptions.log > 0: print ip+" is blocked."
            return True
    return False

def urlfetch(url, payload, method, headers, fetchhost, fetchserver, password=None, dns=None, on_error=None):
    errors = []
    params = {'url':url, 'method':method, 'headers':headers, 'payload':payload}
    params['fetchmax'] = '3'
    logging.debug('urlfetch params %s', params)
    if password:
        params['password'] = password
    if dns:
        params['dns'] = dns
    params =  '&'.join('%s=%s' % (k, binascii.b2a_hex(v)) for k, v in params.iteritems())
    for i in xrange(3):
        try:
            logging.debug('urlfetch %r by %r', url, fetchserver)
            request = urllib2.Request(fetchserver, zlib.compress(params, 9))
            request.add_header('Content-Type', '')
            response = urllib2.urlopen(request)
            compressed = response.read(1)

            data = {}
            if compressed == '0':
                data['code'], hlen, clen = struct.unpack('>3I', response.read(12))
                data['headers'] = SimpleMessageClass((k, binascii.a2b_hex(v)) for k, _, v in (x.partition('=') for x in response.read(hlen).split('&')))
                data['response'] = response
            elif compressed == '1':
                rawdata = zlib.decompress(response.read())
                data['code'], hlen, clen = struct.unpack('>3I', rawdata[:12])
                data['headers'] = SimpleMessageClass((k, binascii.a2b_hex(v)) for k, _, v in (x.partition('=') for x in rawdata[12:12+hlen].split('&')))
                data['content'] = rawdata[12+hlen:12+hlen+clen]
                response.close()
            else:
                raise ValueError('Data format not match(%s)' % url)

            return (0, data)
        except Exception, e:
            if on_error:
                logging.info('urlfetch error=%s on_error=%s', str(e), str(on_error))
                data = on_error(e)
                if data:
                    newfetch = (data.get('fetchhost'), data.get('fetchserver'))
                    if newfetch != (fetchhost, fetchserver):
                        (fetchhost, fetchserver) = newfetch
            errors.append(str(e))
            time.sleep(i+1)
            continue
    return (-1, errors)


class CertUtil(object):
    '''CertUtil module, based on WallProxy 0.4.0'''

    CA = None
    CALock = threading.Lock()

    SubjectAltNames = \
            'DNS: twitter.com, DNS: facebook.com, \
            DNS: *.twitter.com, DNS: *.twimg.com, \
            DNS: *.akamaihd.net, DNS: *.google.com, \
            DNS: *.facebook.com, DNS: *.ytimg.com, \
            DNS: *.appspot.com, DNS: *.google.com, \
            DNS: *.youtube.com, DNS: *.googleusercontent.com, \
            DNS: *.gstatic.com, DNS: *.live.com, \
            DNS: *.ak.fbcdn.net, DNS: *.ak.facebook.com, \
            DNS: *.android.com, DNS: *.fbcdn.net'

    @staticmethod
    def readFile(filename):
        content = None
        with open(filename, 'rb') as fp:
            content = fp.read()
        return content

    @staticmethod
    def writeFile(filename, content):
        with open(filename, 'wb') as fp:
            fp.write(str(content))

    @staticmethod
    def createKeyPair(type=None, bits=1024):
        if type is None:
            type = OpenSSL.crypto.TYPE_RSA
        pkey = OpenSSL.crypto.PKey()
        pkey.generate_key(type, bits)
        return pkey

    @staticmethod
    def createCertRequest(pkey, digest='sha1', **subj):
        req = OpenSSL.crypto.X509Req()
        subject = req.get_subject()
        for k,v in subj.iteritems():
            setattr(subject, k, v)
        req.set_pubkey(pkey)
        req.sign(pkey, digest)
        return req

    @staticmethod
    def createCertificate(req, (issuerKey, issuerCert), serial, (notBefore,
        notAfter), digest='sha1', host=None):
        cert = OpenSSL.crypto.X509()
        cert.set_version(3)
        cert.set_serial_number(serial)
        cert.gmtime_adj_notBefore(notBefore)
        cert.gmtime_adj_notAfter(notAfter)
        cert.set_issuer(issuerCert.get_subject())
        cert.set_subject(req.get_subject())
        cert.set_pubkey(req.get_pubkey())
        if CertUtil.SubjectAltNames:
            alts = CertUtil.SubjectAltNames
            if host is not None:
                alts += ", DNS: %s" % host
            cert.add_extensions([OpenSSL.crypto.X509Extension("subjectAltName",
                True, alts)])
        cert.sign(issuerKey, digest)
        return cert

    @staticmethod
    def loadPEM(pem, type):
        handlers = ('load_privatekey', 'load_certificate_request', 'load_certificate')
        return getattr(OpenSSL.crypto, handlers[type])(OpenSSL.crypto.FILETYPE_PEM, pem)

    @staticmethod
    def dumpPEM(obj, type):
        handlers = ('dump_privatekey', 'dump_certificate_request', 'dump_certificate')
        return getattr(OpenSSL.crypto, handlers[type])(OpenSSL.crypto.FILETYPE_PEM, obj)

    @staticmethod
    def makeCA():
        pkey = CertUtil.createKeyPair(bits=2048)
        subj = {'countryName': 'CN', 'stateOrProvinceName': 'Internet',
                'localityName': 'Cernet', 'organizationName': 'GoAgent',
                'organizationalUnitName': 'GoAgent Root', 'commonName': 'GoAgent CA'}
        req = CertUtil.createCertRequest(pkey, **subj)
        cert = CertUtil.createCertificate(req, (pkey, req), 0, (0, 60*60*24*7305))  #20 years
        return (CertUtil.dumpPEM(pkey, 0), CertUtil.dumpPEM(cert, 2))

    @staticmethod
    def makeCert(host, (cakey, cacrt), serial):
        pkey = CertUtil.createKeyPair()
        subj = {'countryName': 'CN', 'stateOrProvinceName': 'Internet',
                'localityName': 'Cernet', 'organizationName': host,
                'organizationalUnitName': 'GoAgent Branch', 'commonName': host}
        req = CertUtil.createCertRequest(pkey, **subj)
        cert = CertUtil.createCertificate(req, (cakey, cacrt), serial, (0,
            60*60*24*7305), host=host)
        return (CertUtil.dumpPEM(pkey, 0), CertUtil.dumpPEM(cert, 2))

    @staticmethod
    def getCertificate(host):
        basedir = os.path.dirname(__file__)
        keyFile = os.path.join(basedir, 'certs/%s.key' % host)
        crtFile = os.path.join(basedir, 'certs/%s.crt' % host)
        if os.path.exists(keyFile):
            return (keyFile, crtFile)
        if OpenSSL is None:
            keyFile = os.path.join(basedir, 'CA.key')
            crtFile = os.path.join(basedir, 'CA.crt')
            return (keyFile, crtFile)
        if not os.path.isfile(keyFile):
            with CertUtil.CALock:
                if not os.path.isfile(keyFile):
                    logging.info('CertUtil getCertificate for %r', host)
                    # FIXME: howto generate a suitable serial number?
                    for serial in (int(hashlib.md5(host).hexdigest(), 16), int(time.time()*100)):
                        try:
                            key, crt = CertUtil.makeCert(host, CertUtil.CA, serial)
                            CertUtil.writeFile(crtFile, crt)
                            CertUtil.writeFile(keyFile, key)
                            break
                        except Exception:
                            logging.exception('CertUtil.makeCert failed: host=%r, serial=%r', host, serial)
                    else:
                        keyFile = os.path.join(basedir, 'CA.key')
                        crtFile = os.path.join(basedir, 'CA.crt')
        return (keyFile, crtFile)

    @staticmethod
    def checkCA():
        #Check CA exists
        keyFile = os.path.join(os.path.dirname(__file__), 'CA.key')
        crtFile = os.path.join(os.path.dirname(__file__), 'CA.crt')
        if not os.path.exists(keyFile):
            if not OpenSSL:
                logging.critical('CA.crt is not exist and OpenSSL is disabled, ABORT!')
                sys.exit(-1)
            key, crt = CertUtil.makeCA()
            CertUtil.writeFile(keyFile, key)
            CertUtil.writeFile(crtFile, crt)
            [os.remove(os.path.join('certs', x)) for x in os.listdir('certs')]
        #Check CA imported
        cmd = {
                'win32'  : r'cd /d "%s" && certmgr.exe -add CA.crt -c -s -r localMachine Root >NUL' % os.path.dirname(__file__),
                #'darwin' : r'sudo security add-trusted-cert -d �Cr trustRoot �Ck /Library/Keychains/System.keychain CA.crt',
              }.get(sys.platform)
        if cmd and os.system(cmd) != 0:
            logging.warning('GoAgent install trusted root CA certificate failed, Please run goagent by administrator/root.')
        if OpenSSL:
            keyFile = os.path.join(os.path.dirname(__file__), 'CA.key')
            crtFile = os.path.join(os.path.dirname(__file__), 'CA.crt')
            cakey = CertUtil.readFile(keyFile)
            cacrt = CertUtil.readFile(crtFile)
            CertUtil.CA = (CertUtil.loadPEM(cakey, 0), CertUtil.loadPEM(cacrt, 2))


class ThreadingHTTPServer(ThreadingMixIn, HTTPServer): pass
class ProxyHandler(BaseHTTPRequestHandler):
    remote = None
    dnsCache = {}
    now = 0
    depth = 0
    MessageClass = SimpleMessageClass

    def enableInjection(self, host, ip):
        self.depth += 1
        if self.depth > 3:
            if gOptions.log>0: print host + " looping, exit"
            return

        global gipWhiteList;
        print "check "+host + " " + ip
        
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

        if host in grules:
            print ("Rule resolve: " + host + " => " + grules[host])
            return grules[host]

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
            ChinaUnicom404 = {
                "202.106.199.37" : 1,
                "202.106.195.30" : 1,
            }
            if ip in gConfig["BLACKHOLES"]:
                print ("Fake IP " + host + " => " + ip)
            elif ip in ChinaUnicom404:
                print ("ChinaUnicom404 " + host + " => " + ip + ", ignore")
            else:
                if gOptions.log > 1: 
                    print ("DNS system resolve: " + host + " => " + ip)
                if isIpBlocked(ip):
                    print (host + " => " + ip + " blocked, try remote resolve")
                    return self.getRemoteResolve(host, gConfig["REMOTE_DNS"])
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
        reqProtocol = "udp"
        if "DNS_PROTOCOL" in gConfig:
            if gConfig["DNS_PROTOCOL"] in ["udp", "tcp"]:
                reqProtocol = gConfig["DNS_PROTOCOL"]

        response = reqObj.req(name=host, qtype="A", protocol=reqProtocol, server=dnsserver)
        #response.show()
        #print "answers: " + str(response.answers)
        ip = ""
        blockedIp = ""
        cname = ""
        ttl = 0
        for a in response.answers:
            if a['typename'] == 'CNAME':
                cname = a["data"]
            else:
                ttl = a["ttl"]
                if isIpBlocked(a["data"]): 
                    print (host + " => " + a["data"]+" is blocked. ")
                    blockedIp = a["data"]
                    continue
                ip = a["data"]
        if (ip != ""):
            self.dnsCache[host] = {"ip":ip, "expire":self.now + ttl*2 + 60}
            return ip;
        if (blockedIp != ""):
            return blockedIp;
        if (cname != ""):
            return self.getip(cname)

        if gOptions.log > 1: print ("DNS remote resolve: " + host + " => " + str(a))
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
        inWhileList = False
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
            if (host in gConfig["BLOCKED_DOMAINS"]) or isIpBlocked(connectHost):
                gConfig["BLOCKED_DOMAINS"][host] = True
                if gOptions.log>0 : print "add ip "+ connectHost + " to block list"
                return self.do_METHOD_Tunnel()
            
            if True:
                for d in domainWhiteList:
                    if host.endswith(d):
                        if gOptions.log > 0: print host + " in domainWhiteList: " + d
                        inWhileList = True

                if not inWhileList:
                    doInject = self.enableInjection(host, connectHost)
                
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
                    self.headers["X-WCPasswd"] = gConfig["PROXY_PASSWD"]
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

                if doInject and (response.status == 400 or response.status == 405 or badStatusLine):
                    self.remote.close()
                    self.remote = None
                    if gOptions.log > 0: print host + " seem not support inject, " + msg
                    domainWhiteList.append(host)
                    return self.do_METHOD_Tunnel()

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
                if dataLength == 0 and (len(response_data) <= 501):
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
            if host in gConfig["HSTS_ON_EXCEPTION_DOMAINS"]:
                redirectUrl = "https://" + self.path[7:]
                self.wfile.write(status + "\r\n")
                self.wfile.write("Location: " + redirectUrl + "\r\n")

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
                        self.do_METHOD_Tunnel()
                        return
 
            print "error in proxy: ", self.requestline
            print exc_type
            print str(exc_value) + " " + host
            if exc_type == socket.timeout or (exc_type == socket.error and code in ["60", "110", "10060"]): #timed out, 10060 is for Windows
                if not inWhileList:
                    if gOptions.log > 0: print "add "+host+" to blocked domains"
                    gConfig["BLOCKED_DOMAINS"][host] = True

            return self.do_METHOD_Tunnel()
    
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
        ip = self.getip(host)
        try:
            if not isIpBlocked(ip):
                self.remote = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                print ("SSL: connect " + host + ":ip:" + ip)
                self.remote.connect((ip, int(port)))

                Agent = 'WCProxy/1.0'
                self.wfile.write('HTTP/1.1'+' 200 Connection established\n'+
                         'Proxy-agent: %s\n\n'%Agent)
                self._read_write()
                return
        except:
            pass
        self.do_CONNECT_Tunnel()

    def do_CONNECT_Tunnel(self):
        # for ssl proxy
        host, _, port = self.path.rpartition(':')
        keyFile, crtFile = CertUtil.getCertificate(host)
        self.connection.sendall('%s 200 OK\r\n\r\n' % self.protocol_version)
        try:
            import ssl
            self._realpath = self.path
            self._realrfile = self.rfile
            self._realwfile = self.wfile
            self._realconnection = self.connection
            self.connection = ssl.wrap_socket(self.connection, keyFile, crtFile, True)
            self.rfile = self.connection.makefile('rb', self.rbufsize)
            self.wfile = self.connection.makefile('wb', self.wbufsize)
            self.raw_requestline = self.rfile.readline(8192)
            if self.raw_requestline == '':
                return
            self.parse_request()
            if self.path[0] == '/':
                if 'Host' in self.headers:
                    self.path = 'https://%s:%s%s' % (self.headers['Host'].partition(':')[0], port or 443, self.path)
                else:
                    self.path = 'https://%s%s' % (self._realpath, self.path)
                self.requestline = '%s %s %s' % (self.command, self.path, self.protocol_version)
            self.do_METHOD_Tunnel()
        except socket.error, e:
            logging.exception('do_CONNECT_Tunnel socket.error: %s', e)
        finally:
            try:
                self.connection.shutdown(socket.SHUT_WR)
            except socket.error:
                pass
            self.rfile = self._realrfile
            self.wfile = self._realwfile
            self.connection = self._realconnection

    def end_error(self, code, message=None, data=None):
        if not data:
            self.send_error(code, message)
        else:
            self.send_response(code, message)
            self.connection.sendall(data)


    def do_METHOD_Tunnel(self):
        headers = self.headers
        host = headers.get('Host') or urlparse.urlparse(self.path).netloc.partition(':')[0]
        if self.path[0] == '/':
            self.path = 'http://%s%s' % (host, self.path)
        payload_len = int(headers.get('Content-Length', 0))
        if payload_len:
            payload = self.rfile.read(payload_len)
        else:
            payload = ''

        if 'Range' in headers.dict:
            autorange = headers.dict['Range']
            logging.info('autorange range=%r match url=%r', autorange, self.path)
            m = re.search('bytes=(\d+)-', autorange)
            start = int(m.group(1) if m else 0)
            headers['Range'] = 'bytes=%d-%d' % (start, start+1048576-1)

        skip_headers = frozenset(['Host', 'Vary', 'Via', 'X-Forwarded-For', 'Proxy-Authorization', 'Proxy-Connection', 'Upgrade', 'Keep-Alive'])
        strheaders = ''.join('%s: %s\r\n' % (k, v) for k, v in headers.iteritems() if k not in skip_headers)

        retval, data = self.fetch(self.path, payload, self.command, strheaders)
        try:
            if retval == -1:
                return self.end_error(502, str(data))
            code = data['code']
            headers = data['headers']
            self.log_request(code)
            if code == 206 and self.command=='GET':
                content_range = headers.get('Content-Range') or headers.get('content-range') or ''
                m = re.search(r'bytes\s+(\d+)-(\d+)/(\d+)', content_range)
                if m and self.rangefetch(m, data):
                    return
            content = '%s %d %s\r\n%s\r\n' % (self.protocol_version, code, self.responses.get(code, ('GoAgent Notify', ''))[0], headers)
            self.connection.sendall(content)
            try:
                self.connection.sendall(data['content'])
            except KeyError:
                #logging.info('OOPS, KeyError! Content-Type=%r', headers.get('Content-Type'))
                response = data['response']
                while 1:
                    content = response.read(8192)
                    if not content:
                        response.close()
                        break
                    self.connection.sendall(content)
            if 'close' == headers.get('Connection',''):
                self.close_connection = 1
        except socket.error, (err, _):
            # Connection closed before proxy return
            if err in (10053, errno.EPIPE):
                return

    def fetch(self, url, payload, method, headers):
        return urlfetch(url, payload, method, headers, gConfig['GOAGENT_FETCHHOST'], "https://" + gConfig["GOAGENT_FETCHHOST"] + "/fetch.py?", password=gConfig["GOAGENT_PASSWORD"])

    def rangefetch(self, m, data):
        m = map(int, m.groups())
        if 'range' in self.headers:
            content_range = 'bytes %d-%d/%d' % (m[0], m[1], m[2])
            req_range = re.search(r'(\d+)?-(\d+)?', self.headers['range'])
            if req_range:
                req_range = [u and int(u) for u in req_range.groups()]
                if req_range[0] is None:
                    if req_range[1] is not None:
                        if not (m[1]-m[0]+1==req_range[1] and m[1]+1==m[2]):
                            return False
                        if m[2] >= req_range[1]:
                            content_range = 'bytes %d-%d/%d' % (req_range[1], m[2]-1, m[2])
                else:
                    if req_range[1] is not None:
                        if not (m[0]==req_range[0] and m[1]==req_range[1]):
                            return False
                        if m[2] - 1 > req_range[1]:
                            content_range = 'bytes %d-%d/%d' % (req_range[0], req_range[1], m[2])
            data['headers']['Content-Range'] = content_range
            data['headers']['Content-Length'] = m[2]-m[0]
        elif m[0] == 0:
            data['code'] = 200
            data['headers']['Content-Length'] = m[2]
            del data['headers']['Content-Range']

        self.wfile.write('%s %d %s\r\n%s\r\n' % (self.protocol_version, data['code'], 'OK', data['headers']))
        if 'response' in data:
            response = data['response']
            bufsize = gConfig['AUTORANGE_BUFSIZE']
            if data['headers'].get('Content-Type', '').startswith('video/'):
                bufsize = gConfig['AUTORANGE_WAITSIZE']
            while 1:
                content = response.read(bufsize)
                if not content:
                    response.close()
                    break
                self.wfile.write(content)
                bufsize = gConfig['AUTORANGE_BUFSIZE']
        else:
            self.wfile.write(data['content'])

        start = m[1] + 1
        end   = m[2] - 1
        failed = 0
        logging.info('>>>>>>>>>>>>>>> Range Fetch started(%r)', self.headers.get('Host'))
        while start < end:
            if failed > 16:
                break
            self.headers['Range'] = 'bytes=%d-%d' % (start, min(start+gConfig['AUTORANGE_MAXSIZE']-1, end))
            retval, data = self.fetch(self.path, '', self.command, str(self.headers))
            if retval != 0 or data['code'] >= 400:
                failed += 1
                seconds = random.randint(2*failed, 2*(failed+1))
                logging.error('Range Fetch fail %d times, retry after %d secs!', failed, seconds)
                time.sleep(seconds)
                continue
            if 'Location' in data['headers']:
                logging.info('Range Fetch got a redirect location:%r', data['headers']['Location'])
                self.path = data['headers']['Location']
                failed += 1
                continue
            m = re.search(r'bytes\s+(\d+)-(\d+)/(\d+)', data['headers'].get('Content-Range',''))
            if not m:
                failed += 1
                logging.error('Range Fetch fail %d times, data[\'headers\']=%s', failed, data['headers'])
                continue
            start = int(m.group(2)) + 1
            logging.info('>>>>>>>>>>>>>>> %s %d' % (data['headers']['Content-Range'], end+1))
            failed = 0
            if 'response' in data:
                response = data['response']
                while 1:
                    content = response.read(gConfig['AUTORANGE_BUFSIZE'])
                    if not content:
                        response.close()
                        break
                    self.wfile.write(content)
            else:
                self.wfile.write(data['content'])
        logging.info('>>>>>>>>>>>>>>> Range Fetch ended(%r)', self.headers.get('Host'))
        return True


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
            if isIpBlocked(d[0]) : 
                print (d[1]+"  ("+d[0] + ") blocked, skipping")
                continue
            grules[d[1]] = d[0]
        s.close()
    except:
        print "read onine hosts fail"
    
    try:
        import json
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

    httplib.HTTPMessage = SimpleMessageClass
    CertUtil.checkCA()
    print "Loaded", len(grules), " dns rules."
    print "Set your browser's HTTP/HTTPS proxy to 127.0.0.1:%d"%(gOptions.port)
    server = ThreadingHTTPServer(("0.0.0.0", gOptions.port), ProxyHandler)
    try: server.serve_forever()
    except KeyboardInterrupt: exit()
    
if __name__ == "__main__":
    try :
        import json
        s = open("config.json")
        jsonConfig = json.loads( s.read() )
        for k in jsonConfig:
            print "read json config " + k + " => " + str(jsonConfig[k])
            gConfig[k] = jsonConfig[k]
    except:
        print "Load json config failed"

    try :
        if sys.version[:3] in ('2.7', '3.0', '3.1', '3.2', '3.3'):
            import argparse
            parser = argparse.ArgumentParser(description='west chamber proxy')
            parser.add_argument('--port', default=gConfig["LOCAL_PORT"], type=int,
                   help='local port')
            parser.add_argument('--log', default=1, type=int, help='log level, 0-3')
            parser.add_argument('--pidfile', default='', help='pid file')
            gOptions = parser.parse_args()
        else:
            import optparse
            parser = optparse.OptionParser()
            parser.add_option("-p", "--port", action="store", type="int", dest="port", default=gConfig["LOCAL_PORT"], help="local port")
            parser.add_option("-l", "--log", action="store", type="int", dest="log", default=1, help="log level, 0-3")
            parser.add_option("-f", "--pidfile", dest="pidfile", default="", help="pid file")
            (gOptions, args)=parser.parse_args()

    except :
        #arg parse error
        print "arg parse error"
        class option:
            def __init__(self): 
                self.log = 1
                self.port = gConfig["LOCAL_PORT"]
                self.pidfile = ""
        gOptions = option()

    if gOptions.pidfile != "":
        pid = str(os.getpid())
        f = open(gOptions.pidfile,'w')
        print "Writing pid " + pid + " to "+gOptions.pidfile
        f.write(pid)
        f.close()
    start()
