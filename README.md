# Infopi Script
This little python script feteches sheduled appointments from a teamup.com online timetable and displays them on the command line.
It is designed to work with a Raspberry Pi with Raspberry Pi OS Lite (console only) and a monitor as infoscreen.

## Installation
Just copy the main.py to the Pis user home directoy and start it.
For autostart, enable autologin for the defauult user via ssh as default user:

    sudo raspi-config
    
Enable *Console Autologin* from submenu *System Options* and reboot.
The default user should be auto logged in after reboot.

Install the requirements of the script using *pip* (See below for virtual environment):

    pip install -r requirements.txt
    
or use apt:

    sudo apt install -y python3-requests python3-icalendar python3-tz python3-rich

And add the following line to your .bashhrc file inside the users home directory:

    # Autostart calendar
    sleep 3 && python3 /home/robot/main.py
    
After rebooting again, the default user should be auto logged in and the script should start.

### Virtueal Environment (venv)
Instead of a systemwide installation of the required packages, you can use a virtual python environment like this:

    sudo apt install -y python3-venv
    python3 -m venv .venv
    source .venv/bin/activate
    python -m pip install --upgrade pip setuptools wheel
    pip install -r requirements.txt

## Usage
Create a file *URLS.txt* at the same directory as the *main.py*.
Enter ics file links and a name at every row, like this:

   https://ics.teamup.com/feed/.../7846707.ics, Labor
   https://ics.teamup.com/feed/.../10974149.ics, Max (Python)
   
with URLs to *.ics* files with appointments. The list can include several ics links and a name of the timetable.
The script will check the files hash for changes every second. 
