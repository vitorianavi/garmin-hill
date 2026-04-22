using Toybox.Math;

module GarminHill {
    class GradeEngine {
        var _config;
        var _segments;
        var _windowDistance;
        var _windowRise;
        var _smoothedAltitude;
        var _smoothedGrade;

        function initialize(config) {
            _config = config;
            if (_config == null) {
                _config = Constants.getProfileConfig("trail");
            }
            _segments = [];
            _windowDistance = 0.0;
            _windowRise = 0.0;
            _smoothedAltitude = null;
            _smoothedGrade = null;
        }

        function setProfileConfig(config) {
            _config = config;
            if (_config == null) {
                _config = Constants.getProfileConfig("trail");
            }
            reset();
        }

        function getWindowDistance() {
            return _windowDistance;
        }

        function reset() {
            _segments = [];
            _windowDistance = 0.0;
            _windowRise = 0.0;
            _smoothedAltitude = null;
            _smoothedGrade = null;
        }

        function addPoint(rawAltitude, distanceDelta, speedMps, quality) {
            if (rawAltitude == null || distanceDelta == null || speedMps == null) {
                return noGrade();
            }

            if (quality != null && quality < cfg(:minGpsQuality, Constants.MIN_GPS_QUALITY)) {
                return noGrade();
            }

            if (speedMps < cfg(:minSpeedMps, Constants.MIN_SPEED_MPS)) {
                return noGrade();
            }

            if (_smoothedAltitude == null) {
                _smoothedAltitude = rawAltitude;
                return noGrade();
            }

            if (absValue(rawAltitude - _smoothedAltitude) > cfg(:maxAltJumpM, Constants.MAX_ALT_JUMP_M)) {
                return noGrade();
            }

            var altitudeAlpha = cfg(:altSmoothingAlpha, Constants.ALT_SMOOTHING_ALPHA);
            var nextAltitude = (altitudeAlpha * rawAltitude) + ((1.0 - altitudeAlpha) * _smoothedAltitude);
            var riseDelta = nextAltitude - _smoothedAltitude;
            _smoothedAltitude = nextAltitude;

            if (distanceDelta < cfg(:minSampleDistanceM, Constants.MIN_SAMPLE_DISTANCE_M) || distanceDelta > cfg(:maxSampleDistanceM, Constants.MAX_SAMPLE_DISTANCE_M)) {
                return noGrade();
            }

            _segments.add({ :rise => riseDelta, :distance => distanceDelta });
            _windowDistance += distanceDelta;
            _windowRise += riseDelta;

            while (_windowDistance > cfg(:windowDistanceM, Constants.WINDOW_DISTANCE_M) && _segments.size() > 0) {
                var oldest = _segments[0];
                _segments.remove(oldest);
                _windowDistance -= oldest[:distance];
                _windowRise -= oldest[:rise];
            }

            if (_windowDistance < cfg(:minWindowDistanceM, Constants.MIN_WINDOW_DISTANCE_M)) {
                return noGrade();
            }

            var rawGrade = (_windowRise / _windowDistance) * 100.0;
            if (absValue(rawGrade) > cfg(:maxAbsGradePercent, Constants.MAX_ABS_GRADE_PERCENT)) {
                return noGrade();
            }

            if (_smoothedGrade == null) {
                _smoothedGrade = rawGrade;
            } else {
                var gradeAlpha = cfg(:gradeSmoothingAlpha, Constants.GRADE_SMOOTHING_ALPHA);
                _smoothedGrade = (gradeAlpha * rawGrade) + ((1.0 - gradeAlpha) * _smoothedGrade);
            }

            return {
                :hasGrade => true,
                :gradePercent => _smoothedGrade,
                :distanceWindow => _windowDistance
            };
        }

        function cfg(key, fallbackValue) {
            if (_config != null && _config.hasKey(key)) {
                return _config[key];
            }
            return fallbackValue;
        }

        function noGrade() {
            return {
                :hasGrade => false,
                :distanceWindow => _windowDistance
            };
        }

        function absValue(value) {
            return (value < 0) ? -value : value;
        }
    }
}
