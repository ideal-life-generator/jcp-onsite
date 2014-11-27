window.app = angular.module "scanApplication", [ "ngResource", "ngAnimate", "ngCookies" ]

window.domain = "event.congresso.no"
# window.domain = "188.226.184.59/congressomulti"

app.config ($interpolateProvider, $httpProvider) ->
	$interpolateProvider.startSymbol '~'
	$interpolateProvider.endSymbol '~'
	$httpProvider.defaults.headers.post["Content-Type"] = "application/x-www-form-urlencoded; charset=UTF-8"	

app.run ->
	window.onkeydown = (event) ->
		if event.keyCode is 8
			if event.target.nodeName isnt "INPUT"
				no