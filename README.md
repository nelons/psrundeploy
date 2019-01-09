Powershell Run & Deploy

This is a project I started that would work via Windows logon scripts to run command files and deploy software, ala Configuration Manager but a lot less cut down. I needed a way to run custom scripts on client machines at startup and although making a start on this, another solution was provided to me whilst writing it so this is being, either temporarily or permanently abandoned.

I don't know what state this is in, though there should be some functionality.

GPO

Ensure workstations are set to wait for the network at startup.
Put core.ps1 in a shared location (i.e. sysvol) and as a startup script for the machines.

Core.ps1

There are two settings:

    - registry location to store information about packages deployed.
    - the file location for package data - this should be a SMB share.

Packages

Each package has it's own folder in the file location above. There must be a "package.json" file in the folder, which contains configuration data in a JSON format. The options are quite straight forward:

info\registry - the registry key to store information under.
run - what to do to run the package. This is currently local, look in core.ps1 to adapt to run from the share.
apply - what clients to apply it to
- some examples in the package.json here about using regex to find clients or them to be defined explicitly. Also whether to only run once (increase the value to "re-advertise" and run again) or to always run. Different array entries would constitute a new advertisment.

Todo

- Ensure the registry values in each package are unique.
- Expand run key to indicate whether a file is located relative to package.json or absolute (another server)
- Logging
- Lots of testing.

License

There is no license to this. Feel free to use as you will in all projects, personal, commercial, whatever. Attribution not required though I'd love to hear if you find this useful or make something of it :)