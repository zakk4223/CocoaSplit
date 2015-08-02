def _reset_sys_path():
    # Clear generic sys.path[0]
    import sys, os
    resources = os.environ['RESOURCEPATH']
    while sys.path[0] == resources:
        del sys.path[0]
_reset_sys_path()


def _update_path():
    import os, sys
    resources = os.environ['RESOURCEPATH']
    sys.path.append(os.path.join(
        resources, 'lib', 'python%d.%d'%(sys.version_info[:2]), 'lib-dynload'))
    sys.path.append(os.path.join(
        resources, 'lib', 'python%d.%d'%(sys.version_info[:2])))

_update_path()


def _site_packages():
    import site, sys, os
    paths = []
    prefixes = [sys.prefix]
    if sys.exec_prefix != sys.prefix:
        prefixes.append(sys.exec_prefix)
    for prefix in prefixes:
        paths.append(os.path.join(prefix, 'lib', 'python' + sys.version[:3],
            'site-packages'))
    if os.path.join('.framework', '') in os.path.join(sys.prefix, ''):
        home = os.environ.get('HOME')
        if home:
            paths.append(os.path.join(home, 'Library', 'Python',
                sys.version[:3], 'site-packages'))

    # Work around for a misfeature in setuptools: easy_install.pth places
    # site-packages way to early on sys.path and that breaks py2app bundles.
    # NOTE: this is hacks into an undocumented feature of setuptools and
    # might stop to work without warning.
    sys.__egginsert = len(sys.path)

    for path in paths:
        site.addsitedir(path)
_site_packages()


""" Add Apple's additional packages to sys.path """
def add_system_python_extras():
    import site, sys

    ver = '%s.%s'%(sys.version_info[:2])

    site.addsitedir('/System/Library/Frameworks/Python.framework/Versions/%s/Extras/lib/python'%(ver,))

add_system_python_extras()


def _setup_ctypes():
    from ctypes.macholib import dyld
    import os
    frameworks = os.path.join(os.environ['RESOURCEPATH'], '..', 'Frameworks')
    dyld.DEFAULT_FRAMEWORK_FALLBACK.insert(0, frameworks)
    dyld.DEFAULT_LIBRARY_FALLBACK.insert(0, frameworks)

_setup_ctypes()


def _path_inject(paths):
    import sys
    sys.path[:0] = paths


_path_inject(['/Users/zakk/proj/CocoaSplit/CapturePlugins/CSShapeCapturePlugin/CSShapeCapturePlugin/CSShapePathPlugin'])


import re, sys
cookie_re = re.compile(b"coding[:=]\s*([-\w.]+)")
if sys.version_info[0] == 2:
    default_encoding = 'ascii'
else:
    default_encoding = 'utf-8'

def guess_encoding(fp):
    for i in range(2):
        ln = fp.readline()

        m = cookie_re.search(ln)
        if m is not None:
            return m.group(1).decode('ascii')

    return default_encoding

def _run():
    global __file__
    import os, site
    sys.frozen = 'macosx_plugin'
    base = os.environ['RESOURCEPATH']

    if 'ARGVZERO' in os.environ:
        argv0 = os.path.basename(os.environ['ARGVZERO'])
    else:
        argv0 = None
    script = SCRIPT_MAP.get(argv0, DEFAULT_SCRIPT)

    sys.argv[0] = __file__ = path = os.path.join(base, script)
    if sys.version_info[0] == 2:
        with open(path, 'rU') as fp:
            source = fp.read() + "\n"
    else:
        with open(path, 'rb') as fp:
            encoding = guess_encoding(fp)

        with open(path, 'r', encoding=encoding) as fp:
            source = fp.read() + '\n'

    exec(compile(source, script, 'exec'), globals(), globals())


DEFAULT_SCRIPT='/Users/zakk/proj/CocoaSplit/CapturePlugins/CSShapeCapturePlugin/CSShapeCapturePlugin/CSShapePathPlugin/CSShapePathLoader.py'
SCRIPT_MAP={}
try:
    _run()
except KeyboardInterrupt:
    pass
