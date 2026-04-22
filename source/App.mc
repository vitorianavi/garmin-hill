using Toybox.Application;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.Math;
using Toybox.WatchUi;

module GarminHill {
    class App extends Application.AppBase {
        function initialize() {
            AppBase.initialize();
        }

        function getInitialView() {
            var view = new GradeView();
            return [ view, new AppInputDelegate(view) ];
        }
    }

    class AppInputDelegate extends WatchUi.BehaviorDelegate {
        var _view;

        function initialize(view) {
            BehaviorDelegate.initialize();
            _view = view;
        }

        function onSelect() {
            _view.cycleProfile();
            return true;
        }

        function onMenu() {
            _view.toggleDebug();
            return true;
        }
    }

    class GradeView extends WatchUi.View {
        var _service;
        var _valueText;
        var _statusText;
        var _debugEnabled;
        var _profileOrder;
        var _profileIndex;
        var _lastSpeedMps;
        var _lastQuality;
        var _lastWindowDistance;
        var _gradeHistory;
        var _maxGraphPoints;
        var _graphRangePercent;

        function initialize() {
            View.initialize();
            _profileOrder = ["trail", "road", "cycling", "hiking"];
            _profileIndex = 0;
            _service = new GradientService(method(:onGradeUpdate), _profileOrder[_profileIndex]);
            _valueText = "--";
            _statusText = "GPS grade";
            _debugEnabled = false;
            _lastSpeedMps = null;
            _lastQuality = null;
            _lastWindowDistance = 0.0;
            _gradeHistory = [];
            _maxGraphPoints = 50;
            _graphRangePercent = 20.0;
        }

        function onShow() {
            _service.start();
        }

        function onHide() {
            _service.stop();
        }

        function onUpdate(dc) {
            var width = dc.getWidth();
            var height = dc.getHeight();

            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
            dc.clear();

            drawGraph(dc, width, height);

            dc.drawText(width / 2, height - 24, Graphics.FONT_SMALL, _valueText, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

            if (_debugEnabled) {
                var debugTop = profileLabel(_profileOrder[_profileIndex]) + "  q " + qualityText(_lastQuality);
                var debugBottom = "spd " + speedText(_lastSpeedMps) + "  win " + _lastWindowDistance.format("%.0f") + "m";
                dc.drawText(width / 2, 12, Graphics.FONT_XTINY, debugTop, Graphics.TEXT_JUSTIFY_CENTER);
                dc.drawText(width / 2, height - 24, Graphics.FONT_XTINY, debugBottom, Graphics.TEXT_JUSTIFY_CENTER);
            }

            dc.drawText(width / 2, height - 10, Graphics.FONT_XTINY, _statusText, Graphics.TEXT_JUSTIFY_CENTER);
        }

        function onGradeUpdate(gradeInfo) {
            if (gradeInfo != null) {
                _lastSpeedMps = gradeInfo[:speedMps];
                _lastQuality = gradeInfo[:quality];
                if (gradeInfo[:distanceWindow] != null) {
                    _lastWindowDistance = gradeInfo[:distanceWindow];
                }
            }

            if (gradeInfo == null || !gradeInfo[:hasGrade]) {
                _valueText = "--";
                _statusText = "Low confidence";
                WatchUi.requestUpdate();
                return;
            }

            var grade = gradeInfo[:gradePercent];
            var sign = "";
            if (grade > 0) {
                sign = "+";
            }

            addGradeSample(grade);

            _valueText = sign + grade.format("%.1f") + "%";
            _statusText = "GPS grade";
            WatchUi.requestUpdate();
        }

        function cycleProfile() {
            _profileIndex = (_profileIndex + 1) % _profileOrder.size();
            _service.setProfile(_profileOrder[_profileIndex]);
            _gradeHistory = [];
            _valueText = "--";
            _statusText = "Profile " + profileLabel(_profileOrder[_profileIndex]);
            WatchUi.requestUpdate();
        }

        function toggleDebug() {
            _debugEnabled = !_debugEnabled;
            WatchUi.requestUpdate();
        }

        function profileLabel(name) {
            if (name == "road") {
                return "Road";
            }
            if (name == "cycling") {
                return "Cycling";
            }
            if (name == "hiking") {
                return "Hiking";
            }
            return "Trail";
        }

        function speedText(speedMps) {
            if (speedMps == null) {
                return "--";
            }
            return speedMps.format("%.1f") + "m/s";
        }

        function qualityText(quality) {
            if (quality == null) {
                return "--";
            }
            return quality.format("%d");
        }

        function addGradeSample(grade) {
            if (grade == null) {
                return;
            }

            _gradeHistory.add(grade);
            while (_gradeHistory.size() > _maxGraphPoints) {
                _gradeHistory.remove(_gradeHistory[0]);
            }
        }

        function drawGraph(dc, width, height) {
            var left = 10;
            var right = width - 10;
            var top = 8;
            var bottom = height - 40;

            dc.drawRectangle(left, top, right - left, bottom - top);

            var zeroY = top + ((bottom - top) / 2);
            dc.drawLine(left, zeroY, right, zeroY);

            if (_gradeHistory.size() < 2) {
                return;
            }

            var count = _gradeHistory.size();
            var graphWidth = right - left;
            var graphHeight = bottom - top;
            var maxAbs = _graphRangePercent;

            for (var i = 1; i < count; i += 1) {
                var g0 = clamp(_gradeHistory[i - 1], -maxAbs, maxAbs);
                var g1 = clamp(_gradeHistory[i], -maxAbs, maxAbs);

                var x0 = left + (((i - 1) * graphWidth) / (count - 1));
                var x1 = left + ((i * graphWidth) / (count - 1));

                var y0 = top + (((maxAbs - g0) * graphHeight) / (2.0 * maxAbs));
                var y1 = top + (((maxAbs - g1) * graphHeight) / (2.0 * maxAbs));

                dc.drawLine(x0, y0, x1, y1);
            }

        }

        function clamp(value, minValue, maxValue) {
            if (value < minValue) {
                return minValue;
            }
            if (value > maxValue) {
                return maxValue;
            }
            return value;
        }
    }

    function getApp() {
        return Application.getApp();
    }
}
