// Copyright 2012 Phus Lu. All rights reserved.

package fetch

import (
    "fmt"
	"bytes"
	"strings"
	"strconv"
	"regexp"
	"time"
    "io/ioutil"
	"compress/zlib"
	"encoding/binary"
	"encoding/hex"
	"net/http"

	"appengine"
	"appengine/urlfetch"
)

const (
	Version  = "1.8.2"
	Author   = "phus.lu@gmail.com"
	Password = ""

	FetchMax     = 3
	FetchMaxSize = 1024 * 1024 * 4
	Deadline int64 = 30 *1e9
)

func encodeData(dic map[string]string) []byte {
	w := bytes.NewBufferString("")
	for k, v := range dic {
	    if len(v) != 0 {
		    fmt.Fprintf(w, "&%s=%s", k, hex.EncodeToString([]byte(v)))
		}
	}
	return w.Bytes()[1:]
}

func decodeData(qs []byte) map[string]string {
	m := make(map[string]string)
	for _, kv := range strings.Split(string(qs), "&") {
		if kv != "" {
			pair := strings.Split(kv, "=")
			value, _ := hex.DecodeString(pair[1])
			m[pair[0]] = string(value)
		}
	}
	return m
}

type Handler struct {
	response http.ResponseWriter
	request  *http.Request
	context  appengine.Context
	http.Handler
}

func (h Handler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	h.response = w
	h.request = r
	h.context = appengine.NewContext(r)
	if r.Method == "POST" {
		h.post()
	} else {
		h.get()
	}
}

func (h Handler) printResponse(status int, header map[string]string, content []byte) {
	headerEncoded := encodeData(header)

	h.response.WriteHeader(200)
	h.response.Header().Set("Content-Type", "image/gif")

    compressed := false
	if contentType, ok := header["content-type"]; ok {
	    if strings.HasPrefix(contentType, "text/") || strings.HasPrefix(contentType, "application/json") || strings.HasPrefix(contentType, "application/javascript") {
	        compressed = true
	    }
	}

	if compressed {
		h.response.Write([]byte("1"))
		w, err := zlib.NewWriterLevel(h.response, zlib.BestCompression)
		if err != nil {
			h.context.Criticalf("zlib.NewWriterLevel(h.response, zlib.BestCompression) Error: %v", err)
			return
		}
		defer w.Close()
		binary.Write(w, binary.BigEndian, uint32(status))
		binary.Write(w, binary.BigEndian, uint32(len(headerEncoded)))
		binary.Write(w, binary.BigEndian, uint32(len(content)))
		w.Write(headerEncoded)
		w.Write(content)
	} else {
		h.response.Write([]byte("0"))
		binary.Write(h.response, binary.BigEndian, uint32(status))
		binary.Write(h.response, binary.BigEndian, uint32(len(headerEncoded)))
		binary.Write(h.response, binary.BigEndian, uint32(len(content)))
		h.response.Write(headerEncoded)
		h.response.Write(content)
	}
}

func (h Handler) printNotify(method string, url string, status int, text string) {
	content := []byte(fmt.Sprintf("<h2>Go Server Fetch Info</h2><hr noshade='noshade'><p>%s '%s'</p><p>Return Code: %d</p><p>Message: %s</p>", method, url, status, text))
	headers := map[string]string{"content-type": "text/html"}
	h.printResponse(status, headers, content)
}

