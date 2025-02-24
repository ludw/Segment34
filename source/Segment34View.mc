import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.ActivityMonitor;
import Toybox.Application;
import Toybox.Weather;
import Toybox.Time;
import Toybox.Math;
import Toybox.SensorHistory;
import Toybox.Position;

const INTEGER_FORMAT = "%d";

class Segment34View extends WatchUi.WatchFace {

    private var isSleeping = false;
    private var lastCondition = null;
    private var lastUpdate = null;

    function initialize() {
        WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        // Get and show the current time
        var clockTime = System.getClockTime();
        var now = Time.now().value();

        var secLabel = View.findDrawableById("SecondsLabel") as Text;
        if(isSleeping) {
            secLabel.setText("");
        } else {
            var secString = Lang.format("$1$", [clockTime.sec.format("%02d")]);
            secLabel.setText(secString);
        }

        if(clockTime.sec % 2 == 0) {
            setHR(dc);
            setHRIcons(dc);
            setNotif(dc);
        }
        
        if(lastUpdate != null && now - lastUpdate < 30 && clockTime.sec % 60 != 0) {
            View.onUpdate(dc);
            setStressAndBodyBattery(dc);
            setWeatherIcon(dc);
            return;
        }
        var hour = clockTime.hour;
        if(!System.getDeviceSettings().is24Hour) {
            hour = hour % 12;
            if(hour == 0) { hour = 12; }
        }
        var timeString = Lang.format("$1$:$2$", [hour.format("%02d"), clockTime.min.format("%02d")]);
        var timelabel = View.findDrawableById("TimeLabel") as Text;
        timelabel.setText(timeString);
        

        // time background 
        var timebg = View.findDrawableById("TimeBg") as Text;
        timebg.setText("#####");

        setMoon(dc);
        setWeather(dc);
        setSunUpDown(dc);
        setDate(dc);
        setStep(dc);
        setTraining(dc);
        setBatt(dc);
        
        View.onUpdate(dc);
        setStressAndBodyBattery(dc);
        setWeatherIcon(dc);

        lastUpdate = now;
    }

    function onPartialUpdate(dc) {
    }

    function onPowerBudgetExceeded() {
        System.println("Power budget exceeded");
    }

    hidden function setHRIcons(dc) as Void {
        var hrIconW = View.findDrawableById("HRIconW") as Text;
        var hrIconR = View.findDrawableById("HRIconR") as Text;

        if (isSleeping) {
            hrIconR.setText("h");
            hrIconW.setText("H");
        } else {
            hrIconR.setText("H");
            hrIconW.setText("h");
        }
        
    }

    hidden function setMoon(dc) as Void {
        var now = Time.now();
        var today = Time.Gregorian.info(now, Time.FORMAT_SHORT);
        var moonVal = moon_phase(today);
        var moonLabel = View.findDrawableById("MoonLabel") as Text;
        moonLabel.setText(moonVal);
    }
    
    hidden function setHR(dc) as Void {
        var value = "";
        // Try to retrieve live HR from Activity::Info
        var activityInfo = Activity.getActivityInfo();
        var sample = activityInfo.currentHeartRate;
        if (sample != null) {
            value = sample.format(INTEGER_FORMAT);
        } else if (ActivityMonitor has :getHeartRateHistory) {
            // Falling back to historical HR from ActivityMonitor
            sample = ActivityMonitor.getHeartRateHistory(1, /* newestFirst */ true).next();
            if ((sample != null) && (sample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE)) {
                value = sample.heartRate.format(INTEGER_FORMAT);
            }
        }

        var hrLabel = View.findDrawableById("HRLabel") as Text;
        hrLabel.setText(value);
        hrLabel.draw(dc);
    }

    hidden function setBatt(dc) as Void {
        var value = "";
        var sample = System.getSystemStats().battery / 5;
        for(var i = 0; i < sample; i++) {
            value += "$";
        }
        var battLabel = View.findDrawableById("BattLabel") as Text;
        battLabel.setText(value);
    }

