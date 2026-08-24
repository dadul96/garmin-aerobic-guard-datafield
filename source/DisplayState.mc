import Toybox.Lang;

// Preallocated presentation state; compute() mutates fields without creating a
// symbol-keyed dictionary every second.
class DisplayState {
    var power = null;
    var heartRate = null;
    var cadence = null;
    var speed = null;
    var averagePower = null;
    var averageHeartRate = null;
    var averageCadence = null;
    var elapsed = null;
    var carbs = null;
    var hrMin = null;
    var hrMax = null;

    function clearReadings() {
        power = null;
        heartRate = null;
        cadence = null;
        speed = null;
        averagePower = null;
        averageHeartRate = null;
        averageCadence = null;
        elapsed = null;
        carbs = null;
    }
}
