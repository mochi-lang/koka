/*----------------------------------------------------------------------------
   Copyright (C) 2012-2016 Microsoft Corporation
    
   Licensed under the Apache License, Version 2.0 ("The Licence"). You may not
   use this file except in compliance with the License. A copy of the License
   can be found in the file "license.txt" at the root of this distribution.
----------------------------------------------------------------------------*/

/* Low level time stamps.

These are unit-less and may not necessarily be in (TAI) SI seconds, and
are used internally to do time scale conversions and calendar calculations. 
User code should use `:std/time/duration/duration`s and `:std/time/instant/instant`s instead.
*/
module std/time/timestamp

import std/text/regex
import std/num/fixed

// Time spans are just fixed point numbers. This gives arbitrary range
// with up to femto-second precision (10^-15^s).
public alias timespan = fixed

public val timespan0 : timespan = zero

/*----------------------------------------------------------------------------
  Timestamps are timespan's since some epoch in some time unit.
  Timestamps expose leap seconds (when appropiate for the time scale)
----------------------------------------------------------------------------*/

// A time stamp is a `:timespan` since some epoch. Time stamps also keep 
// track of possible leap seconds when the unit is in Unix/UTC seconds.
abstract struct timestamp(
  since : timespan,
  // the extra leap seconds
  public leap-seconds : int
)

// The time stamp at its epoch.
public val timestamp0 : timestamp = Timestamp(zero,0)


// Create a time stamp from a `:timespan` since some epoch.
public fun timestamp( t : timespan, leap-seconds : int = 0 ) : timestamp {
  Timestamp(t,leap-seconds)
}

// Create a time stamp in seconds and fraction of seconds since its epoch.
// Can also pass possible `leap-seconds` (=`0`). If the unit is in Unix seconds
// (where a day is always 86400 seconds) this is used to indicate extra leap seconds in that day.
public fun timestamp( secs : int, frac : double = 0.0, leap-seconds : int = 0 ) : timestamp {
  timestamp(fixed(secs,frac), leap-seconds)
}

// Create a time stamp in seconds since its epoch
public fun timestamp( secs : double, leap-seconds : int = 0 ) : timestamp {
  timestamp(fixed(secs),leap-seconds)
}

// The time span since the epoch of the time stamp. (including leap seconds)
public fun timespan( ts : timestamp ) : timespan {
  ts.seconds
}

// The total seconds (in some time unit) since the epoch of the time stamp.
// This includes possible leap seconds.
public fun seconds( ts : timestamp ) : fixed {
  ts.since + ts.leap-seconds.fixed
}

// Round a time stamp to a certain precision (`prec` is number of digits of the fraction of the second).
public fun round-to-prec(t : timestamp, prec : int ) : timestamp {
  Timestamp(t.since.round-to-prec(prec), t.leap-seconds)
}


// Forget the leap seconds.
public fun without-leap-seconds( ts : timestamp ) : timestamp {
  Timestamp(ts.since,0)
}

// Return the non-leap seconds since its epoch.
public fun non-leap-seconds( ts : timestamp ) : timespan {
  ts.since
}

// Add `leaps` leap seconds to the time stamp.
public fun add-leap-seconds( ts : timestamp, leaps : fixed ) : timestamp {
  if (!leaps.pos?) then ts 
  elif (leaps < fixed(1.0) && ts.leap-seconds.zero?) 
   then Timestamp( (ts.since - 1.fixed) + leaps, 1)
   else Timestamp( ts.since + leaps.fraction.fixed, ts.leap-seconds + leaps.trunc )
}



// Return the total non-leap seconds, the positive fraction (in the range [0,1.0>), and the leap seconds.
// This is used when displaying calendar time such that leap seconds can be displayed correctly.
public fun calendar-seconds( ts : timestamp ) : (int,double,int) {
  (ts.since.floor, ts.since.ffraction, ts.leap-seconds)
}

// Compare two `:timestamp`s. 
public fun compare( i : timestamp, j : timestamp ) : order {
  match(compare(i.since,j.since)) {  // compare without leap-seconds first!
    Eq  -> compare(i.leap-seconds,j.leap-seconds)
    ord -> ord
  }
}

public fun (<)( i : timestamp, j : timestamp )  : bool { compare(i,j) == Lt }
public fun (<=)( i : timestamp, j : timestamp ) : bool { compare(i,j) != Gt }
public fun (>)( i : timestamp, j : timestamp )  : bool { compare(i,j) == Gt }
public fun (>=)( i : timestamp, j : timestamp ) : bool { compare(i,j) != Lt }
public fun (==)( i : timestamp, j : timestamp ) : bool { compare(i,j) == Eq }
public fun (!=)( i : timestamp, j : timestamp ) : bool { compare(i,j) != Eq }

// The minimum of two timestamps.
public fun min( i : timestamp, j : timestamp ) : timestamp {
  if (i <= j) then i else j
}

// The maximum of two timestamps.
public fun max( i : timestamp, j : timestamp ) : timestamp {
  if (i >= j) then i else j
}

// Add a time span to a time stamp.
public fun (+)( ts : timestamp, t : timespan ) : timestamp {
  Timestamp(ts.since + t, ts.leap-seconds)
}

// Subtract a time span from a time stamp.
public fun (-)( ts : timestamp, t : timespan ) : timestamp {
  Timestamp(ts.since - t, ts.leap-seconds)
}

// Difference between two time stamps.
//public fun (-)( ts1 : timestamp, ts2 : timestamp ) : timespan {
//  ts1.since - ts2.since
//}

// Show a time stamp (without the `s` postfix).
public fun ts-show( ts : timestamp, max-prec : int = 9, secs-width : int = 1 ) : string {
  val s = ts.since.show(max-prec=max-prec)
  val l = if (ts.leap-seconds.zero?) then "" else " (+" + ts.leap-seconds.show + " leap)"
  //trace("show timestamp: " + s + ", " + ts.since.show + ", " + ts.since.show(max-prec))
  match(s.find(".")) {
    Nothing -> s.pad-left(secs-width,'0') + l
    Just(dot) -> {
      val f = dot.after.string
      val len3 = ((f.count + 2)/3)*3
      dot.before.string.pad-left(secs-width,'0') + "." + f.pad-right(len3,'0') + l
    }
  }
}


