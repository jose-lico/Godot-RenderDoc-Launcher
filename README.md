# GodotRenderDocLauncher

This plugin tool adds a button to Godot's editor allowing you to easily launch RenderDoc so you can quickly see how your changes are affecting the game's rendering.

<p align="center">
<img src="addons/renderdoc_launcher/res/renderdoc_logo.png" alt= "RenderDocLogo" width="64">
<img src="icon.png" alt= "RenderDocLogo" width="">
</p>

## Motivation

I created this plugin to simplify my workflow when using RenderDoc.

Previously, I had to export my game and adjust RenderDoc's settings each time I made a change, which was tedious. I later discovered that I could directly launch Godot with the command-line argument "--path <path_to_your_project>" instead of launching the game's executable, which made things easier. 

However, I still wanted quicker access to RenderDoc without having to navigate through multiple menus or search for file paths.

## Walkthrough

<p align="center">
<img src="addons/renderdoc_launcher/.github/RenderDocLauncherButton.png" alt= "RenderDocLauncherButton" width="75%">
</p>

The first time you click the button you will be prompted to provide RenderDoc's location. This will be save in a resource file.

<p align="center">
<img src="addons/renderdoc_launcher/.github/RenderDocLauncherLocation.png" alt="RenderDocLauncherLocation" width="75%">
</p>

After you provide RenderDoc's location, it will be launched and the game will automatically start. This and other launch settings can be found at addons/renderdoc_launcher/res/settings.cap.

<p align="center">
<img src="addons/renderdoc_launcher/.github/RenderDocLauncherExample.png" alt="RenderDocLauncherExample" width="75%">
</p>

---

Hope this small tool can make your life easier when optimzing and iterating :)
