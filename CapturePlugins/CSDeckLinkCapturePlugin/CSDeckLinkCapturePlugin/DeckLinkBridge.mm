//
//  DeckLinkBridge.m
//  CSDeckLinkCapturePlugin
//
//  Created by Zakk on 6/13/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DeckLinkBridge.h"
#import "CSAbstractCaptureDevice.h"
#include "CSDeckLinkCapture.h"
#include "CSDeckLinkDevice.h"
#include "CSDeckLinkWrapper.h"



DeckLinkInputHandler::DeckLinkInputHandler(CSDeckLinkDevice* delegate)
: deckLinkDevice(delegate),refCount(1)
{
    
}


DeckLinkInputHandler::~DeckLinkInputHandler()
{
}


HRESULT     DeckLinkInputHandler::VideoInputFrameArrived(IDeckLinkVideoInputFrame *videoFrame, IDeckLinkAudioInputPacket *audioPacket)
{
    
    if (deckLinkDevice)
    {
        [deckLinkDevice frameArrived:videoFrame];
    }
    return S_OK;
}

HRESULT     DeckLinkInputHandler::VideoInputFormatChanged(BMDVideoInputFormatChangedEvents notificationEvents, IDeckLinkDisplayMode *newDisplayMode, BMDDetectedVideoInputFormatFlags detectedSignalFlags)
{
    
    
    if (deckLinkDevice)
    {
        [deckLinkDevice detectedDisplayChange:newDisplayMode withFlags:detectedSignalFlags];
    }
    return S_OK;
}


HRESULT         DeckLinkInputHandler::QueryInterface (REFIID iid, LPVOID *ppv)
{
    CFUUIDBytes		iunknown;
    HRESULT			result = E_NOINTERFACE;
    
    // Initialise the return result
    *ppv = NULL;
    
    // Obtain the IUnknown interface and compare it the provided REFIID
    iunknown = CFUUIDGetUUIDBytes(IUnknownUUID);
    if (memcmp(&iid, &iunknown, sizeof(REFIID)) == 0)
    {
        *ppv = this;
        AddRef();
        result = S_OK;
    }
    else if (memcmp(&iid, &IID_IDeckLinkDeviceNotificationCallback, sizeof(REFIID)) == 0)
    {
        *ppv = (IDeckLinkDeviceNotificationCallback*)this;
        AddRef();
        result = S_OK;
    }
    
    return result;
}

ULONG           DeckLinkInputHandler::AddRef (void)
{
    return OSAtomicIncrement32(&refCount);
}

ULONG           DeckLinkInputHandler::Release (void)
{
    int32_t		newRefValue;
    
    newRefValue = OSAtomicDecrement32(&refCount);
    if (newRefValue == 0)
    {
        delete this;
        return 0;
    }
    
    return newRefValue;
}

/* Thanks blackmagic! ripped directly from your example code! */


DeckLinkDeviceDiscovery::DeckLinkDeviceDiscovery(CSDeckLinkCapture* delegate)
: captureDelegate(delegate), deckLinkDiscovery(NULL), refCount(1)
{
    deckLinkDiscovery = CreateDeckLinkDiscoveryInstance();
}


DeckLinkDeviceDiscovery::~DeckLinkDeviceDiscovery()
{
    if (deckLinkDiscovery != NULL)
    {
        // Uninstall device arrival notifications and release discovery object
        deckLinkDiscovery->UninstallDeviceNotifications();
        deckLinkDiscovery->Release();
        deckLinkDiscovery = NULL;
    }
}

bool        DeckLinkDeviceDiscovery::Enable()
{
    HRESULT     result = E_FAIL;
    
    // Install device arrival notifications
    if (deckLinkDiscovery != NULL)
        result = deckLinkDiscovery->InstallDeviceNotifications(this);
    
    return result == S_OK;
}

void        DeckLinkDeviceDiscovery::Disable()
{
    // Uninstall device arrival notifications
    if (deckLinkDiscovery != NULL)
        deckLinkDiscovery->UninstallDeviceNotifications();
}

HRESULT     DeckLinkDeviceDiscovery::DeckLinkDeviceArrived (/* in */ IDeckLink* deckLink)
{
    
    HRESULT result;
    IDeckLinkAttributes *deckLinkAttributes = NULL;
    
    // Update UI (add new device to menu) from main thread
    // AddRef the IDeckLink instance before handing it off to the main thread
    result = deckLink->QueryInterface(IID_IDeckLinkAttributes, (void **)&deckLinkAttributes);
    
    if (result != S_OK)
    {
        return S_OK;
    }
    
    
    CSDeckLinkWrapper *wrapper = [[CSDeckLinkWrapper alloc] initWithDeckLink:deckLink];
    
    
    CFStringRef displayName;
    int64_t topID;
    deckLink->GetDisplayName(&displayName);
    deckLinkAttributes->GetInt(BMDDeckLinkPersistentID, &topID);
    
    NSString *uuid = [NSString stringWithFormat:@"%lld", topID];
    
    CSAbstractCaptureDevice *newDev = [[CSAbstractCaptureDevice alloc] initWithName:(__bridge NSString *)displayName device:wrapper uniqueID:uuid];
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [captureDelegate addDevice:newDev];
    });
    
    return S_OK;
}

HRESULT     DeckLinkDeviceDiscovery::DeckLinkDeviceRemoved (/* in */ IDeckLink* deckLink)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [captureDelegate removeDevice:deckLink];
    });
    return S_OK;
}

HRESULT         DeckLinkDeviceDiscovery::QueryInterface (REFIID iid, LPVOID *ppv)
{
    CFUUIDBytes		iunknown;
    HRESULT			result = E_NOINTERFACE;
    
    // Initialise the return result
    *ppv = NULL;
    
    // Obtain the IUnknown interface and compare it the provided REFIID
    iunknown = CFUUIDGetUUIDBytes(IUnknownUUID);
    if (memcmp(&iid, &iunknown, sizeof(REFIID)) == 0)
    {
        *ppv = this;
        AddRef();
        result = S_OK;
    }
    else if (memcmp(&iid, &IID_IDeckLinkDeviceNotificationCallback, sizeof(REFIID)) == 0)
    {
        *ppv = (IDeckLinkDeviceNotificationCallback*)this;
        AddRef();
        result = S_OK;
    }
    
    return result;
}

ULONG           DeckLinkDeviceDiscovery::AddRef (void)
{
    return OSAtomicIncrement32(&refCount);
}

ULONG           DeckLinkDeviceDiscovery::Release (void)
{
    int32_t		newRefValue;
    
    newRefValue = OSAtomicDecrement32(&refCount);
    if (newRefValue == 0)
    {
        delete this;
        return 0;
    }
    
    return newRefValue;
}