    hidden function setWeather(dc) as Void {
        var weather = Weather.getCurrentConditions();
        if (weather == null) { return; }
        lastCondition = weather.condition;
        if(lastCondition == null) { return; }

        if(weather.temperature != null) {
            var tempUnit = System.getDeviceSettings().temperatureUnits;
            var temp = weather.temperature;
            var tempLabel = View.findDrawableById("TempLabel") as Text;
            if(tempUnit != System.UNIT_METRIC) {
                temp = (temp * 9/5) + 32;
            }
            tempLabel.setText(temp.format(INTEGER_FORMAT));
        }
        
        var windLabel = View.findDrawableById("WindLabel") as Text;
        if(weather.windSpeed != null) {
            windLabel.setText(weather.windSpeed.format(INTEGER_FORMAT));
        }

        if(weather.windBearing != null) {
            var windIcon = View.findDrawableById("WindIcon") as Text;
            var bearing = (Math.round((weather.windBearing.toFloat() + 180) / 45.0).toNumber() % 8).format(INTEGER_FORMAT);
            windIcon.setText(bearing);
        }
    }

    hidden function setWeatherIcon(dc) as Void {
        var icon;
        if(lastCondition == null) {
            return;
        }
/*

Remaining weathers:

CONDITION_WINDY
CONDITION_ICE
CONDITION_SQUALL
CONDITION_FLURRIES
CONDITION_FREEZING_RAIN
CONDITION_ICE_SNOW

*/


        switch(lastCondition) {
            case Weather.CONDITION_MOSTLY_CLEAR:
            case Weather.CONDITION_CLEAR:
                icon = Application.loadResource( Rez.Drawables.w_clear ) as BitmapResource;
                break;
            case Weather.CONDITION_FAIR:
            case Weather.CONDITION_THIN_CLOUDS:
            case Weather.CONDITION_PARTLY_CLEAR:
            case Weather.CONDITION_PARTLY_CLOUDY:
                icon = Application.loadResource( Rez.Drawables.w_partly_cloudy ) as BitmapResource;
                break;
            case Weather.CONDITION_MOSTLY_CLOUDY:
                icon = Application.loadResource( Rez.Drawables.w_mostly_cloudy ) as BitmapResource;
                break;
            case Weather.CONDITION_CLOUDY:
                icon = Application.loadResource( Rez.Drawables.w_cloudy ) as BitmapResource;
                break;
            case Weather.CONDITION_CLOUDY_CHANCE_OF_RAIN:
            case Weather.CONDITION_CHANCE_OF_SHOWERS:
            case Weather.CONDITION_SHOWERS:
            case Weather.CONDITION_SCATTERED_SHOWERS:
            case Weather.CONDITION_UNKNOWN_PRECIPITATION:
            case Weather.CONDITION_RAIN:
                icon = Application.loadResource( Rez.Drawables.w_rain ) as BitmapResource;
                break;
            case Weather.CONDITION_LIGHT_SHOWERS:
            case Weather.CONDITION_DRIZZLE:
            case Weather.CONDITION_LIGHT_RAIN:
                icon = Application.loadResource( Rez.Drawables.w_light_rain ) as BitmapResource;
                break;
            case Weather.CONDITION_HEAVY_SHOWERS:
            case Weather.CONDITION_HEAVY_RAIN:
                icon = Application.loadResource( Rez.Drawables.w_heavy_rain ) as BitmapResource;
                break;
            case Weather.CONDITION_CLOUDY_CHANCE_OF_RAIN_SNOW:
            case Weather.CONDITION_CHANCE_OF_RAIN_SNOW:
            case Weather.CONDITION_LIGHT_RAIN_SNOW:
            case Weather.CONDITION_HEAVY_RAIN_SNOW:
            case Weather.CONDITION_SLEET:
            case Weather.CONDITION_WINTRY_MIX:
            case Weather.CONDITION_RAIN_SNOW:
                icon = Application.loadResource( Rez.Drawables.w_rain_snow ) as BitmapResource;
                break;
            case Weather.CONDITION_CLOUDY_CHANCE_OF_SNOW:
            case Weather.CONDITION_CHANCE_OF_SNOW:
            case Weather.CONDITION_FLURRIES:
            case Weather.CONDITION_SNOW:
                icon = Application.loadResource( Rez.Drawables.w_snow ) as BitmapResource;
                break;
            case Weather.CONDITION_LIGHT_SNOW:
                icon = Application.loadResource( Rez.Drawables.w_light_snow ) as BitmapResource;
                break;
            case Weather.CONDITION_HEAVY_SNOW:
                icon = Application.loadResource( Rez.Drawables.w_heavy_snow ) as BitmapResource;
                break;
            case Weather.CONDITION_MIST:
            case Weather.CONDITION_FOG:
                icon = Application.loadResource( Rez.Drawables.w_fog ) as BitmapResource;
                break;
            case Weather.CONDITION_HAZY:
            case Weather.CONDITION_HAZE:
                icon = Application.loadResource( Rez.Drawables.w_haze ) as BitmapResource;
                break;
            case Weather.CONDITION_VOLCANIC_ASH:
            case Weather.CONDITION_SMOKE:
            case Weather.CONDITION_SAND:
            case Weather.CONDITION_SANDSTORM:
            case Weather.CONDITION_DUST:
                icon = Application.loadResource( Rez.Drawables.w_dust ) as BitmapResource;
                break;
            case Weather.CONDITION_HAIL:
                icon = Application.loadResource( Rez.Drawables.w_hail ) as BitmapResource;
                break;
            case Weather.CONDITION_THUNDERSTORMS:
            case Weather.CONDITION_SCATTERED_THUNDERSTORMS:
            case Weather.CONDITION_CHANCE_OF_THUNDERSTORMS:
                icon = Application.loadResource( Rez.Drawables.w_thunder ) as BitmapResource;
                break;
            case Weather.CONDITION_TROPICAL_STORM:
            case Weather.CONDITION_HURRICANE:
                icon = Application.loadResource( Rez.Drawables.w_hurricane ) as BitmapResource;
                break;
            case Weather.CONDITION_TORNADO:
                icon = Application.loadResource( Rez.Drawables.w_tornado ) as BitmapResource;
                break;
            default:
                icon = Application.loadResource( Rez.Drawables.w_default ) as BitmapResource;
        }
        dc.drawBitmap((dc.getWidth() / 2) - 30, 23, icon);

    }

