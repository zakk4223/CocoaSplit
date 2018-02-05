//
//  DeckLinkBridge.h
//  CSDeckLinkCapturePlugin
//
//  Created by Zakk on 6/13/15.
//

#ifndef CSDeckLinkCapturePlugin_DeckLinkBridge_h
#define CSDeckLinkCapturePlugin_DeckLinkBridge_h


#include "DeckLinkAPI.h"


@class CSDeckLinkCapture;
@class CSDeckLinkDevice;


class DeckLinkInputHandler :  public IDeckLinkInputCallback
{
private:
    CSDeckLinkDevice*      deckLinkDevice;
    int32_t                         refCount;
public:
    DeckLinkInputHandler(CSDeckLinkDevice* csDevice);
    virtual ~DeckLinkInputHandler();
    
    
    // IDeckLinkDeviceArrivalNotificationCallback interface
    virtual HRESULT     VideoInputFrameArrived(IDeckLinkVideoInputFrame *videoFrame, IDeckLinkAudioInputPacket *audioPacket);
    virtual HRESULT     VideoInputFormatChanged(BMDVideoInputFormatChangedEvents notificationEvents, IDeckLinkDisplayMode *newDisplayMode, BMDDetectedVideoInputFormatFlags detectedSignalFlags);
    
    // IUnknown needs only a dummy implementation
    virtual HRESULT		QueryInterface (REFIID iid, LPVOID *ppv);
    virtual ULONG		AddRef ();
    virtual ULONG		Release ();
};


class DeckLinkDeviceDiscovery :  public IDeckLinkDeviceNotificationCallback
{
private:
    IDeckLinkDiscovery*             deckLinkDiscovery;
    __weak CSDeckLinkCapture*      captureDelegate;
    int32_t                         refCount;
public:
    DeckLinkDeviceDiscovery(CSDeckLinkCapture* uiDelegate);
    virtual ~DeckLinkDeviceDiscovery();
    
    bool                Enable();
    void                Disable();
    
    // IDeckLinkDeviceArrivalNotificationCallback interface
    virtual HRESULT     DeckLinkDeviceArrived (/* in */ IDeckLink* deckLinkDevice);
    virtual HRESULT     DeckLinkDeviceRemoved (/* in */ IDeckLink* deckLinkDevice);
    
    // IUnknown needs only a dummy implementation
    virtual HRESULT		QueryInterface (REFIID iid, LPVOID *ppv);
    virtual ULONG		AddRef ();
    virtual ULONG		Release ();
};


#endif
