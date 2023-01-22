# SpeedCrop

Speedcrop is an application to quickly crop many images within a folder to a certain resolution. It is based on the [Godot Engine](https://godotengine.org/) (4.0) and supports the same formats the Engine supports for import and export (PNG, JPG, WEBP).

The main focus was providing a as fast as possible workflow for cropping images to a certain resolutiom while still remaining as simple as possible. After configuring the initial settings on the right, you can move forward on the left hand, while selecting the area with the right hand.

For more I suggest taking a look at the [Showcase](#showcase).

![Application preview](https://user-images.githubusercontent.com/18115780/213894048-d93189b7-4cb1-40b4-8f21-5a9789b9bf8a.png)

- [SpeedCrop](#speedcrop)
  - [Features](#features)
  - [Usage](#usage)
  - [Why](#why)
  - [Showcase](#showcase)
  - [Misc](#misc)
    - [SCONS config for the export templates](#scons-config-for-the-export-templates)
    - [Copyright and license information](#copyright-and-license-information)

## Features

* PNG, JPG, WEBP support
* Lazy loading of images enabling browsing of large folders (I tried up to 20.000 images)
* Rotate images by 90°
* Remembers previous region when going back to an image
* Threaded loading and saving of images so that the application remains as responsive as possible
* Support for templating the output file name (more on that later)
* Responsive UI which fits even on small screens
* Written in basic GDScript using only engine features, so should be easy to understand and modify for people familiar with the engine

## Usage

If available, grab the latest release for your platform from the [releases page](https://github.com/NetroScript/SpeedCrop/releases). They are custom compiled versions of the export template to be as small as possible. Otherwise, you can download the source code and run it with the Godot Engine. I made it while Godot 4.0 was still in beta, so my provided binaries are built on top of commit `c3539b4561f9b4d7dc4ba1c5859217e7fbf9c6fe`.

Now just run the application. On the right side click the folder icon for `Input Path`, select your folder with the images you want to crop. Next select an output path. If you do not provide one, the current working directory will be used.

If you want you can modify the output file name template. This is a string which will be used to generate the output file name (and also folder structure). It can contain the following placeholders:

```
{directory_tree}    - The relative folder tree to the original image
{file}              - The filename (without extension)
{extension}         - The file extension
{index}             - The index the image had in this application
{width}             - The width at which it was cropped
{height}            - The height at which it was cropped
{rotations}         - How often the image was rotated (negative = counterclockwise, positive=clockwise)
{rect.x}            - The cropped area top left x position (in the original image)
{rect.y}            - The cropped area top left y position (in the original image)
{rect.width}        - How wide the cropped area originally was
{rect.height}       - How high the cropped area originally was
```

By using `{directory_tree}` you can create a folder structure which mirrors the original folder structure. Alternatively you can leave it out and use `{index}` to create a flat folder structure without overwriting files. An example template could be `{directory_tree}/{file}_{width}x{height}.{extension}` for a more detailed name or also for a flat directory structure `{index}_{file}.{extension}`.

As a last setting you can select the output format. This is the format the cropped images will be saved as. It can be different from the input format. If you want to keep the original format, select `Same as input`.

Now you can go to cropping images. For that you have the following controls available (which you can also show within the application by pressing F1):

```
Space / Right -   Move to next image (Moving between images will save the cropped image to disk)
Left          -   Move to previous image
Q             -   Rotate image counterclockwise
R             -   Rotate image clockwise
ESC           -   Unfocus GUI element

Mouse in the main area:

Mouse Wheel         -   Zoom in / out at mouse position
Right Click, Drag   -   Zoom in / out, x coordinate is a bit slower than y coordinate
Left Click, Pan     -   Move the selected area

Mouse in the bottom area:

Mouse Wheel         -   Scroll through images
Left Click          -   Select image
```

And thats it already.

## Why

You might ask why I made something like that. This is because I personally needed many cropped images at a specific resolution. Sure web tools might exist with nice UI, but they aren't local, thus not as fast and don't have direct access to the filesystem.

There are also existing tools which are very good at cropping, but only specific stuff, where you would first need for example a feature detector. Something like this is mostly only easily available for faces for example. If this was your use case, a library like  [autocrop](https://github.com/leblancfg/autocrop) is a much better choice than this application.

In any case this was a fun project to make and I hope it can be useful for someone else as well. And it was the first time I made something with Godot which is exclusively an application and not a game. Because of this I also provide the two exports with a more optimized executable size compared to the default export templates.

## Showcase

As demo images I used some tree images generated with Stable Diffusion here.

First have a video showing the application in action:

https://user-images.githubusercontent.com/18115780/213894630-54bdb299-1ea4-4109-adad-ab1542364571.mp4

The application is made quite responsively and should fit on every screen. 

![Application scales freely](https://user-images.githubusercontent.com/18115780/213894696-05a49809-c3d5-4931-b7c8-17327e09e929.png)

Here you can see the info text you can toggle with F1.

![Controls displayed within the application](https://user-images.githubusercontent.com/18115780/213894721-bf2c6c20-bd49-43be-a6dd-a882db2b04fa.png)

## Misc

### SCONS config for the export templates

Should you be interested in the command I used to build the export templates, here it is:

```sh
# Windows
scons -j8 platform=windows target=template_release production=yes arch=x86_64 optimize=size use_lto=yes disable_3d=yes module_bmp_enabled=no module_astcenc_enabled=no module_zip_enabled=no module_xatlas_unwrap_enabled=no module_websocket_enabled=no module_webrtc_enabled=no module_vorbis_enabled=no module_upnp_enabled=no module_theora_enabled=no module_tga_enabled=no module_squish_enabled=no module_ogg_enabled=no module_multiplayer_enabled=no module_minimp3_enabled=no module_lightmapper_rd_enabled=no module_jsonrpc_enabled=no module_etcpak_enabled=no module_enet_enabled=no module_basis_universal_enabled=no

# Linux
scons -j8 platform=linux target=template_release production=yes arch=x86_64 optimize=size use_lto=yes disable_3d=yes module_bmp_enabled=no module_astcenc_enabled=no module_zip_enabled=no module_xatlas_unwrap_enabled=no module_websocket_enabled=no module_webrtc_enabled=no module_vorbis_enabled=no module_upnp_enabled=no module_theora_enabled=no module_tga_enabled=no module_squish_enabled=no module_ogg_enabled=no module_multiplayer_enabled=no module_minimp3_enabled=no module_lightmapper_rd_enabled=no module_jsonrpc_enabled=no module_etcpak_enabled=no module_enet_enabled=no module_basis_universal_enabled=no

```

### Copyright and license information

This project is licensed under the MPL-2.0 license.

Following parts of the project are contained which are licensed under different licenses:
The used Godot Engine itself, and the provided icons which were also used here and are provided in the `/assets/icons` folder. For specific details see the [copyright notice](https://github.com/godotengine/godot/blob/master/COPYRIGHT.txt) of the Godot Repository. 

Additionally the contained font `Cantarell` is licensed under the OFL-1.1 license. For more information see the license file in the `/assets/fonts/cantarell` folder. 
