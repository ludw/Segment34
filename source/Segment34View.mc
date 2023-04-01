import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.ActivityMonitor;
import Toybox.Application;
import Toybox.Weather;
import Toybox.Time;
import Toybox.Math;

const INTEGER_FORMAT = "%d";

class Segment34View extends WatchUi.WatchFace {

    private var isSleeping = false;

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
        var timeString = Lang.format("$1$:$2$", [clockTime.hour.format("%02d"), clockTime.min.format("%02d")]);
        var timelabel = View.findDrawableById("TimeLabel") as Text;
        timelabel.setText(timeString);

        // time background 
        var timebg = View.findDrawableById("TimeBg") as Text;
        timebg.setText("#####");
        
        setMoon(dc);
        setHR(dc);
        setHRIcons(dc);
        setBatt(dc);
        setNotif(dc);
        setWeather(dc);
        setDate(dc);
        setStep(dc);

        View.onUpdate(dc);

        setWeatherIcon(dc);
    }

    function onPartialUpdate(dc) {
    }

    function onPowerBudgetExceeded() {
        System.println("Power budget exceeded");
    }

    hidden function setHRIcons(dc) as Void {
        var hrIconW = View.findDrawableById("HRIconW") as Text;
        var hrIconR = View.findDrawableById("HRIconR") as Text;

        if (!isSleeping) {
            hrIconR.setText("H");
        } else {
            hrIconR.setText("");
        }
        
        hrIconW.setText("h");
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
  
        //value = System.getClockTime().sec.format(INTEGER_FORMAT);
        hrLabel.setText(value);
        hrLabel.draw(dc);
    }

    hidden function setBatt(dc) as Void {
        var value = "";
        var sample = System.getSystemStats().batteryInDays;
        //value = Lang.format("BATT: $1$ DAYS" ,[sample.format(INTEGER_FORMAT)]);
        value = "";
        for(var i = 0; i < sample; i++) {
            value += "$";
        }
        var battLabel = View.findDrawableById("BattLabel") as Text;
        battLabel.setText(value);
    }

    hidden function setWeather(dc) as Void {
        var weather = Weather.getCurrentConditions();

        var temp = weather.temperature.format(INTEGER_FORMAT);
        var tempLabel = View.findDrawableById("TempLabel") as Text;
        tempLabel.setText(temp);

        var wind = weather.windSpeed.format(INTEGER_FORMAT);
        var windLabel = View.findDrawableById("WindLabel") as Text;
        windLabel.setText(wind);

        var windIcon = View.findDrawableById("WindIcon") as Text;
        var bearing = (Math.round((weather.windBearing.toFloat() + 180) / 45.0).toNumber() % 8).format(INTEGER_FORMAT);
        windIcon.setText(bearing);
        
        var wc = View.findDrawableById("WeatherCode") as Text;
        var wcVal = weather.condition.format(INTEGER_FORMAT);
        wc.setText(wcVal);
    }

    hidden function setWeatherIcon(dc) as Void {
        var weather = Weather.getCurrentConditions();
        var icon;

        switch(weather.condition) {
            case Weather.CONDITION_CLEAR:
                icon = Application.loadResource( Rez.Drawables.w_clear ) as BitmapResource;
                break;
            case Weather.CONDITION_PARTLY_CLOUDY:
                icon = Application.loadResource( Rez.Drawables.w_partly_cloudy ) as BitmapResource;
                break;
            case Weather.CONDITION_MOSTLY_CLOUDY:
                icon = Application.loadResource( Rez.Drawables.w_mostly_cloudy ) as BitmapResource;
                break;
            case Weather.CONDITION_CLOUDY:
                icon = Application.loadResource( Rez.Drawables.w_cloudy ) as BitmapResource;
                break;
            case Weather.CONDITION_RAIN:
                icon = Application.loadResource( Rez.Drawables.w_rain ) as BitmapResource;
                break;
            case Weather.CONDITION_LIGHT_RAIN:
                icon = Application.loadResource( Rez.Drawables.w_light_rain ) as BitmapResource;
            break;
                case Weather.CONDITION_HEAVY_RAIN:
                icon = Application.loadResource( Rez.Drawables.w_heavy_rain ) as BitmapResource;
                break;
            case Weather.CONDITION_SNOW:
                icon = Application.loadResource( Rez.Drawables.w_snow ) as BitmapResource;
                break;
            case Weather.CONDITION_LIGHT_SNOW:
                icon = Application.loadResource( Rez.Drawables.w_light_snow ) as BitmapResource;
                break;
            
            default:
                icon = Application.loadResource( Rez.Drawables.w_default ) as BitmapResource;
        }
        dc.drawBitmap(100, 23, icon);
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

        var value = Lang.format("$1$, $2$ $3$ $4$ (WEEK $5$)" , [
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
        var stepCount = ActivityMonitor.getInfo().steps.toString();
        stepLabel.setText(stepCount);
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
        //sleepUpdates = 2;
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

    hidden function moon_phase(time) {
        var jd = julian_day(time.year, time.month, time.day);

        var days_since_new_moon = jd - 2459966;
        var lunar_cycle = 29.53;
        var phase = ((days_since_new_moon / lunar_cycle) * 100).toNumber() % 100;
        var into_cycle = (phase / 100.0) * lunar_cycle;

        if (into_cycle < 2.5) {
            return "0";
        } else if (into_cycle < 5) {
            return "1";
        } else if (into_cycle < 8) {
            return "2";
        } else if (into_cycle < 13) {
            return "3";
        } else if (into_cycle < 17) {
            return "4";
        } else if (into_cycle < 20) {
            return "5";
        } else if (into_cycle < 23) {
            return "6";
        } else if (into_cycle < 26) {
            return "7";
        } else {
            return "0";
        }

    }

}