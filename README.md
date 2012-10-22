CocoaSplit


CocoaSplit uses libavformat and the OSX VideoToolbox hardware h264 encoder to stream to anything libavformat can handle.

Multiple outputs are supported, so you can save to a local file while streaming to something like twitch.tv or own3d.tv

Audio codec is limited to AAC; this is done through AVFoundation's AVCaptureOutput, which means it does not support MP3. Sorry, maybe later.


Video input support:
Webcam (Uses AVFoundation)
Desktop (Uses CGDisplayStream)

Audio input support:
AVFoundation audio (things like SoundFlower or Jack should work fine)

How to use

Setup your video and audio inputs. 

Video: The resolution is the final output resolution; inputs are scaled to this resolution. No cropping is done.
Output: Choose between local file or RTMP stream and click 'Add'. Remove entries by selecting them and clicking 'Remove'.

Click 'Stream!'

Click Stop when you are done.


All settings are saved.


TODO
Some sort of status output while streaming is active.
Use twitch and own3d API to get user's streamkey.
Syphon input.
Allow the option of using libavcodec's x264 encoder for those that don't have a hardware encoder.

What about CamTwist?
Unfortunately CamTwist is 32bit only and CocoaSplit is 64bit. On top of that, CamTwist only shows up at a QTCaptureDevice and not an AVFoundation Device.
My experiments with a 32bit version of CocoaSplit that uses QTCapture ended with what I consider excessive CPU usage. So there is unlikely to be native CamTwist support. The upcoming Syphon support should allow getting frames out of CamTwist, it'll just be a bit more complicated than normal.


Supported Platforms

So far only tested on a Retina MacbookPro running Mountain Lion (10.8)

