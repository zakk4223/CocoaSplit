CocoaSplit


BINARIES HERE: http://krylon.rsdio.com/zakk/cocoasplit/


CocoaSplit uses libavformat and the OSX VideoToolbox hardware h264 encoder to stream to anything libavformat can handle.

Multiple outputs are supported, so you can save to a local file while streaming to something like twitch.tv or own3d.tv

Audio codec is limited to AAC; this is done through AVFoundation's AVCaptureOutput, which means it does not support MP3. Sorry, maybe later.


Video input support:
Webcam (Uses AVFoundation)
Desktop (Uses CGDisplayStream)
32-bit QuickTime Inputs (QTCapture) - Camtwist and various webcam/capture cards should show up here.

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

Supported Platforms

So far only tested on a Retina MacbookPro running Mountain Lion (10.8)

