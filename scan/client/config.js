// Generated by CoffeeScript 1.8.0
(function() {
  window.app = angular.module("scanApplication", ["ngResource", "ngAnimate", "ngCookies"]);

  window.domain = "event.congresso.no";

  app.config(function($interpolateProvider, $httpProvider) {
    $interpolateProvider.startSymbol('~');
    $interpolateProvider.endSymbol('~');
    return $httpProvider.defaults.headers.post["Content-Type"] = "application/x-www-form-urlencoded; charset=UTF-8";
  });

  app.run(function() {
    return window.onkeydown = function(event) {
      if (event.keyCode === 8) {
        if (event.target.nodeName !== "INPUT") {
          return false;
        }
      }
    };
  });

}).call(this);
