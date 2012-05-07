#!/usr/bin/env python
# coding=utf-8
# Based on GAppProxy by Du XiaoGang <dugang@188.com>
# Based on WallProxy 0.4.0 by hexieshe <www.ehust@gmail.com>

__version__ = '1.8.5'
__author__ =  'phus.lu@gmail.com'
__password__ = ''

import sys, os, re, time, struct, zlib, binascii, logging
try:
    from google.appengine.api import urlfetch
    from google.appengine.runtime import apiproxy_errors, DeadlineExceededError
except ImportError:
    urlfetch = None

FetchMax = 3
FetchMaxSize = 1024*1024*4
Deadline = 30

def encode_data(dic):
    return '&'.join('%s=%s' % (k, binascii.b2a_hex(v)) for k, v in dic.iteritems() if v)

def decode_data(qs):
    return dict((k, binascii.a2b_hex(v)) for k, _, v in (x.partition('=') for x in qs.split('&')))

def send_response(start_response, status, headers, content):
    strheaders = encode_data(headers)
    #logging.debug('response status=%s, headers=%s, content length=%d', status, headers, len(content))
    if headers.get('content-type', '').startswith(('text/', 'application/json', 'application/javascript')):
        data = '1' + zlib.compress('%s%s%s' % (struct.pack('>3I', status, len(strheaders), len(content)), strheaders, content))
    else:
        data = '0%s%s%s' % (struct.pack('>3I', status, len(strheaders), len(content)), strheaders, content)
    start_response('200 OK', [('Content-type', 'image/gif')])
    return [data]

def send_notify(start_response, method, url, status, content):
    logging.warning('%r Failed: url=%r, status=%r', method, url, status)
    content = '<h2>Python Server Fetch Info</h2><hr noshade="noshade"><p>%s %r</p><p>Return Code: %d</p><p>Message: %s</p>' % (method, url, status, content)
    send_response(start_response, status, {'content-type':'text/html'}, content)

def paas_post(environ, start_response):
    import httplib, urlparse

    request = decode_data(zlib.decompress(environ['wsgi.input'].read(int(environ.get('CONTENT_LENGTH') or -1))))
    #logging.debug('post() get fetch request %s', request)

    method = request['method']
    url = request['url']
    payload = request['payload'] or None

    if __password__ and __password__ != request.get('password', ''):
        return send_notify(start_response, method, url, 403, 'Wrong password.')

    deadline = Deadline

    headers = dict((k.title(), v.lstrip()) for k, _, v in (line.partition(':') for line in request['headers'].splitlines()))
    headers['Connection'] = 'close'

    errors = []

    scheme, netloc, path, params, query, fragment = urlparse.urlparse(url)
    HTTPConnection = httplib.HTTPSConnection if scheme == 'https' else httplib.HTTPConnection
    if params:
        path += ';' + params
    if query:
        path += '?' + query
    for i in xrange(int(request.get('fetchmax', FetchMax))):
        try:
            conn = HTTPConnection(netloc, timeout=deadline)
            conn.request(method, path, body=payload, headers=headers)
            response = conn.getresponse()
            break
        except Exception, e:
            errors.append(str(e))
            time.sleep(1)
            if i==0 and method=='GET':
                deadline = Deadline * 2
    else:
        return send_notify(start_response, method, url, 500, 'Python PaaS Server: HTTPConnection error: %s' % errors)

    headers = {}
    for key, value in response.getheaders():
        if key == 'set-cookie':
            headers['set-cookie'] = headers.get('set-cookie', '') + '\r\nSet-Cookie: %s' % value
        else:
            headers[key] = value
    headers['connection'] = 'close'

    return send_response(start_response, response.status, headers, response.read())

def paas_get(environ, start_response):
    redirect_url = 'http://www.google.cn/webhp?source=g_cn'
    start_response('302 Found', [('Location', redirect_url)])
    return ['']

