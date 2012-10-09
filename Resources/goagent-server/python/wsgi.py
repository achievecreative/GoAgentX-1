#!/usr/bin/env python
# coding=utf-8
# Contributor:
#      Phus Lu        <phus.lu@gmail.com>

__version__ = '2.0.12'
__password__ = ''
__hostsdeny__ = ()  # __hostsdeny__ = ('.youtube.com', '.youku.com')

import sys
import os
import re
import time
import struct
import zlib
import binascii
import logging
import httplib
import urlparse
import base64
import cStringIO
import hashlib
import errno
try:
    from google.appengine.api import urlfetch
    from google.appengine.runtime import apiproxy_errors
except ImportError:
    urlfetch = None
try:
    import sae
except ImportError:
    sae = None
try:
    import socket, select, ssl, thread
except:
    socket = None

FetchMax = 2
FetchMaxSize = 1024*1024*4
DeflateMaxSize = 1024*1024*4
Deadline = 60

def httplib_request(method, url, body=None, headers={}, timeout=None):
    scheme, netloc, path, params, query, fragment = urlparse.urlparse(url)
    HTTPConnection = httplib.HTTPSConnection if scheme == 'https' else httplib.HTTPConnection
    if params:
        path += ';' + params
    if query:
        path += '?' + query
    conn = HTTPConnection(netloc, timeout=timeout)
    conn.request(method, path, body=body, headers=headers)
    response = conn.getresponse()
    return response

def encode_request(headers, **kwargs):
    if hasattr(headers, 'items'):
        headers = headers.items()
    data = ''.join('%s: %s\r\n' % (k, v) for k, v in headers) + ''.join('X-Goa-%s: %s\r\n' % (k.title(), v) for k, v in kwargs.iteritems())
    return base64.b64encode(zlib.compress(data)).rstrip()

def decode_request(request):
    data     = zlib.decompress(base64.b64decode(request))
    headers  = []
    kwargs   = {}
    for line in data.splitlines():
        keyword, _, value = line.partition(':')
        if keyword.startswith('X-Goa-'):
            kwargs[keyword[6:].lower()] = value.strip()
        else:
            headers.append((keyword.title(), value.strip()))
    return headers, kwargs

def paas_application(environ, start_response):
    try:
        headers, kwargs = decode_request(environ['HTTP_COOKIE'])
    except Exception as e:
        logging.exception("decode_request(environ['HTTP_COOKIE']=%r) failed: %s", environ.get('HTTP_COOKIE'), e)
        raise

    if __password__ and __password__ != kwargs.get('password'):
        url = 'https://goa%d%s' % (int(time.time()*100), environ['HTTP_HOST'])
        response = httplib_request('GET', url, timeout=5)
        status_line = '%s %s' % (response.status, httplib.responses.get(response.status, 'OK'))
        start_response(status_line, response.getheaders())
        yield response.read()
        raise StopIteration

    method  = kwargs['method']
    url     = kwargs['url']
    timeout = Deadline

    logging.info('%s "%s %s %s" - -', environ['REMOTE_ADDR'], method, url, 'HTTP/1.1')

    if method != 'CONNECT':
        try:
            headers = dict(headers)
            headers['Connection'] = 'close'
            data = environ['wsgi.input'] if int(headers.get('Content-Length',0)) else None
            response = httplib_request(method, url, body=data, headers=headers, timeout=timeout)
            response_headers = dict(response.getheaders())
            response_headers['connection'] = 'close'
            response_headers.pop('transfer-encoding', '')
            start_response('%s OK' % response.status, response_headers.items())
            bufsize = 8192
            while 1:
                data = response.read(bufsize)
                if not data:
                    response.close()
                    break
                yield data
        except httplib.HTTPException as e:
            raise

