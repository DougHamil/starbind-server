Starbind
===============

Starbind is a program to allow easy mod synchronization between clients and servers for the game Starbound.

If you host a Starbound server and would like to allow players to use Starbind to synchronize mods specifically for your
server, then follow the Server installation instructions below.

Hosting a Starbind Server
---------------------------------
Starbind runs on NodeJS, which must be installed before continuing.
NodeJS can be installed on [Windows](http://nodejs.org/download/), [Mac](http://nodejs.org/download/), and [common Linux distros](https://github.com/joyent/node/wiki/Installing-Node.js-via-package-manager)

Once NodeJS is installed, download Starbind using Git:
` git clone https://github.com/DougHamil/starbind-server.git`

Edit the config.default.json file to have the PORT property specify which port you would like to host your Starbind server on (this is NOT the same port as your Starbound game server).  Also set the STARBOUND_INSTALL_DIR property to point to the path of your Starbound game installation (this is the directory that contains the 'assets' directory).

Starbind will automatically try to find your installation directory for Starbound if you specify an invalid path.

Install Starbind NodeJS dependencies with

` npm install`

And run Starbind with

` node app.js`
