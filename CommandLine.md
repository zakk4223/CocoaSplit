CocoaSplit Command line


Use Contents/MacOS/CocoaSplitCmd

The default is to load the saved settings from the GUI app and then immediately start streaming. This behavior is controllable via a command line switch.


Command line client specific switches:

-dumpInfo YES : (The YES is required) Emit a JSON dump of audio sources, x264 profiles, tunes presets, and profile names for Apple VTCompression. The utility exits after printing this info.

-loadSettings NO : Do not load saved settings from the GUI application. The default is to load settings


Command line switches and what they correspond to in the GUI.

-captureWidth <integer> 
  Output Width

-captureHeight <integer> 
  Output Height

-captureVideoAverageBitrate <integer>
  AppleVTCompressor - Avg Bitrate
  x264 - VBV Maxrate

-captureVideoMaxBitrate <integer>
  AppleVTCompressor - Max Bitrate
  x264 - VBV Buffer

-captureVideoMaxKeyframeInterval <integer>
  AppleVTCompressor - Keyframe
  x264 - Keyframe

-audioBitrate <integer>
  Audio - Bitrate

-audioSamplerate <integer>
  Audio - Sample Rate


-x264tune <string>
  x264 - Tune
  Valid values are given in dumpInfo output

-x264preset <string>
  x264 - Preset
  Valid values are given in dumpInfo output

-x264profile <string>
  AppleVTCompressor - Profile
  x264 - Profile
  Valid values are given in dumpInfo output. 

-x264crf <integer>
  x264 - CRF

-selectedVideoType <string>
  Video - Type. Valid types are Syphon, AVFoundation, QTCapture, Desktop

-selectedCompressorType <string>
  Video - Compress. Valid values are x264, AppleVTCompressor

-videoCaptureID <string>
  Video - Source. Unique ID of the video source. Varies based on selectedVideoType. Currently no way to get these without figuring them out yourself. Sorry. 

-audioCaptureID <string>
  Audio - Source. Valid values are given in dumpInfo. Use the uniqueID property

-captureFPS <float>
  Video - FPS. 

-outputDestinations <see below>
  Array of stream destinations/outputs. Handles just about anything ffmpeg will for an output. All outputs are considered 'active'. Since this is an array the output is a bit peculiar. 

  <array><string>/tmp/blah.mp4</string><string>rtmp://somehost/streamkeyblahblah</string></array>


Example command line use, with syphon input for video and microphone input for audio. Using x264, outputting to /tmp/blah.mp4

./CocoaSplitCmd -loadSettings NO -captureWidth 1280 -captureHeight 720 -captureVideoAverageBitrate 3000 -captureVideoMaxBitrate 6000 -captureVideoMaxKeyframeInterval 200 -audioBitrate 128 -x264preset veryfast -x264crf 22 -selectedCompressorType x264 -videoCaptureID "info.v002.Syphon.F0B6D834-9BB5-44A5-B177-AE0E8DA2D8E7" -selectedVideoType Syphon -audioCaptureID "AppleHDAEngineInput:1B,0,1,0:1" -captureFPS 60 -outputDestinations "<array><string>/tmp/blah.mp4</string></array>" -audioSamplerate 44100



TODO:

Errors should emit something on stderr and exit the utility with a non-zero exit code. Right now they pop up error modal dialogs. Sorry.

Put valid video input types in dumpInfo
Enumerate all valid video inputs (per type) in dumpInfo?

Output periodic status to stdout for each output. Basically the same stuff that's in the status panel of the UI.

BUGS:
If you control-c the app it is an immediately non-graceful exit. If any of the output formats require trailers in their files it will leave a corrupt/unuseable file. Most notably this means it will break MP4 or MOV output. FLV is ok, though.