    hidden function setSunUpDown(dc) as Void {
        var weather = Weather.getCurrentConditions();
        var sunUpLabel = View.findDrawableById("SunUpLabel") as Text;
        var sunDownLabel = View.findDrawableById("SunDownLabel") as Text;
        var now = Time.now();
        if(weather == null) {
            return;
        }
        var loc = weather.observationLocationPosition;
        if(loc == null) {
            return;
        }
        var sunrise = Time.Gregorian.info(Weather.getSunrise(loc, now), Time.FORMAT_SHORT);
        var sunset = Time.Gregorian.info(Weather.getSunset(loc, now), Time.FORMAT_SHORT);
        sunUpLabel.setText(sunrise.hour.format(INTEGER_FORMAT));
        sunDownLabel.setText(sunset.hour.format(INTEGER_FORMAT));
    }

    hidden function setNotif(dc) as Void {
        var value = "";
        var sample = System.getDeviceSettings().notificationCount;
        if(sample > 0) {
            value = sample.format("%01d");
        }
        var notifLabel = View.findDrawableById("NotifLabel") as Text;
        notifLabel.setText(value);
    }

    hidden function setDate(dc) as Void {
        var dateLabel = View.findDrawableById("DateLabel") as Text;
        var now = Time.now();
        var today = Time.Gregorian.info(now, Time.FORMAT_SHORT);
        var week = iso_week_number(today.year, today.month, today.day).toString();

        var value = Lang.format("$1$, $2$ $3$ $4$ (W $5$)" , [
            day_name(today.day_of_week),
            today.day,
            month_name(today.month),
            today.year,
            week
        ]).toUpper();
        dateLabel.setText(value);
    }

