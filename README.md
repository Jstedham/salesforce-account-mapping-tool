# Account Geolocation and Assignment Tool

A Salesforce application built with LWC and Apex that provides a map-based interface for geocoding and assigning accounts. This project demonstrates Asynchronous Apex (Batchable, Queueable), Apex REST Callouts, and front-end development with Lightning Web Components.

## Features
- Interactive Map Interface: View and select accounts on an interactive map, built with Lightning Web Components.
- Third-Party Geocoding: Automatically convert account addresses into geographic coordinates using REST callouts to a third-party API.

Asynchronous Processing:
- Nightly Batch Job: A batch job runs nightly to update accounts that are missing geocoding information.
- User-Initiated Geocoding: Users can select accounts from a list view to be geocoded on demand via a Queueable Apex job.
- Flow and Invocable Apex: A screen flow allows users to initiate the geocoding process, which calls an Invocable Apex method to enqueue the asynchronous job.
