using Toybox.Lang;
using Toybox.Math;
using Toybox.Position;
using Toybox.System;

module GarminHill {
    class GradientService {
        var _listener;
        var _engine;
        var _profileName;
        var _lastLocation;
        var _lastTimestamp;

        function initialize(listener, profileName) {
            _listener = listener;
            _profileName = profileName;
            if (_profileName == null) {
                _profileName = "trail";
            }
            _engine = new GradeEngine(Constants.getProfileConfig(_profileName));
            _lastLocation = null;
            _lastTimestamp = null;
        }

        function setProfile(profileName) {
            _profileName = profileName;
            if (_profileName == null) {
                _profileName = "trail";
            }
            _engine.setProfileConfig(Constants.getProfileConfig(_profileName));
        }

        function start() {
            _engine.reset();
            _lastLocation = null;
            _lastTimestamp = null;
            Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
        }

        function stop() {
            Position.enableLocationEvents(Position.LOCATION_DISABLE, null);
        }

        function onPosition(info as Position.Info) as Void {
            if (info == null || info.position == null || info.altitude == null) {
                publishNoData(null, null);
                return;
            }

            var now = System.getTimer();
            var distanceDelta = 0.0;
            var speedMps = info.speed;

            if (_lastLocation != null) {
                distanceDelta = computeDistanceMeters(_lastLocation, info.position);
            }

            if (speedMps == null && _lastTimestamp != null && now > _lastTimestamp) {
                var dtSec = (now - _lastTimestamp) / 1000.0;
                if (dtSec > 0.0) {
                    speedMps = distanceDelta / dtSec;
                }
            }

            _lastLocation = info.position;
            _lastTimestamp = now;

            var gradeInfo = _engine.addPoint(info.altitude, distanceDelta, speedMps, info.accuracy);
            if (!gradeInfo[:hasGrade]) {
                publishNoData(speedMps, info.accuracy);
                return;
            }

            gradeInfo[:speedMps] = speedMps;
            gradeInfo[:quality] = info.accuracy;
            gradeInfo[:profile] = _profileName;
            _listener.invoke(gradeInfo);
        }

        function publishNoData(speedMps, quality) {
            _listener.invoke({
                :hasGrade => false,
                :speedMps => speedMps,
                :quality => quality,
                :distanceWindow => _engine.getWindowDistance(),
                :profile => _profileName
            });
        }

        function computeDistanceMeters(fromLocation, toLocation) {
            if (fromLocation == null || toLocation == null) {
                return 0.0;
            }

            var fromRad = fromLocation.toRadians();
            var toRad = toLocation.toRadians();

            var dLat = toRad[0] - fromRad[0];
            var dLon = toRad[1] - fromRad[1];

            var sinLat = Math.sin(dLat / 2.0);
            var sinLon = Math.sin(dLon / 2.0);
            var a = (sinLat * sinLat) + (Math.cos(fromRad[0]) * Math.cos(toRad[0]) * sinLon * sinLon);
            var c = 2.0 * Math.atan2(Math.sqrt(a), Math.sqrt(1.0 - a));

            return 6371000.0 * c;
        }
    }
}