def socket_forward(local, remote, timeout=60, tick=2, bufsize=8192, maxping=None, maxpong=None, idlecall=None, trans=''):
    timecount = timeout
    try:
        while 1:
            timecount -= tick
            if timecount <= 0:
                break
            (ins, _, errors) = select.select([local, remote], [], [local, remote], tick)
            if errors:
                break
            if ins:
                for sock in ins:
                    data = sock.recv(bufsize)
                    if trans:
                        data = data.translate(trans)
                    if data:
                        if sock is local:
                            remote.sendall(data)
                            timecount = maxping or timeout
                        else:
                            local.sendall(data)
                            timecount = maxpong or timeout
                    else:
                        return
            else:
                if idlecall:
                    try:
                        idlecall()
                    except Exception:
                        logging.exception('socket_forward idlecall fail')
                    finally:
                        idlecall = None
    except Exception:
        logging.exception('socket_forward error')
        raise
    finally:
        if idlecall:
            idlecall()

def socks5_handler(sock, address):
    bufsize = 8192
    rfile = sock.makefile('rb', bufsize)
    wfile = sock.makefile('wb', 0)
    remote_addr, remote_port = address
    MessageClass = dict
    try:
        line = rfile.readline(bufsize)
        if not line:
            raise socket.error('empty line')
        method, path, version = line.rstrip().split(' ', 2)
        headers = MessageClass()
        while 1:
            line = rfile.readline(bufsize)
            if not line or line == '\r\n':
                break
            keyword, _, value = line.partition(':')
            keyword = keyword.title()
            value = value.strip()
            headers[keyword] = value
        logging.info('%s:%s "%s %s %s" - -', remote_addr, remote_port, method, path, version)
        if headers.get('Connection', '').lower() != 'upgrade':
            logging.error('%s:%s Connection(%s) != "upgrade"', remote_addr, remote_port, headers.get('Connection'))
            return

        #wfile.write('HTTP/1.1 101 Switching Protocols\r\nConnection: Upgrade\r\n\r\n')

        transtable = ''.join(chr(x%256) for x in xrange(-128, 128))
        rfile_read  = lambda x:rfile.read(x).translate(transtable)
        wfile_write = lambda x:wfile.write(x.translate(transtable))

        rfile_read(ord(rfile_read(2)[-1]))
        wfile_write(b'\x05\x00');
        # 2. Request
        data = rfile_read(4)
        mode = ord(data[1])
        addrtype = ord(data[3])
        if addrtype == 1:       # IPv4
            addr = socket.inet_ntoa(rfile_read(4))
        elif addrtype == 3:     # Domain name
            addr = rfile_read(ord(rfile_read(1)[0]))
        port = struct.unpack('>H',rfile_read(2))
        reply = b'\x05\x00\x00\x01'
        try:
            logging.info('%s:%s socks5 mode=%r', remote_addr, remote_port, mode)
            if mode == 1:  # 1. TCP Connect
                remote = socket.create_connection((addr, port[0]))
                logging.info('%s:%s TCP Connect to %s:%s', remote_addr, remote_port, addr, port[0])
                local = remote.getsockname()
                reply += socket.inet_aton(local[0]) + struct.pack(">H", local[1])
            else:
                reply = b'\x05\x07\x00\x01' # Command not supported
        except socket.error:
            # Connection refused
            reply = '\x05\x05\x00\x01\x00\x00\x00\x00\x00\x00'
        wfile_write(reply)
        # 3. Transfering
        if reply[1] == '\x00':  # Success
            if mode == 1:    # 1. Tcp connect
                socket_forward(sock, remote, trans=transtable)
    except socket.error as e:
        if e[0] not in (10053, errno.EPIPE, 'empty line'):
            raise
    finally:
        rfile.close()
        wfile.close()
        sock.close()

def send_response(start_response, status, headers, content, content_type='image/gif'):
    headers['Content-Length'] = str(len(content))
    strheaders = '&'.join('%s=%s' % (k, binascii.b2a_hex(v)) for k, v in headers.iteritems() if v)
    #logging.debug('response status=%s, headers=%s, content length=%d', status, headers, len(content))
    if headers.get('content-type', '').startswith(('text/', 'application/json', 'application/javascript')):
        data = '1' + zlib.compress('%s%s%s' % (struct.pack('>3I', status, len(strheaders), len(content)), strheaders, content))
    else:
        data = '0%s%s%s' % (struct.pack('>3I', status, len(strheaders), len(content)), strheaders, content)
    start_response('200 OK', [('Content-type', content_type)])
    return [data]

