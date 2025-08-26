from datetime import datetime
import requests
from icalendar import Calendar, Event, vDDDTypes
from pytz import timezone
from rich.console import Console
from rich.table import Table
import time
import os
import hashlib
import csv


def load_urls_with_names(filepath="URLS.txt"):
    urls_with_names = []
    if not os.path.exists(filepath):
        return urls_with_names
    with open(filepath, "r") as f:
        reader = csv.reader(f)
        for row in reader:
            if not row or len(row) < 2:
                continue
            url = row[0].strip()
            name = row[1].strip()
            if url:
                urls_with_names.append((url, name))
    return urls_with_names

def process(ics_urls_with_names):
    # Timezone in which the events should be displayed
    local_tz = timezone('Europe/Berlin')

    # Collect all future events from all calendars
    future_events = []

    for ics_url, calendar_name in ics_urls_with_names:
        # Download the ICS file
        response = requests.get(ics_url)
        response.raise_for_status()  # Ensures the request was successful

        # Parse the ICS file
        cal = Calendar.from_ical(response.text)

        # Current time in the correct timezone
        now = datetime.now().astimezone(local_tz)

        # Collect all future events
        for component in cal.walk():
            if isinstance(component, Event):
                dt_start = vDDTYpes_to_datetime(component.get('dtstart'))
                dt_end = vDDTYpes_to_datetime(component.get('dtend'), end_time=datetime.max.time())
                dt_start = dt_start.astimezone(local_tz)
                dt_end = dt_end.astimezone(local_tz)
                component['dtstart'] = dt_start
                component['dtend'] = dt_end
                component['calendar_name'] = calendar_name  # Add calendar name to the event

                # Add if the event has not yet passed
                if dt_start >= now or dt_end >= now:
                    future_events.append(component)

    # Sort events by start time
    future_events.sort(key=lambda x: x.get('dtstart'))

    return future_events


def vDDTYpes_to_datetime(time_obj, end_time=datetime.min.time()):
    if isinstance(time_obj, vDDDTypes):
        time_obj = time_obj.dt

    if not isinstance(time_obj, datetime):
        time_obj = datetime.combine(time_obj, end_time)

    return time_obj


def display_events(future_events, num_of_elements_displayed=10):
    local_tz = timezone('Europe/Berlin')
    console = Console()
    table = Table(show_header=True, header_style="bold magenta", show_lines=True)
    table.add_column("Start Time")
    table.add_column("End Time")
    table.add_column("Event Name")
    table.add_column("Description")
    table.add_column("Calendar Name")

    now = datetime.now().astimezone(local_tz)

    for event in future_events[:num_of_elements_displayed]:
        dt_start = vDDTYpes_to_datetime(event.get('dtstart'))
        dt_end = vDDTYpes_to_datetime(event.get('dtend'), end_time=datetime.max.time())
        dt_start = dt_start.astimezone(local_tz)
        dt_end = dt_end.astimezone(local_tz)

        # Check if the event is currently ongoing
        if dt_start <= now <= dt_end:
            style = "on red"  # Background color for ongoing events
        else:
            style = ""

        table.add_row(
            dt_start.strftime('%d.%m.')
            if dt_start.time().hour == 0 and dt_start.time().minute == 0 else dt_start.strftime('%d.%m. %H:%M'),
            dt_end.strftime('%d.%m.')
            if dt_end.time().hour == 23 and dt_end.time().minute == 59 else dt_end.strftime('%d.%m. %H:%M'),
            event.get('summary').strip(),
            event.get('description').strip() if event.get('description') else "",
            event.get('calendar_name'),  # Display calendar name
            style=style)

    console.print(table)


def hash_events(events):
    """Create a hash of the list of events to detect changes."""
    events_str = ''.join(
        [event.get('summary', '') + str(event.get('dtstart')) + str(event.get('dtend')) for event in events])
    return hashlib.md5(events_str.encode('utf-8')).hexdigest()


if __name__ == '__main__':
    # List of URLs of your ICS files with calendar names
    _urls_with_names = load_urls_with_names()
    
    previous_hash = None

    while True:
        try:
            _future_events = process(_urls_with_names)
            current_hash = hash_events(_future_events)

            if current_hash != previous_hash:
                os.system('clear')  # Clear the console screen (for Linux)
                display_events(_future_events)
                previous_hash = current_hash
        except Exception:
            pass

        time.sleep(1)  # Wait for 2 seconds before refreshing
