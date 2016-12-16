/*----------------------------------------------------------------------------
   Copyright (C) 2012-2016 Microsoft Corporation
    
   Licensed under the Apache License, Version 2.0 ("The Licence"). You may not
   use this file except in compliance with the License. A copy of the License
   can be found in the file "license.txt" at the root of this distribution.
----------------------------------------------------------------------------*/

/* Date and time functionality.

   Months, weeks, days etc. are always 1-based, while durations are always in (fractional) seconds.
*/
module std/time

public import std/time/duration
public import std/time/instant
public import std/time/utc
public import std/time/chrono
public import std/time/timer

public import std/time/download
public import std/time/date
public import std/time/calendar
public import std/time/calendars
public import std/time/time

public import std/time/locale
public import std/time/format
public import std/time/parse