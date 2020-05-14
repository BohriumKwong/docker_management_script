from flask import (Flask,
                   request,
                   abort,
                   )
import os
import json
from functools import wraps
import subprocess
import time


# Flask app
app = Flask(
    __name__,
    static_folder='static', static_url_path='',
    instance_relative_config=True
)



def exception_to_json(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        try:
            result = func(*args, **kwargs)
            return result
        except (BadRequest,
                KeyError,
                ValueError,
                ) as e:
            result = {'error': {'code': 400,
                                'message': str(e)}}
        except PermissionDenied as e:
            result = {'error': {'code': 403,
                                'message': ', '.join(e.args)}}
        except (NotImplementedError, RuntimeError, AttributeError) as e:
            result = {'error': {'code': 500,
                                'message': ', '.join(e.args)}}
        return json.dumps(result)
    return wrapper


class PermissionDenied(Exception):
    pass


class BadRequest(Exception):
    pass


HTML_INDEX = '''<html><head>
    <script type="text/javascript">
        var w = window,
        d = document,
        e = d.documentElement,
        g = d.getElementsByTagName('body')[0],
        x = w.innerWidth || e.clientWidth || g.clientWidth,
        y = w.innerHeight|| e.clientHeight|| g.clientHeight;
        var url = "redirect?width=" + x + "&height=" + (parseInt(y));
        window.location.href = url;
    </script>
    <title>Page Redirection</title>
</head><body></body></html>'''


HTML_REDIRECT = '''<html><head>
    <script type="text/javascript">
        var port = window.location.port;
        if (!port)
            port = window.location.protocol[4] == 's' ? 443 : 80;
        window.location.href = "vnc.html?autoconnect=1";
    </script>
    <title>Page Redirection</title>
</head><body></body></html>'''


@app.route('/autoresize')
def index():
    return HTML_INDEX


@app.route('/redirect')
def redirectme():

    env = {'width': 1280, 'height': 720}
    if 'width' in request.args:
        env['width'] = request.args['width']
    if 'height' in request.args:
        env['height'] = request.args['height']

    cmd = 'echo {}x{}x24 > /root/.RESOLUTION'.format(env['width'], env['height'])
    subprocess.check_call(cmd, shell=True)
    # supervisorctrl reload
    subprocess.check_call('killall -9 Xvfb', shell=True)
    
    return HTML_REDIRECT


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=10101)