    hidden function setStep(dc) as Void {
        var stepLabel = View.findDrawableById("StepLabel") as Text;
        var stepCount = ActivityMonitor.getInfo().steps.format("%05d");
        stepLabel.setText(stepCount);
    }

    hidden function setStressAndBodyBattery(dc) as Void {
        var batt = 0;
        var stress = 0;

        if ((Toybox has :SensorHistory) && (Toybox.SensorHistory has :getBodyBatteryHistory) && (Toybox.SensorHistory has :getStressHistory)) {
            // Set up the method with parameters
            var bbIterator = Toybox.SensorHistory.getBodyBatteryHistory({:period => 1});
            var stIterator = Toybox.SensorHistory.getStressHistory({:period => 1});
            var bb = bbIterator.next();
            var st = stIterator.next();
            var barTop = 91;
            var fromEdge = 10;
            var barWidth = 3;
            var bbAdjustment = 0;
            if(dc.getHeight() == 240) {
                barTop = 81;
                fromEdge = 6;
                barWidth = 2;
                bbAdjustment = 1;
            }
            if(dc.getHeight() == 280) {
                fromEdge = 14;
                barWidth = 4;
                bbAdjustment = -1;
            }
            if(bb != null) {
                batt = Math.round(bb.data * 0.80);
                dc.setColor(0x00AAFF, -1);
                dc.fillRectangle(dc.getWidth() - fromEdge - barWidth - bbAdjustment, barTop + (80 - batt), barWidth, batt);
            }
            if(st != null) {
                stress = Math.round(st.data * 0.80);
                dc.setColor(0xFFAA00, -1);
                dc.fillRectangle(fromEdge, barTop + (80 - stress), barWidth, stress);
            }
        }
    }

    hidden function setTraining(dc) as Void {
        var TTRDesc = View.findDrawableById("TTRDesc") as Text;
        var TTRLabel = View.findDrawableById("TTRLabel") as Text;
        var TTRReady = View.findDrawableById("TTRReady") as Text;

        if(ActivityMonitor.getInfo().timeToRecovery == null || ActivityMonitor.getInfo().timeToRecovery == 0) {
            TTRReady.setText("FULLY\nRECOVERED");
            TTRLabel.setText("");
            TTRDesc.setText("");
        } else { 
            TTRReady.setText("");
            TTRDesc.setText("HOURS TO\nRECOVERY");
            if(dc.getHeight() == 240) {
                TTRDesc.setText("HRS TO\nRECOV.");
            }

            var ttr = ActivityMonitor.getInfo().timeToRecovery.format("%03d");
            TTRLabel.setText(ttr);
        }
        
        var ActiveDesc = View.findDrawableById("ActiveDesc") as Text;
        ActiveDesc.setText("WEEKLY\nACTIVE MIN");

        if(dc.getHeight() == 240) {
            ActiveDesc.setText("WEEKLY\nMIN");
        }

        var ActiveLabel = View.findDrawableById("ActiveLabel") as Text;
        var active = "";
        if(ActivityMonitor.getInfo().activeMinutesWeek != null) {
            if(ActivityMonitor.getInfo().activeMinutesWeek.total > 999) {
                active = ActivityMonitor.getInfo().activeMinutesWeek.total.format("%04d");
                ActiveDesc.setText("");
            } else {
                active = ActivityMonitor.getInfo().activeMinutesWeek.total.format("%03d");
            }            
            ActiveLabel.setText(active);
        }

    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
        isSleeping = false;
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
        isSleeping = true;
    }

    hidden function day_name(day_of_week) {
        var names = [
            "SUNDAY",
            "MONDAY",
            "TUESDAY",
            "WEDNESDAY",
            "THURSDAY",
            "FRIDAY",
            "SATURDAY",
        ];
        return names[day_of_week - 1];
    }