func (h Handler) post() {
	r, err := zlib.NewReader(h.request.Body)
	if err != nil {
		h.context.Criticalf("zlib.NewReader(h.request.Body) Error: %v", err)
		return
	}
	defer r.Close()
	data, err := ioutil.ReadAll(r)
	if err != nil {
		h.context.Criticalf("ioutil.ReadAll(r) Error: %v", err)
		return
	}
	request := decodeData(data)

	method := request["method"]
	url := request["url"]
	headers := request["headers"]

	if Password != "" {
		password, ok := request["password"]
		if !ok || password != Password {
			h.printNotify(method, url, 403, " Wrong Password.")
		}
	}

	if !strings.HasPrefix(url, "http") {
		h.printNotify(method, url, 501, "Unsupported Scheme")
	}

	payload := request["payload"]
	req, err := http.NewRequest(method, url, bytes.NewBufferString(payload))
	if err != nil {
		h.printNotify(method, url, 500, "http.NewRequest(method, url, payload) failed")
	}

	for _, line := range strings.Split(headers, "\r\n") {
		kv := strings.SplitN(line, ":", 2)
		if len(kv) == 2 {
		    req.Header.Set(strings.Title(kv[0]), strings.TrimSpace(kv[1]))
		}
	}

	fetchmax := FetchMax
	if fetchmaxString, ok := request["fetchmax"] ; ok {
	    fetchmax, err = strconv.Atoi(fetchmaxString)
	    if err != nil {
	        h.context.Errorf("strconv.Atoi(fetchmaxString=%v) error=%v", fetchmaxString, err)
	        fetchmax = FetchMax
	    }
	}
	
	deadline := time.Duration(Deadline)
	
	var errors []string
	for i := 0; i < fetchmax; i++ {
		t := &urlfetch.Transport{Context:h.context, Deadline:deadline, AllowInvalidServerCertificate:true}
		resp, err := t.RoundTrip(req)
		if err != nil {
			message := err.Error()
			errors = append(errors, message)
			if strings.Contains(message, "FETCH_ERROR") {
				h.context.Errorf("URLFetchServiceError_FETCH_ERROR(type=%T, deadline=%v, url=%v)", err, deadline, url)
				time.Sleep(1*1e9)
				deadline = time.Duration(Deadline*2)
			} else if strings.Contains(message, "DEADLINE_EXCEEDED") {
				h.context.Errorf("URLFetchServiceError_DEADLINE_EXCEEDED(type=%T, deadline=%v, url=%v)", err, deadline, url)
				time.Sleep(1*1e9)
				deadline = time.Duration(Deadline*2)
			} else if strings.Contains(message, "INVALID_URL") {
				h.printNotify(method, url, 501, fmt.Sprintf("Invalid URL: %s", err.Error()))
				return
			} else if strings.Contains(message, "RESPONSE_TOO_LARGE") {
				h.context.Errorf("URLFetchServiceError_RESPONSE_TOO_LARGE(type=%T, deadline=%v, url=%v)", err, deadline, url)
				req.Header.Set("Range", fmt.Sprintf("bytes=0-%d", FetchMaxSize))
				//h.context.Infof("req.Header=%v", req.Header)
				deadline = time.Duration(Deadline*2)
			} else {
				h.context.Errorf("URLFetchServiceError UNKOWN(type=%T, deadline=%v, url=%v, error=%v)", err, deadline, url, err)
				time.Sleep(4*1e9)
			}
			continue
		}

		status := resp.StatusCode
		header := make(map[string]string)
		for k, vv := range resp.Header {
		    key := strings.ToLower(k)
			if key != "set-cookie" {
				header[key] = vv[0]
			} else {
				var cookies []string
				i := -1
				regex, _ := regexp.Compile("^[^ =]+ ")
				for _, sc := range strings.Split(vv[0], ", ") {
					if 0 <= i && regex.MatchString(sc) {
						cookies[i] = fmt.Sprintf("%s, %s", cookies[i], sc)
					} else {
						cookies = append(cookies, sc)
						i++
					}
				}
				header["set-cookie"] = strings.Join(cookies, "\r\nSet-Cookie: ")
			}
		}

		content, err := ioutil.ReadAll(resp.Body)
		if err == urlfetch.ErrTruncatedBody {
			h.context.Criticalf("ioutil.ReadAll(resp.Body) return urlfetch.ErrTruncatedBody")
		}
		if status == 206 {
			header["accept-ranges"] = "bytes"
			header["content-length"] = strconv.Itoa(len(content))
		}
		header["connection"] = "close"

		//h.printNotify(method, url, 502, fmt.Sprintf("status=%d, header=%v, len(content)=%d", status, resp.Header, len(content)))
		h.printResponse(status, header, content)
		return
	}
	h.printNotify(method, url, 502, fmt.Sprintf("Go Server Fetch Failed: %v", errors))
}

func (h Handler) get() {
	h.response.WriteHeader(http.StatusOK)
	h.response.Header().Set("Content-Type", "text/html; charset=utf-8")
	fmt.Fprintf(h.response, `
<html>
<head>
    <link rel="icon" type="image/vnd.microsoft.icon" href="http://www.google.cn/favicon.ico">
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <title>GoAgent GAE/Go %s &#x5DF2;&#x7ECF;&#x5728;&#x5DE5;&#x4F5C;&#x4E86;</title>
</head>
<body>
    <table width="800" border="0" align="center">
        <tr><td align="center"><hr></td></tr>
        <tr><td align="center">
            <b><h1>GoAgent Go Server %s &#x5DF2;&#x7ECF;&#x5728;&#x5DE5;&#x4F5C;&#x4E86;</h1></b>
        </td></tr>
        <tr><td align="center"><hr></td></tr>

        <tr><td align="center">
            GoAgent&#x662F;&#x4E00;&#x4E2A;&#x5F00;&#x6E90;&#x7684;HTTP Proxy&#x8F6F;&#x4EF6;, &#x4F7F;&#x7528;Go/Python&#x7F16;&#x5199;, &#x8FD0;&#x884C;&#x4E8E;Google App Engine&#x5E73;&#x53F0;&#x4E0A;
        </td></tr>
        <tr><td align="center"><hr></td></tr>

        <tr><td align="center">
            &#x66F4;&#x591A;&#x76F8;&#x5173;&#x4ECB;&#x7ECD;, &#x8BF7;&#x53C2;&#x8003;<a href="http://code.google.com/p/goagent/">GoAgent&#x9879;&#x76EE;&#x4E3B;&#x9875;</a>.
        </td></tr>
        <tr><td align="center"><hr></td></tr>

    </table>
</body>
</html>`, Version, Version)
}

func init() {
	http.Handle("/fetch.py", Handler{})
}
