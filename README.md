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

Copy the config_server.default.json file to config.json
` cp config_server.default.json config.json`

Edit the new config.json file to match the settings you desire.
> PORT: The port for the Starbind server, NOT the same port as your Starbound game server
> STARBOUND_INSTALL_DIR: Path to the base of your Starbound game installation
> ADMIN_USERNAME: Username for the admin login
> ADMIN_PASSWORD: Password for the admin login
> HTTPS_KEY_FILE: Key.pem file for HTTPS, if you want use HTTPS specify the location of the file using the property
> HTTPS_CERT_FILE: cert.pem file for HTTPS, if you want to use HTTPS specify the location of the cert.pem file here.

If you leave ADMIN_USERNAME or ADMIN_PASSWORD unset or an empty string, admin login will be disabled.
If the HTTPS_KEY_FILE or HTTPS_CERT_FILE properties don't point to valid locations, then Starbind will fall back to HTTP

Next, install Starbind NodeJS dependencies with

` npm install`

And run Starbind with

` node app.js server`

For players to use Starbind, give them the address to your Starbind server:

`http://myawesomeserver:1337`

They can then use this address in the Starbind client to easily sync any mods you've installed on your server.

Installing Mods
----------------------
To install a mod on the server, just drop the mod zip file in the mods directory in your Starbind installation directory.
Starbind supports the standard mod zip packages and will look for a mod.json metadata file for mod info.
Additionally, Starbind does merging and allows for partial mods to base game assets.  See mod merging below for more info.

After adding a mod zip folder to the mods directory, you will need to restart Starbind server in order for the changes to be merged in.

At the moment there is no mod manager besides a simple mod package listing available if you set a admin username/password and navigate
to the Starbind server on your browser. Please not

Mod Support
-----------------------
Starbind works with zipped mod packages as most other mod managers. Starbind also supports differential mods to existing game assets
meaning a mod can specify a player.config mod and only list the properties that should change. Starbind will read in the existing player.config
file from the Starbound/assets directory and merge the change in intelligently. It will do the same with any conflicting mods.