    hidden function month_name(month) {
        var names = [
            "JANUARY",
            "FEBRUARY",
            "MARCH",
            "APRIL",
            "MAY",
            "JUNE",
            "JULY",
            "AUGUST",
            "SEPTEMBER",
            "OCTOBER",
            "NOVEMBER",
            "DECEMBER"
        ];
        return names[month - 1];
    }

    hidden function iso_week_number(year, month, day) {
    	var first_day_of_year = julian_day(year, 1, 1);
    	var given_day_of_year = julian_day(year, month, day);
    	var day_of_week = (first_day_of_year + 3) % 7;
    	var week_of_year = (given_day_of_year - first_day_of_year + day_of_week + 4) / 7;
    	if (week_of_year == 53) {
			if (day_of_week == 6) {
            	return week_of_year;
        	} else if (day_of_week == 5 && is_leap_year(year)) {
            	return week_of_year;
        	} else {
            	return 1;
        	}
    	}
    	else if (week_of_year == 0) {
       		first_day_of_year = julian_day(year - 1, 1, 1);
        	day_of_week = (first_day_of_year + 3) % 7;
			return (given_day_of_year - first_day_of_year + day_of_week + 4) / 7;
    	}
    	else {
            return week_of_year;
    	}
	}
	
	
	hidden function julian_day(year, month, day) {
    	var a = (14 - month) / 12;
    	var y = (year + 4800 - a);
    	var m = (month + 12 * a - 3);
    	return day + ((153 * m + 2) / 5) + (365 * y) + (y / 4) - (y / 100) + (y / 400) - 32045;
	}
	
	
	hidden function is_leap_year(year) {
    	if (year % 4 != 0) {
        	return false;
   		 } else if (year % 100 != 0) {
        	return true;
    	} else if (year % 400 == 0) {
            return true;
    	}
		return false;
	}

    hidden function flipMoonCodeForSouthernHemisphere(code as String) as String {
        switch (code) {
            // Waxing ↔ Waning flips
            case "1": return "7"; // waxing crescent ↔ waning crescent
            case "2": return "6"; // first quarter ↔ last quarter
            case "3": return "5"; // waxing gibbous ↔ waning gibbous
            case "5": return "3";
            case "6": return "2";
            case "7": return "1";
            // “0” (new) and “4” (full) look the same from both hemispheres
            default:  return code;
        }
    }

    hidden function moon_phase(time) as String {
        // 1) Calculate the Northern Hemisphere moon code exactly as before
        var jd = julian_day(time.year, time.month, time.day);
        var days_since_new_moon = jd - 2459966; 
        var lunar_cycle = 29.53;
        var phase = ((days_since_new_moon / lunar_cycle) * 100).toNumber() % 100;
        var into_cycle = (phase / 100.0) * lunar_cycle;

        // Determine the raw code (0..7) for the “Northern Hemisphere” shape
        var rawCode = "";
        if (into_cycle < 3) {
            rawCode = "0"; // new
        } else if (into_cycle < 6) {
            rawCode = "1"; // waxing crescent
        } else if (into_cycle < 10) {
            rawCode = "2"; // first quarter
        } else if (into_cycle < 14) {
            rawCode = "3"; // waxing gibbous
        } else if (into_cycle < 18) {
            rawCode = "4"; // full
        } else if (into_cycle < 22) {
            rawCode = "5"; // waning gibbous
        } else if (into_cycle < 26) {
            rawCode = "6"; // last quarter
        } else if (into_cycle < 29) {
            rawCode = "7"; // waning crescent
        } else {
            rawCode = "0"; // new again
        }

        // 2) Check if user is in Southern Hemisphere
        var positionInfo = Position.getInfo();
        if (positionInfo != null && positionInfo.position != null) {
            var coords = positionInfo.position.toDegrees();
            var lat = coords[0];
            if (lat < 0) {
                // 3) Flip the shape codes. 
                // Text (waxing/waning) does *not* need to be swapped, only the graphic side.
                rawCode = flipMoonCodeForSouthernHemisphere(rawCode);
            }
        }

        return rawCode;
    }
}