def gae_post(environ, start_response):
    request = decode_data(zlib.decompress(environ['wsgi.input'].read(int(environ['CONTENT_LENGTH']))))
    #logging.debug('post() get fetch request %s', request)

    method = request['method']
    url = request['url']
    payload = request['payload']

    if __password__ and __password__ != request.get('password', ''):
        return send_notify(start_response, method, url, 403, 'Wrong password.')

    fetchmethod = getattr(urlfetch, method, '')
    if not fetchmethod:
        return send_notify(start_response, method, url, 501, 'Invalid Method')

    if 'http' != url[:4]:
        return send_notify(start_response, method, url, 501, 'Unsupported Scheme')

    deadline = Deadline

    headers = dict((k.title(), v.lstrip()) for k, _, v in (line.partition(':') for line in request['headers'].splitlines()))
    headers['Connection'] = 'close'

    errors = []
    for i in xrange(int(request.get('fetchmax', FetchMax))):
        try:
            response = urlfetch.fetch(url, payload, fetchmethod, headers, False, False, deadline, False)
            break
        except apiproxy_errors.OverQuotaError, e:
            time.sleep(4)
        except DeadlineExceededError, e:
            errors.append(str(e))
            logging.error('DeadlineExceededError(deadline=%s, url=%r)', deadline, url)
            time.sleep(1)
            deadline = Deadline * 2
        except urlfetch.DownloadError, e:
            errors.append(str(e))
            logging.error('DownloadError(deadline=%s, url=%r)', deadline, url)
            time.sleep(1)
            deadline = Deadline * 2
        except urlfetch.InvalidURLError, e:
            return send_notify(start_response, method, url, 501, 'Invalid URL: %s' % e)
        except urlfetch.ResponseTooLargeError, e:
            response = e.response
            logging.error('DownloadError(deadline=%s, url=%r) response(%s)', deadline, url, response and response.headers)
            if response and response.headers.get('content-length'):
                response.status_code = 206
                response.headers['accept-ranges']  = 'bytes'
                response.headers['content-range']  = 'bytes 0-%d/%s' % (len(response.content)-1, response.headers['content-length'])
                response.headers['content-length'] = len(response.content)
                break
            else:
                headers['Range'] = 'bytes=0-%d' % FetchMaxSize
            deadline = Deadline * 2
        except Exception, e:
            errors.append(str(e))
            if i==0 and method=='GET':
                deadline = Deadline * 2
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
    headers['connection'] = 'close'
    return send_response(start_response, response.status_code, headers, response.content)

def gae_get(environ, start_response):
    timestamp = long(os.environ['CURRENT_VERSION_ID'].split('.')[1])/pow(2,28)
    ctime = time.strftime('%Y-%m-%d %H:%M:%S', time.gmtime(timestamp+8*3600))
    html = u'GoAgent Python Server %s 已经在工作了，部署时间 %s\n' % (__version__, ctime)
    start_response('200 OK', [('Content-type', 'text/plain; charset=utf-8')])
    return [html.encode('utf8')]

def application(environ, start_response):
    if urlfetch and environ['REQUEST_METHOD'] == 'POST':
        return gae_post(environ, start_response)
    elif environ['REQUEST_METHOD'] == 'POST':
        return paas_post(environ, start_response)
    elif urlfetch and environ['REQUEST_METHOD'] == 'GET':
        return gae_get(environ, start_response)
    else:
        return paas_get(environ, start_response)

if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO, format='%(levelname)s - - %(asctime)s %(message)s', datefmt='[%b %d %H:%M:%S]')
    import gevent, gevent.pywsgi, gevent.monkey
    gevent.monkey.patch_all(dns=gevent.version_info[0]>=1)
    def WSGIHandler_read_requestline(self):
        line = self.rfile.readline(8192)
        while line == '\r\n':
            line = self.rfile.readline(8192)
        return line
    gevent.pywsgi.WSGIHandler.read_requestline = WSGIHandler_read_requestline
    server = gevent.pywsgi.WSGIServer(('', 80), application)
    logging.info('serving http://%s:%s/wsgi.py', server.address[0] or '0.0.0.0', server.address[1])
    server.serve_forever()