def send_notify(start_response, method, url, status, content):
    logging.warning('%r Failed: url=%r, status=%r', method, url, status)
    content = '<h2>Python Server Fetch Info</h2><hr noshade="noshade"><p>%s %r</p><p>Return Code: %d</p><p>Message: %s</p>' % (method, url, status, content)
    send_response(start_response, status, {'content-type':'text/html'}, content)

def gae_post(environ, start_response):
    data = zlib.decompress(environ['wsgi.input'].read(int(environ['CONTENT_LENGTH'])))
    request = dict((k,binascii.a2b_hex(v)) for k, _, v in (x.partition('=') for x in data.split('&')))
    #logging.debug('post() get fetch request %s', request)

    method = request['method']
    url = request['url']
    payload = request['payload']

    if __password__ and __password__ != request.get('password', ''):
        return send_notify(start_response, method, url, 403, 'Wrong password.')

    if __hostsdeny__ and urlparse.urlparse(url).netloc.endswith(__hostsdeny__):
        return send_notify(start_response, method, url, 403, 'Hosts Deny: url=%r' % url)

    fetchmethod = getattr(urlfetch, method, '')
    if not fetchmethod:
        return send_notify(start_response, method, url, 501, 'Invalid Method')

    deadline = Deadline

    headers = dict((k.title(),v.lstrip()) for k, _, v in (line.partition(':') for line in request['headers'].splitlines()))
    headers['Connection'] = 'close'

    errors = []
    for i in xrange(FetchMax if 'fetchmax' not in request else int(request['fetchmax'])):
        try:
            response = urlfetch.fetch(url, payload, fetchmethod, headers, False, False, deadline, False)
            break
        except apiproxy_errors.OverQuotaError as e:
            time.sleep(4)
        except urlfetch.DeadlineExceededError as e:
            errors.append('DeadlineExceededError %s(deadline=%s)' % (e, deadline))
            logging.error('DeadlineExceededError(deadline=%s, url=%r)', deadline, url)
            time.sleep(1)
        except urlfetch.DownloadError as e:
            errors.append('DownloadError %s(deadline=%s)' % (e, deadline))
            logging.error('DownloadError(deadline=%s, url=%r)', deadline, url)
            time.sleep(1)
        except urlfetch.InvalidURLError as e:
            return send_notify(start_response, method, url, 501, 'Invalid URL: %s' % e)
        except urlfetch.ResponseTooLargeError as e:
            response = e.response
            logging.error('ResponseTooLargeError(deadline=%s, url=%r) response(%r)', deadline, url, response)
            m = re.search(r'=\s*(\d+)-', headers.get('Range') or headers.get('range') or '')
            if m is None:
                headers['Range'] = 'bytes=0-%d' % FetchMaxSize
            else:
                headers.pop('Range', '')
                headers.pop('range', '')
                start = int(m.group(1))
                headers['Range'] = 'bytes=%s-%d' % (start, start+FetchMaxSize)
            deadline = Deadline * 2
        except Exception as e:
            errors.append('Exception %s(deadline=%s)' % (e, deadline))
    else:
        return send_notify(start_response, method, url, 500, 'Python Server: Urlfetch error: %s' % errors)

    headers = response.headers
    if 'set-cookie' in headers:
        scs = headers['set-cookie'].split(', ')
        cookies = []
        i = -1
        for sc in scs:
            if re.match(r'[^ =]+ ', sc):
                try:
                    cookies[i] = '%s, %s' % (cookies[i], sc)
                except IndexError:
                    pass
            else:
                cookies.append(sc)
                i += 1
        headers['set-cookie'] = '\r\nSet-Cookie: '.join(cookies)
    if 'content-length' not in headers:
        headers['content-length'] = str(len(response.content))
    headers['connection'] = 'close'
    return send_response(start_response, response.status_code, headers, response.content)

