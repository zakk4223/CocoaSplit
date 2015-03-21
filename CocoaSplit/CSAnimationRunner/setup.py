from distutils.core import setup
import py2app
setup(
      options = {
      "py2app": {
      "includes": "pluginbase",
      },
      },
      
      plugin = ['CSAnimationRunner.py'] 
      )
