# pinTAR

Planning a trip? Want to closely examine your destination in advance to scope out beautiful places to see?

Fond memories? Want to remember that great hike and share it with your friends and family with the context for where those cute pictures came from?

If so, pinTAR may be for you.  pinTAR lets\* you load up any location in Apple Maps 3D view and explore it in AR.  You can leave notes, photos and videos, or even view those that you've already taken in context using their location information.

Additional information on pinTAR, including the full concept deck is available: 

\* *Restrictions apply. Void where prohibited. Not all functionality implemented. ;)*

## Overview

pinTAR is a proof of concept ARKit application created during the October 6-7th "Hack the now and next" in Seattle, WA.  pinTAR allows the user to use an iOS device with ARKit support to identify a plane in space and spawn a landscape.  The user can tap to add 'pins' to the landscape to identify points of interest.  Pins can be dismissed with a simple swipe, and are also dismissed if the landscape is unloaded by the user.

## Getting Started

ARKit and this app require iOS 11 and a device with an A9 (or later) processor.

## Complile and Launch

To compile, you'll need Xcode 9 or greater.  ARKit apps must be run on an actual device and won't work in the simulator.

A dashed yellow square will appear in the center of your screen, along with directions at the top left.  Sweep the camera view slowly along a flat plane to identify an appropriate surface to project pinTAR.  When you've identified an ideal location, the square will have mapped itself onto the plane and will have a full edge.  If you can't find an ideal surface, as long as the square is flat along the surface, even if not completed, pinTAR will work.

## Place the Landscape

Once you have identified a surface to preject onto, press the (+) button and select "islands" to place the landscape at the location of the square.

## Add pins

Tap anywhere on the landscape to add a pin.  Walk around the landscape to see it from different angles.  The flat face of the pin will adjust to face you.

If a pin collides with an existing pin it will bounce off.

Swipe left to right to dismiss all the pins.

## Team

Jimmy Lee
Brian Nguyen
Sarah Outhwaite
Kristina Rakestraw
Gabe Stocco

## References

Apple's ARKit sample code: https://developer.apple.com/documentation/arkit/handling_3d_interaction_and_ui_controls_in_augmented_reality

AppCoda SimpleARKitDemo: https://www.appcoda.com/arkit-introduction-scenekit/

Twin Islands 3D Model: https://free3d.com/3d-model/twin-islands-32356.html