def gae_error_html(**kwargs):
    GAE_ERROR_TEMPLATE = '''
<html><head>
<meta http-equiv="content-type" content="text/html;charset=utf-8">
<title>{{errno}} {{error}}</title>
<style><!--
body {font-family: arial,sans-serif}
div.nav {margin-top: 1ex}
div.nav A {font-size: 10pt; font-family: arial,sans-serif}
span.nav {font-size: 10pt; font-family: arial,sans-serif; font-weight: bold}
div.nav A,span.big {font-size: 12pt; color: #0000cc}
div.nav A {font-size: 10pt; color: black}
A.l:link {color: #6f6f6f}
A.u:link {color: green}
//--></style>

</head>
<body text=#000000 bgcolor=#ffffff>
<table border=0 cellpadding=2 cellspacing=0 width=100%>
<tr><td bgcolor=#3366cc><font face=arial,sans-serif color=#ffffff><b>Error</b></td></tr>
<tr><td>&nbsp;</td></tr></table>
<blockquote>
<H1>{{error}}</H1>
{{description}}

<p>
</blockquote>
<table width=100% cellpadding=0 cellspacing=0><tr><td bgcolor=#3366cc><img alt="" width=1 height=4></td></tr></table>
</body></html>
'''
    for keyword, value in kwargs.items():
        GAE_ERROR_TEMPLATE = GAE_ERROR_TEMPLATE.replace('{{%s}}' % keyword, value)
    return GAE_ERROR_TEMPLATE


def gae_post_ex(environ, start_response):
    headers, kwargs = decode_request(environ['HTTP_COOKIE'])

    method = kwargs['method']
    url    = kwargs['url']

    #logging.info('%s "%s %s %s" - -', environ['REMOTE_ADDR'], method, url, 'HTTP/1.1')

    if __password__ and __password__ != kwargs.get('password', ''):
        start_response('403 Forbidden', [('Content-Type', 'text/html')])
        return [gae_error_html(errno='403', error='Wrong password.', description='GoAgent proxy.ini password is wrong!')]

    if __hostsdeny__ and urlparse.urlparse(url).netloc.endswith(__hostsdeny__):
        start_response('403 Forbidden', [('Content-Type', 'text/html')])
        return [gae_error_html(errno='403', error='Hosts Deny', description='url=%r' % url)]

    fetchmethod = getattr(urlfetch, method, '')
    if not fetchmethod:
        start_response('501 Unsupported', [('Content-Type', 'text/html')])
        return [gae_error_html(errno='501', error=('Invalid Method: '+str(method)), description='Unsupported Method')]

    deadline = Deadline
    headers = dict(headers)
    headers['Connection'] = 'close'
    payload = environ['wsgi.input'].read() if 'Content-Length' in headers else None

    accept_encoding = headers.get('Accept-Encoding', '')

    errors = []
    for i in xrange(int(kwargs.get('fetchmax', FetchMax))):
        try:
            response = urlfetch.fetch(url, payload, fetchmethod, headers, allow_truncated=False, follow_redirects=False, deadline=deadline, validate_certificate=False)
            break
        except apiproxy_errors.OverQuotaError as e:
            time.sleep(4)
        except urlfetch.DeadlineExceededError as e:
            errors.append('DeadlineExceededError %s(deadline=%s)' % (e, deadline))
            logging.error('DeadlineExceededError(deadline=%s, url=%r)', deadline, url)
            time.sleep(1)
            deadline = Deadline * 2
        except urlfetch.DownloadError as e:
            errors.append('DownloadError %s(deadline=%s)' % (e, deadline))
            logging.error('DownloadError(deadline=%s, url=%r)', deadline, url)
            time.sleep(1)
            deadline = Deadline * 2
        except urlfetch.ResponseTooLargeError as e:
            response = e.response
            logging.error('ResponseTooLargeError(deadline=%s, url=%r) response(%r)', deadline, url, response)
            m = re.search(r'=\s*(\d+)-', headers.get('Range') or headers.get('range') or '')
            if m is None:
                headers['Range'] = 'bytes=0-%d' % int(kwargs.get('fetchmaxsize', FetchMaxSize))
            else:
                headers.pop('Range', '')
                headers.pop('range', '')
                start = int(m.group(1))
                headers['Range'] = 'bytes=%s-%d' % (start, start+int(kwargs.get('fetchmaxsize', FetchMaxSize)))
            deadline = Deadline * 2
        except Exception as e:
            errors.append(str(e))
            if i==0 and method=='GET':
                deadline = Deadline * 2
    else:
        start_response('500 Internal Server Error', [('Content-Type', 'text/html')])
        return [gae_error_html(errno='502', error=('Python Urlfetch Error: ' + str(method)), description='<br />\n'.join(errors) or 'UNKOWN')]

    #logging.debug('url=%r response.status_code=%r response.headers=%r response.content[:1024]=%r', url, response.status_code, dict(response.headers), response.content[:1024])

    data = response.content
    if 'content-encoding' not in response.headers and len(response.content) < DeflateMaxSize and response.headers.get('content-type', '').startswith(('text/', 'application/json', 'application/javascript')):
        if 'deflate' in accept_encoding:
            response.headers['Content-Encoding'] = 'deflate'
            data = zlib.compress(data)[2:-4]
        elif 'gzip' in accept_encoding:
            response.headers['Content-Encoding'] = 'gzip'
            compressobj = zlib.compressobj(zlib.Z_DEFAULT_COMPRESSION, zlib.DEFLATED, -zlib.MAX_WBITS, zlib.DEF_MEM_LEVEL, 0)
            dataio = cStringIO.StringIO()
            dataio.write('\x1f\x8b\x08\x00\x00\x00\x00\x00\x02\xff')
            dataio.write(compressobj.compress(data))
            dataio.write(compressobj.flush())
            dataio.write(struct.pack('<LL', zlib.crc32(data)&0xFFFFFFFFL, len(data)&0xFFFFFFFFL))
            data = dataio.getvalue()
    response.headers['Content-Length'] = str(len(data))
    start_response('200 OK', [('Content-Type', 'image/gif'), ('Set-Cookie', encode_request(response.headers, status=str(response.status_code)))])
    return [data]

