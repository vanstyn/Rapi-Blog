#!/usr/bin/env perl
#

use strict;
use warnings;

use RapidApp::Util ':all';

use FindBin;
use lib "$FindBin::Bin/../lib";

use Rapi::Blog;

my $AC = Rapi::Blog->controller('RapidApp::Template')->Access;

my $tpls = &_tpls;
for my $template (keys %$tpls) {
  print "\n  $template :   ";
  $AC->template_exists($template) and print "exists" and next;
  $AC->create_template($template, $tpls->{$template}) and print "created";
}

print "\n\n";

########################################


sub _tpls {{

'site/content/gotalk.md' => q~# gotalk

[Gotalk](https://github.com/rsms/gotalk) exists to make it easy for programs to *talk with one another over the internet*, like a web app coordinating with a web server, or a bunch of programs dividing work amongst eachother.

![A terribly boring amateur comic strip](https://github.com/rsms/gotalk/raw/master/doc/gotalk-comic.png)

Gotalk takes the natural approach of *bidirectional* and *concurrent* communication — any peer have the ability to expose "operations" as well as asking other peers to perform operations. The traditional restrictions of who can request and who can respond usually associated with a client-server model is nowhere to be found in gotalk.

## Gotalk in a nutshell

**Bidirectional** — There's no discrimination on capabilities depending on who connected or who accepted. Both "servers" and "clients" can expose operations as well as send requests to the other side.

**Concurrent** — Requests, results, and notifications all share a single connection without blocking eachother by means of [pipelining](http://en.wikipedia.org/wiki/Protocol_pipelining). There's no serialization on request-result or even for a single large message, as the gotalk protocol is frame-based and multiplexes messages over a single connection. This means you can perform several requests at once without having to think about queueing or blocking.

![Diagram of how Gotalk uses connection pipelining](https://github.com/rsms/gotalk/raw/master/doc/gotalk-pipeline-diagram.png)

**Simple** — Gotalk has a simple and opinionated API with very few components. You expose an operation via "handle" and send requests via "request".

**Debuggable** — The Gotalk protocol's wire format is ASCII-based for easy on-the-wire inspection of data. For example, here's a protocol message representing an operation request: `r0001005hello00000005world`. The Gotalk protocol can thus be operated over any reliable byte transport.

**Practical** — Gotalk includes a JavaScript implementation for Web Sockets alongside the full-featured Go implementation, making it easy to build real-time web applications. The Gotalk source code also includes a number of easily-readable examples.


## By example

There are a few examples in the `examples` directory demonstrating Gotalk. But let's explore a simple program right now — here's a little something written in [Go](http://golang.org/) which demonstrates the use of an operation named "greet":

```go
func server() {
  gotalk.Handle("greet", func(in GreetIn) (GreetOut, error) {
    return GreetOut{"Hello " + in.Name}, nil
  })
  if err := gotalk.Serve("tcp", "localhost:1234"); err != nil {
    log.Fatalln(err)
  }
}

func client() {
  s, err := gotalk.Connect("tcp", "localhost:1234")
  if err != nil {
    log.Fatalln(err)
  }
  greeting := &GreetOut{}
  if err := s.Request("greet", GreetIn{"Rasmus"}, greeting); err != nil {
    log.Fatalln(err)
  }
  log.Printf("greeting: %+v\n", greeting)
  s.Close()
}
```

Let's look at the above example in more detail, broken apart to see what's going on.

We begin by importing the gotalk library together with `log` which we use for printing to the console:

```go
package main
import (
  "log"
  "github.com/rsms/gotalk"
)
```

We define two types: Expected input (request parameters) and output (result) for our "greet" operation:

```go
type GreetIn struct {
  Name string `json:"name"`
}
type GreetOut struct {
  Greeting string `json:"greeting"`
}
```

Registers a process-global request handler for an operation called "greet" accepting parameters of type `GreetIn`, returning results of type `GreetOut`:

```go
func server() {
  gotalk.Handle("greet", func(in GreetIn) (GreetOut, error) {
    return GreetOut{"Hello " + in.Name}, nil
  })
```

Finally at the bottom of our `server` function we call `gotalk.Serve`, which starts a local TCP server on port 1234:

```go
  if err := gotalk.Serve("tcp", "localhost:1234"); err != nil {
    log.Fatalln(err)
  }
}
```

In out `client` function we start by connecting to the server:

```go
func client() {
  s, err := gotalk.Connect("tcp", "localhost:1234")
  if err != nil {
    log.Fatalln(err)
  }
```

Finally we send a request for "greet" and print the result:

```go
  greeting := GreetOut{}
  if err := s.Request("greet", GreetIn{"Rasmus"}, &greeting); err != nil {
    log.Fatalln(err)
  }
  log.Printf("greeting: %+v\n", greeting)

  s.Close()
}
```

Output:

```go
greeting: {Greeting:Hello Rasmus}
```

## Gotalk in the web browser

Gotalk is implemented not only in the full-fledged Go package, but also in a JavaScript library. This allows writing web apps talking Gotalk via Web Sockets possible.

```go
// server.go:
package main
import (
  "net/http"
  "github.com/rsms/gotalk"
)
func main() {
  gotalk.Handle("echo", func(in string) (string, error) {
    return in, nil
  })
  http.Handle("/gotalk/", gotalk.WebSocketHandler())
  http.Handle("/", http.FileServer(http.Dir(".")))
  err := http.ListenAndServe("localhost:1234", nil)
  if err != nil {
    panic(err)
  }
}
```

In our html document, we begin by registering any operations we can handle:

```html
<!-- index.html -->
<body>
<script type="text/javascript" src="/gotalk/gotalk.js"></script>
<script>
gotalk.handle('greet', function (params, result) {
  result({ greeting: 'Hello ' + params.name });
});
</script>
```

Notice how we load a JavaScript from "/gotalk/gotalk.js" — a gotalk web socket server embeds a matching web browser JS library which it returns from `{path where gotalk web socket is mounted}/gotalk.js`. It uses Etag cache validation, so you shouldn't need to think about "cache busting" the URL.

We can't "listen & accept" connections in a web browser, but we can "connect" so we do just that:

```html
<!-- index.html -->
<body>
<script type="text/javascript" src="/gotalk/gotalk.js"></script>
<script>
gotalk.handle('greet', function (params, result) {
  result({ greeting: 'Hello ' + params.name });
});

var s = gotalk.connection().on('open', function () {
  // do something useful
}).on('close', function (err) {
  if (err.isGotalkProtocolError) return console.error(err);
});
</script>
```

This is enough for enabling the *server* to do things in the *browser* ...

But you probably want to have the *browser* send requests to the *server*, so let's send a "echo" request just as our connection opens:

```js
var s = gotalk.connection().on('open', function () {
  s.request("echo", "Hello world", function (err, result) {
    if (err) return console.error('echo failed:', err);
    console.log('echo result:', result);
  });
});
```

We could rewrite our code like this to allow some UI component to send a request:

```js
var s = gotalk.connection();

button.addEventListener('click', function () {
  s.request("echo", "Hello world", function (err, result) {
    if (err) return console.error('echo failed:', err);
    console.log('echo result:', result);
  });
});
```

The request will fail with an error "socket is closed" if the user clicks our button while the connection isn't open.

There are two ways to open a connection on a socket: `Sock.prototype.open` which simply opens a connection, and `Sock.prototype.openKeepAlive` which keeps the connection open, reconnecting as needed with exponential back-off and internet reachability knowledge. `gotalk.connection()` is a short-hand for creating a new Sock with `gotalk.defaultHandlers` and then calling `openKeepAlive` on it.


## Protocol and wire format

The wire format is designed to be human-readable and flexible; it's byte-based and can be efficiently implemented in a number of environments ranging from HTTP and WebSocket in a web browser to raw TCP in Go or C. The protocol provides only a small set of operations on which more elaborate operations can be modeled by the user.

> This document describes protocol version 1

Here's a complete description of the protocol:

    conversation    = ProtocolVersion Message*
    message         = SingleRequest | StreamRequest
                    | SingleResult | StreamResult
                    | ErrorResult | RetryResult
                    | Notification | ProtocolError

    ProtocolVersion = <hexdigit> <hexdigit>

    SingleRequest   = "r" requestID operation payload
    StreamRequest   = "s" requestID operation payload StreamReqPart*
    StreamReqPart   = "p" requestID payload
    SingleResult    = "R" requestID payload
    StreamResult    = "S" requestID payload StreamResult*
    ErrorResult     = "E" requestID payload
    RetryResult     = "e" requestID wait payload
    Notification    = "n" name payload
    Heartbeat       = "h" load time
    ProtocolError   = "f" code

    requestID       = <byte> <byte> <byte> <byte>

    operation       = text3
    name            = text3
    wait            = hexUInt8
    code            = hexUInt8
    time            = hexUInt8
    load            = hexUInt4

    text3           = text3Size text3Value
    text3Size       = hexUInt3
    text3Value      = <<byte>{text3Size} as utf8 text>

    payload         = payloadSize payloadData
    payloadSize     = hexUInt8
    payloadData     = <byte>{payloadSize}

    hexUInt3        = <hexdigit> <hexdigit> <hexdigit>
    hexUInt4        = <hexdigit> <hexdigit> <hexdigit> <hexdigit>
    hexUInt8        = <hexdigit> <hexdigit> <hexdigit> <hexdigit>
                      <hexdigit> <hexdigit> <hexdigit> <hexdigit>


### Handshake

A conversation begins with the protocol version:

```lua
01  -- ProtocolVersion 1
```

If the version of the protocol spoken by the other end is not supported by the reader, a ProtocolError message is sent with code 1 and the connection is terminated. Otherwise, any messages are read and/or written.


### Single-payload requests and results

This is a "single-payload" request ...

```py
+------------------ SingleRequest
|   +---------------- requestID   "0001"
|   |      +--------- operation   "echo" (text3Size 4, text3Value "echo")
|   |      |       +- payloadSize 25
|   |      |       |
r0001004echo00000019{"message":"Hello World"}
```

... and a corresponding "single-payload" result:

```py
+------------------ SingleResult
|   +---------------- requestID   "0001"
|   |       +-------- payloadSize 25
|   |       |
R000100000019{"message":"Hello World"}
```

Each request is identified by exactly three bytes—the `requestID`—which is requestor-specific and has no purpose beyond identity, meaning the value is never interpreted. 4 bytes can express 4 294 967 296 different values, meaning we can send up to 4 294 967 295 requests while another request is still being served. Should be enough.

These "single" requests & results are the most common protocol messages, and as their names indicates, their payloads follow immediately after the header. For large payloads this can become an issue when dealing with many concurrent requests over a single connection, for which there's a more complicated "streaming" request & result type which we will explore later on.


### Faults

There are two types of replies indicating a fault: `ErrorResult` for requestor faults and `RetryResult` for responder faults.

If a request is faulty, like missing some required input data or sent over an unauthorized connection, an "error" is send as the reply instead of a regular result:

```py
+------------------ ErrorResult
|   +---------------- requestID   "0001"
|   |       +-------- payloadSize 38
|   |       |
E000100000026{"error":"Unknown operation \"echo\""}
```

A request that produces an error should not be retried as-is, similar to the 400-class of errors of the HTTP protocol.

In the scenario a fault occurs on the responder side, like suffering a temporary internal error or is unable to complete the request because of resource starvation, a RetryResult is sent as the reply to a request:

```py
+-------------------- RetryResult
|   +------------------ requestID   "0001"
|   |       +---------- wait        0
|   |       |       +-- payloadSize 20
|   |       |       |
e00010000000000000014"service restarting"
```

In this case — where `wait` is zero — the requestor is free to retry the request at its convenience.

However in some scenarios the responder might require the requestor to wait for some time before retrying the request, in which case the `wait` property has a non-zero value:

```py
+-------------------- RetryResult
|   +------------------ requestID   "0001"
|   |       +---------- wait        5000 ms
|   |       |       +-- payloadSize 20
|   |       |       |
e00010000138800000014"request rate limit"
```

In this case the requestor must not retry the request until at least 5000 milliseconds has passed.

If the protocol communication itself experiences issues—e.g. an illegal message is received—a ProtocolError is written and the connection is closed.

**ProtocolError codes:**

|  Code | Meaning              | Comments
| ----: | -------------------- | -----------------------------------------------------------------
|     0 | Abnormal             | Closed because of an abnormal condition (e.g. server fault, etc)
|     1 | Unsupported protocol | The other side does not support the callers protocol
|     2 | Invalid message      | An invalid message was transmitted
|     3 | Timeout              | The other side closed the connection because communicating took too long

Example of a peer which does not support the version of the protocol spoken by the sender:

```py
+-------- ProtocolError
|       +-- code 1
|       |
f00000001
```

### Streaming requests and results

For more complicated scenarios there are "streaming-payload" requests and results at our disposal. This allows transmitting of large amounts of data without the need for large buffers. For example this could be used to forward audio data to audio playback hardware, or to transmit a large file off of slow media like a tape drive or hard-disk drive.

Because transmitting a streaming request or result does not occupy "the line" (single-payloads are transmitted serially), they can also be useful when there are many concurrent requests happening over a single connection.

Here's an example of a "streaming-payload" request ...

```py
+------------------ StreamRequest
|   +---------------- requestID   "0001"
|   |      +--------- operation   "echo" (text3Size 4, text3Value "echo")
|   |      |       +- payloadSize 11
|   |      |       |
s0001004echo0000000b{"message":

+------------------ streamReqPart
|   +---------------- requestID   "0001"
|   |       +-------- payloadSize 14
|   |       |
p00010000000e"Hello World"}

+------------------ streamReqPart
|   +---------------- requestID   "0001"
|   |       +-------- payloadSize 0 (end of stream)
|   |       |
p000100000000
```

... followed by a "streaming-payload" result:

```py
+------------------ StreamResult (1st part)
|   +---------------- requestID   "0001"
|   |       +-------- payloadSize 11
|   |       |
S00010000000b{"message":

+------------------ StreamResult (2nd part)
|   +---------------- requestID   "0001"
|   |       +-------- payloadSize 14
|   |       |
S00010000000e"Hello World"}

+------------------ StreamResult
|   +---------------- requestID   "0001"
|   |       +-------- payloadSize 0 (end of stream)
|   |       |
S000100000000
```

Streaming requests occupy resources on the responder's side for the duration of the "stream session". Therefore handling of streaming requests should be limited and "RetryResult" used to throttle requests:

```py
+-------------------- RetryResult
|   +------------------ requestID   "0001"
|   |       +---------- wait        5000 ms
|   |       |       +-- payloadSize 19
|   |       |       |
e00010000138800000013"stream rate limit"
```

This means that the requestor must not send any new requests until `wait` time has passed.


### Notifications

When there's no expectation on a response, Gotalk provides a "notification" message type:

```py
+---------------------- Notification
|              +--------- name        "chat message" (text3Size 12, text3Value "chat message")
|              |       +- payloadSize 46
|              |       |
n00cchat message0000002e{"message":"Hi","from":"nthn","room":"gonuts"}
```

Notifications are never replied to nor can they cause "error" results. Applications needing acknowledgement of notification delivery might consider using a request instead.


### Heartbeats

Because most responders will limit the time it waits for reads, a heartbeat message is send at a certain interval. When a heartbeat is sent is up to the implementation.

A heartbeat contains the sender's local time in the form of an unsigned 32-bit UNIX timestamp. This is enought to cover usage until 2106. I really hope gotalk is nowhere to be found in 2106.

It also contains an optional "load" value, indicating how pressured, or under what load, the sender is. 0 means "idle" and 65535 (0xffff) means "omg I think I'm dying." This can be used to distribute work to less loaded responders in a load-balancing setup.

```py
+------------------ Heartbeat
|   +--------- load 2
|   |       +- time 2015-02-08 22:09:30 UTC
|   |       |
h000254d7de9a
```


### Notes

Requests and results does not need to match on the "single" vs "streaming" detail — it's perfectly fine to send a streaming request and read a single response, or send a single response just to receive a streaming result. *The payload type is orthogonal to the message type*, with the exception of an error response which is always a "single-payload" message, carrying any information about the error in its payload. Note however that the current version of the Go package does not provide a high-level API for mixed-kind request-response handling.

For transports which might need "heartbeats" to stay alive, like some raw TCP connections over the internet, the suggested way to implement this is by notifications, e.g. send a "heartbeat" notification at a ceretain interval while no requests are being sent. The Gotalk protocol does not include a "heartbeat" feature because of this reason, as well as the fact that some transports (like web socket) already provide "heartbeat" features.



## Other implementations

- <https://github.com/gtaylor/python-gotalk>


## MIT license

Copyright (c) 2015 Rasmus Andersson <http://rsms.me/>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

~,



'site/content/marked.md' => q~# marked

> A full-featured markdown parser and compiler, written in JavaScript. Built
> for speed.

[![NPM version](https://badge.fury.io/js/marked.png)][badge]

## Install

``` bash
npm install marked --save
```

## Usage

Minimal usage:

```js
var marked = require('marked');
console.log(marked('I am using __markdown__.'));
// Outputs: <p>I am using <strong>markdown</strong>.</p>
```

Example setting options with default values:

```js
var marked = require('marked');
marked.setOptions({
  renderer: new marked.Renderer(),
  gfm: true,
  tables: true,
  breaks: false,
  pedantic: false,
  sanitize: false,
  smartLists: true,
  smartypants: false
});

console.log(marked('I am using __markdown__.'));
```

### Browser

```html
<!doctype html>
<html>
<head>
  <meta charset="utf-8"/>
  <title>Marked in the browser</title>
  <script src="lib/marked.js"></script>
</head>
<body>
  <div id="content"></div>
  <script>
    document.getElementById('content').innerHTML =
      marked('# Marked in browser\n\nRendered by **marked**.');
  </script>
</body>
</html>
```

## marked(markdownString [,options] [,callback])

### markdownString

Type: `string`

String of markdown source to be compiled.

### options

Type: `object`

Hash of options. Can also be set using the `marked.setOptions` method as seen
above.

### callback

Type: `function`

Function called when the `markdownString` has been fully parsed when using
async highlighting. If the `options` argument is omitted, this can be used as
the second argument.

## Options

### highlight

Type: `function`

A function to highlight code blocks. The first example below uses async highlighting with
[node-pygmentize-bundled][pygmentize], and the second is a synchronous example using
[highlight.js][highlight]:

```js
var marked = require('marked');

var markdownString = '```js\n console.log("hello"); \n```';

// Async highlighting with pygmentize-bundled
marked.setOptions({
  highlight: function (code, lang, callback) {
    require('pygmentize-bundled')({ lang: lang, format: 'html' }, code, function (err, result) {
      callback(err, result.toString());
    });
  }
});

// Using async version of marked
marked(markdownString, function (err, content) {
  if (err) throw err;
  console.log(content);
});

// Synchronous highlighting with highlight.js
marked.setOptions({
  highlight: function (code) {
    return require('highlight.js').highlightAuto(code).value;
  }
});

console.log(marked(markdownString));
```

#### highlight arguments

`code`

Type: `string`

The section of code to pass to the highlighter.

`lang`

Type: `string`

The programming language specified in the code block.

`callback`

Type: `function`

The callback function to call when using an async highlighter.

### renderer

Type: `object`
Default: `new Renderer()`

An object containing functions to render tokens to HTML.

#### Overriding renderer methods

The renderer option allows you to render tokens in a custom manner. Here is an
example of overriding the default heading token rendering by adding an embedded anchor tag like on GitHub:

```javascript
var marked = require('marked');
var renderer = new marked.Renderer();

renderer.heading = function (text, level) {
  var escapedText = text.toLowerCase().replace(/[^\w]+/g, '-');

  return '<h' + level + '><a name="' +
                escapedText +
                 '" class="anchor" href="#' +
                 escapedText +
                 '"><span class="header-link"></span></a>' +
                  text + '</h' + level + '>';
},

console.log(marked('# heading+', { renderer: renderer }));
```
This code will output the following HTML:
```html
<h1>
  <a name="heading-" class="anchor" href="#heading-">
    <span class="header-link"></span>
  </a>
  heading+
</h1>
```

#### Block level renderer methods

- code(*string* code, *string* language)
- blockquote(*string* quote)
- html(*string* html)
- heading(*string* text, *number*  level)
- hr()
- list(*string* body, *boolean* ordered)
- listitem(*string*  text)
- paragraph(*string* text)
- table(*string* header, *string* body)
- tablerow(*string* content)
- tablecell(*string* content, *object* flags)

`flags` has the following properties:

```js
{
    header: true || false,
    align: 'center' || 'left' || 'right'
}
```

#### Inline level renderer methods

- strong(*string* text)
- em(*string* text)
- codespan(*string* code)
- br()
- del(*string* text)
- link(*string* href, *string* title, *string* text)
- image(*string* href, *string* title, *string* text)

### gfm

Type: `boolean`
Default: `true`

Enable [GitHub flavored markdown][gfm].

### tables

Type: `boolean`
Default: `true`

Enable GFM [tables][tables].
This option requires the `gfm` option to be true.

### breaks

Type: `boolean`
Default: `false`

Enable GFM [line breaks][breaks].
This option requires the `gfm` option to be true.

### pedantic

Type: `boolean`
Default: `false`

Conform to obscure parts of `markdown.pl` as much as possible. Don't fix any of
the original markdown bugs or poor behavior.

### sanitize

Type: `boolean`
Default: `false`

Sanitize the output. Ignore any HTML that has been input.

### smartLists

Type: `boolean`
Default: `true`

Use smarter list behavior than the original markdown. May eventually be
default with the old behavior moved into `pedantic`.

### smartypants

Type: `boolean`
Default: `false`

Use "smart" typograhic punctuation for things like quotes and dashes.

## Access to lexer and parser

You also have direct access to the lexer and parser if you so desire.

``` js
var tokens = marked.lexer(text, options);
console.log(marked.parser(tokens));
```

``` js
var lexer = new marked.Lexer(options);
var tokens = lexer.lex(text);
console.log(tokens);
console.log(lexer.rules);
```

## CLI

``` bash
$ marked -o hello.html
hello world
^D
$ cat hello.html
<p>hello world</p>
```

## Philosophy behind marked

The point of marked was to create a markdown compiler where it was possible to
frequently parse huge chunks of markdown without having to worry about
caching the compiled output somehow...or blocking for an unnecesarily long time.

marked is very concise and still implements all markdown features. It is also
now fully compatible with the client-side.

marked more or less passes the official markdown test suite in its
entirety. This is important because a surprising number of markdown compilers
cannot pass more than a few tests. It was very difficult to get marked as
compliant as it is. It could have cut corners in several areas for the sake
of performance, but did not in order to be exactly what you expect in terms
of a markdown rendering. In fact, this is why marked could be considered at a
disadvantage in the benchmarks above.

Along with implementing every markdown feature, marked also implements [GFM
features][gfmf].

## Benchmarks

node v0.8.x

``` bash
$ node test --bench
marked completed in 3411ms.
marked (gfm) completed in 3727ms.
marked (pedantic) completed in 3201ms.
robotskirt completed in 808ms.
showdown (reuse converter) completed in 11954ms.
showdown (new converter) completed in 17774ms.
markdown-js completed in 17191ms.
```

__Marked is now faster than Discount, which is written in C.__

For those feeling skeptical: These benchmarks run the entire markdown test suite 1000 times. The test suite tests every feature. It doesn't cater to specific aspects.

### Pro level

You also have direct access to the lexer and parser if you so desire.

``` js
var tokens = marked.lexer(text, options);
console.log(marked.parser(tokens));
```

``` js
var lexer = new marked.Lexer(options);
var tokens = lexer.lex(text);
console.log(tokens);
console.log(lexer.rules);
```

``` bash
$ node
> require('marked').lexer('> i am using marked.')
[ { type: 'blockquote_start' },
  { type: 'paragraph',
    text: 'i am using marked.' },
  { type: 'blockquote_end' },
  links: {} ]
```

## Running Tests & Contributing

If you want to submit a pull request, make sure your changes pass the test
suite. If you're adding a new feature, be sure to add your own test.

The marked test suite is set up slightly strangely: `test/new` is for all tests
that are not part of the original markdown.pl test suite (this is where your
test should go if you make one). `test/original` is only for the original
markdown.pl tests. `test/tests` houses both types of tests after they have been
combined and moved/generated by running `node test --fix` or `marked --test
--fix`.

In other words, if you have a test to add, add it to `test/new/` and then
regenerate the tests with `node test --fix`. Commit the result. If your test
uses a certain feature, for example, maybe it assumes GFM is *not* enabled, you
can add `.nogfm` to the filename. So, `my-test.text` becomes
`my-test.nogfm.text`. You can do this with any marked option. Say you want
line breaks and smartypants enabled, your filename should be:
`my-test.breaks.smartypants.text`.

To run the tests:

``` bash
cd marked/
node test
```

### Contribution and License Agreement

If you contribute code to this project, you are implicitly allowing your code
to be distributed under the MIT license. You are also implicitly verifying that
all code is your original work. `</legalese>`

## License

Copyright (c) 2011-2014, Christopher Jeffrey. (MIT License)

See LICENSE for more info.

[gfm]: https://help.github.com/articles/github-flavored-markdown
[gfmf]: http://github.github.com/github-flavored-markdown/
[pygmentize]: https://github.com/rvagg/node-pygmentize-bundled
[highlight]: https://github.com/isagalaev/highlight.js
[badge]: http://badge.fury.io/js/marked
[tables]: https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet#wiki-tables
[breaks]: https://help.github.com/articles/github-flavored-markdown#newlines



~



}}