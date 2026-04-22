using Toybox.Lang;

module GarminHill {
    module Constants {
        const MIN_SPEED_MPS = 0.5;
        const MIN_SAMPLE_DISTANCE_M = 1.0;
        const MAX_SAMPLE_DISTANCE_M = 60.0;
        const WINDOW_DISTANCE_M = 80.0;
        const MIN_WINDOW_DISTANCE_M = 25.0;
        const ALT_SMOOTHING_ALPHA = 0.15;
        const GRADE_SMOOTHING_ALPHA = 0.30;
        const MAX_ALT_JUMP_M = 8.0;
        const MAX_ABS_GRADE_PERCENT = 35.0;
        const MIN_GPS_QUALITY = 2;

        function getProfileConfig(profileName) {
            var profile = profileName;
            if (profile == null) {
                profile = "trail";
            }

            if (profile == "road") {
                return {
                    :minSpeedMps => 1.2,
                    :minSampleDistanceM => 2.0,
                    :maxSampleDistanceM => 90.0,
                    :windowDistanceM => 120.0,
                    :minWindowDistanceM => 35.0,
                    :altSmoothingAlpha => 0.12,
                    :gradeSmoothingAlpha => 0.24,
                    :maxAltJumpM => 6.0,
                    :maxAbsGradePercent => 25.0,
                    :minGpsQuality => 3
                };
            }

            if (profile == "cycling") {
                return {
                    :minSpeedMps => 1.5,
                    :minSampleDistanceM => 3.0,
                    :maxSampleDistanceM => 120.0,
                    :windowDistanceM => 150.0,
                    :minWindowDistanceM => 45.0,
                    :altSmoothingAlpha => 0.10,
                    :gradeSmoothingAlpha => 0.22,
                    :maxAltJumpM => 6.0,
                    :maxAbsGradePercent => 22.0,
                    :minGpsQuality => 3
                };
            }

            if (profile == "hiking") {
                return {
                    :minSpeedMps => 0.4,
                    :minSampleDistanceM => 0.8,
                    :maxSampleDistanceM => 40.0,
                    :windowDistanceM => 70.0,
                    :minWindowDistanceM => 20.0,
                    :altSmoothingAlpha => 0.18,
                    :gradeSmoothingAlpha => 0.35,
                    :maxAltJumpM => 8.0,
                    :maxAbsGradePercent => 35.0,
                    :minGpsQuality => 2
                };
            }

            return {
                :minSpeedMps => MIN_SPEED_MPS,
                :minSampleDistanceM => MIN_SAMPLE_DISTANCE_M,
                :maxSampleDistanceM => MAX_SAMPLE_DISTANCE_M,
                :windowDistanceM => WINDOW_DISTANCE_M,
                :minWindowDistanceM => MIN_WINDOW_DISTANCE_M,
                :altSmoothingAlpha => ALT_SMOOTHING_ALPHA,
                :gradeSmoothingAlpha => GRADE_SMOOTHING_ALPHA,
                :maxAltJumpM => MAX_ALT_JUMP_M,
                :maxAbsGradePercent => MAX_ABS_GRADE_PERCENT,
                :minGpsQuality => MIN_GPS_QUALITY
            };
        }
    }
}