def gae_get(environ, start_response):
    if '204' in environ['QUERY_STRING']:
        start_response('204 No Content', [])
        return ''
    timestamp = long(os.environ['CURRENT_VERSION_ID'].split('.')[1])/pow(2,28)
    ctime = time.strftime('%Y-%m-%d %H:%M:%S', time.gmtime(timestamp+8*3600))
    html = u'GoAgent Python Server %s \u5df2\u7ecf\u5728\u5de5\u4f5c\u4e86\uff0c\u90e8\u7f72\u65f6\u95f4 %s\n' % (__version__, ctime)
    start_response('200 OK', [('Content-Type', 'text/plain; charset=utf-8')])
    return [html.encode('utf8')]

def app(environ, start_response):
    if urlfetch and environ['REQUEST_METHOD'] == 'POST':
        if environ.get('HTTP_COOKIE'):
            return gae_post_ex(environ, start_response)
        else:
            return gae_post(environ, start_response)
    elif not urlfetch:
        return paas_application(environ, start_response)
    else:
        return gae_get(environ, start_response)

application = app if sae is None else sae.create_wsgi_app(app)

if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO, format='%(levelname)s - - %(asctime)s %(message)s', datefmt='[%b %d %H:%M:%S]')
    import gevent, gevent.server, gevent.wsgi, gevent.monkey, getopt
    gevent.monkey.patch_all(dns=gevent.version_info[0]>=1)

    options = dict(getopt.getopt(sys.argv[1:], 'l:p:a:')[0])
    host = options.get('-l', '0.0.0.0')
    port = options.get('-p', '23')
    app  = options.get('-a', 'socks5')

    if app == 'socks5':
        server = gevent.server.StreamServer((host, int(port)), socks5_handler)
    else:
        server = gevent.wsgi.WSGIServer((host, int(port)), paas_application)

    logging.info('serving %s at http://%s:%s/', app.upper(), server.address[0], server.address[1])
    server.serve_forever()


