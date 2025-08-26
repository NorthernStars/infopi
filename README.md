# Infopi Script
This little python script feteches sheduled appointments from a teamup.com online timetable and displays them on the command line.
It is designed to work with a Raspberry Pi with Raspberry Pi OS Lite (console only) and a monitor as infoscreen.

## Installation
1. Clone this repository to the *infopi* directory in the Pis default user home directory:

    git clone https://github.com/NorthernStars/infopi.git
    
2. Go into the *infopi* directoy

    cd infopi
    
3. Make the script executable

    chmod a+x install.sh uninstall.sh

4. Run the install script as root:

    sudo ./install.sh

## Usage
Create a file *URLS.txt* at the same directory as the *main.py*.
Enter ics file links and a name at every row, like this:

   https://ics.teamup.com/feed/.../7846707.ics, Labor
   https://ics.teamup.com/feed/.../10974149.ics, Max (Python)
   
with URLs to *.ics* files with appointments. The list can include several ics links and a name of the timetable.
The script will check the files hash for changes every second.

## Uninstallation
Run the uninstall script:

    sudo ./uninstall.sh
    
Uninstall is AI generated and was not tested, so use with caution!
