app.directive "login", (connect, message, freelancer, lyric) ->
	restrict: "C"
	controller: ($scope, $element) ->
		button = $element[0].querySelector "button"

		message.setNeutral lyric.constant.message_6
		$scope.freelancer.loginer = ->
			button.disabled = yes
			message.setNeutral lyric.constant.message_7
			freelancer.login().then ->
				null
			, ->
				button.disabled = no

app.directive "scroll", (scroll) ->
	restrict: "A"
	controller: ($scope, $element) ->
		scroll.setElement selector: $element[0]