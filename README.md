# DotCleanPlus
Clean up MacOS artifacts from the device.

## How it works
Removes all the macOS artifacts: `.DS_Store`, `._*` files, `.Trashes`, `.VolumeIcons.icns`, `.Spotlight-V100`, and `.fseventsd`

Searches recursively through all directories, including hidden ones

Shows output as a filecount, and writes the session to a file called `removed_log.txt`

## Installation and usage

Place the entire `DotCleanPlus` folder inside the `App` folder in your SD Card.  Then, go to the Apps menu on your Miyoo Mini/Plus running OnionOS, and run the DotCleanPlus app.

It will run through a few steps to check and delete each filetype, report status, and wait for user input/close.
It may take a while, so if you have aggressive sleep settings, you may want to hit a button once in a while.
