app.factory "resource", ($resource) ->
	$resource "http://#{domain}/api/:api/:id", { },
		get: method: "GET", headers: { "User-Role": "freelancer" }
		posts: method: "POST", headers: { "User-Role": "freelancer" }

app.factory "connect", (resource, loader) ->
	load: (settings, result, error) ->
		loader.loading = on
		if settings.type is "get"
			resource[settings.type]
				api: settings.params.api,
				id: settings.params.id
				data: settings.data
			, (res) ->
				loader.loading = off
				result angular.fromJson res.data
			, (err) ->
				loader.loading = off
				error err
		else if settings.type is "posts"
			resource[settings.type]
				api: settings.params.api,
				id: settings.params.id
			,
				data: settings.data
			, (res) ->
				loader.loading = off
				result res.data
			, (err) ->
				loader.loading = off
				error err

app.factory "parser", ->
	class Parser
		objToMassive: (obj) ->
			massive = [ ]
			angular.forEach obj, (item) ->
				if item.id
					item.id = ~~item.id
				massive.push item
			massive
	new Parser

app.factory "message", ->
	class Message
	
		setNeutral: (message) ->
			@clear()
			@neutral = message
		setSuccess: (message) ->
			@clear()
			@success = message
		setError: (message) ->
			@clear()
			@error = message

		clear: ->
			delete @error
			delete @success
			delete @neutral

	new Message()

app.factory "loader", ->
	class Loader
		ths = null
		constructor: ->
			ths = @

	new Loader()

app.factory "events", (connect, $q, parser) ->
	class Events
		ths = null
		constructor: ->
			ths = @

		load: ->
			defer = $q.defer()
			connect.load
				type: "get"
				params: api: "event"
			, (eventList) ->
				ths.eventList = parser.objToMassive eventList
				ths.activeEvent = ths.eventList[0]
				defer.resolve()
			, (eventError) ->
				defer.reject eventError
			defer.promise

		clear: ->
			delete @eventList
			delete @activeEvent

	new Events()

app.factory "participants", (connect, $q, parser, events, $filter, scroll, message, lyric) ->
	class Participants
		ths = null
		constructor: ->
			@filteredList = [ ]
			ths = @

		load: ->
			defer = $q.defer()
			connect.load
				type: "get"
				params: api: "participant"
				data: event_id: events.activeEvent.id, approval_status: 2
			, (participantsList) ->
					defer.resolve parser.objToMassive participantsList
			, (participantsError) ->
				defer.reject participantsError
			defer.promise

		loadProfile: (participant) ->
			defer = $q.defer()
			connect.load
				type: "get"
				params: api: "participant"
				data: id: participant.id, extraParam: "detailView"
			, (participantProfile) ->
				defer.resolve parser.objToMassive(participantProfile)[0]
			, (profileError) ->
				defer.reject profileError
			defer.promise

		updateParticipant: (participant) ->
			defer = $q.defer()
			connect.load
				type: "get"
				params: api: "participant"
				data: id: participant.id
			, (participantCheckedin) ->
				participantCheckedin = parser.objToMassive participantCheckedin
				angular.forEach ths.participantsList, (participant, i) ->
					if participant.id is participantCheckedin[0].id
						ths.participantsList[i].checkedin_time = participantCheckedin[0].checkedin_time
						ths.participantsList[i].status = "checkedin"
				angular.forEach ths.filteredList, (participant, i) ->
					if participant.id is participantCheckedin[0].id
						ths.filteredList[i].checkedin_time = participantCheckedin[0].checkedin_time
						ths.filteredList[i].status = "checkedin"
				ths.addChecinsCount()
				defer.resolve()
				ths.checkins = off
			, (error) ->
				message.setError lyric.dynamic.t "message_3", var1: error.status, var2: error.statusText
				defer.reject()
				ths.checkins = off
			defer.promise

		updateChecinsCount: ->
			checkinsCount = 0
			angular.forEach @participantsList, (participant) ->
				if participant.status is "checkedin"
					checkinsCount++
			@participantsList.checkidins = checkinsCount

		addChecinsCount: ->
			@participantsList.checkidins++

		checkin: (participant) ->
			@checkins = on
			defer = $q.defer()
			message.setNeutral lyric.constant.message_8
			connect.load
				type: "posts"
				params: api: "participantCheckin"
				data: participant_id: participant.id
			, (data) ->
				ths.updateParticipant participant
					.then (data) ->
						defer.resolve()
					, (error) ->
						defer.reject()
			, (error) ->
				message.setError lyric.dynamic.t "message_3", var1: error.status, var2: error.statusText
				ths.updateParticipant participant
					.then (data) ->
						defer.resolve()
					, (error) ->
						defer.reject()
			defer.promise

		lastLength = undefined

		filter: (searchString) ->
			lastLength = @filteredList.length
			filteredList = $filter('filter') @participantsList, (participant) ->
				if searchString
					if participant.barcode.toLowerCase().indexOf(searchString) isnt -1 or participant.first_name.toLowerCase().indexOf(searchString) isnt -1 or participant.last_name.toLowerCase().indexOf(searchString) isnt -1 or participant.company_name.toLowerCase().indexOf(searchString) isnt -1 then yes
				else yes
			if filteredList and @participantsList
				scroll.scrollList filteredList.length, lastLength
			if filteredList then @filteredList = filteredList

		clear: ->
			delete @participantsList
			@filteredList = [ ]
			delete @searchString
			delete @refresh
			delete @activeParticipant
			delete @lastParticipantActive

	new Participants()

app.factory "scroll", ($timeout) ->
	class Scroll
		ths = null
		constructor: (@elements = [ ], @scrollCoords = [ ]) ->
			ths = @

		setElement: (element) ->
			@elements.push element

		scrollElement: ->
			angular.forEach @elements, (element) ->
				element.coord = element.selector.getBoundingClientRect().top + element.selector.getBoundingClientRect().height
			window.addEventListener "scroll", (event) ->
				event.stopPropagation()
				scrollTop = window.document.body.scrollTop
				angular.forEach ths.elements, (element) ->
					classList = element.selector.classList
					if element.coord < scrollTop and not classList.contains "scroll"
						classList.add "scroll"
					else if element.coord >= scrollTop and classList.contains "scroll"
						classList.remove "scroll"

		scrollList: (newLength, lastLength) ->
			if newLength < lastLength
				@scrollCoords.push window.document.body.scrollTop
			else if newLength > lastLength and @scrollCoords.length
				$timeout ->
					document.body.scrollTop = ths.scrollCoords[ths.scrollCoords.length-1]
					ths.scrollCoords.length = ths.scrollCoords.length-1

		clear: ->
			angular.forEach @elements, (element) ->
				classList = element.selector.classList
				if classList.contains "scroll"
					classList.remove "scroll"

	new Scroll()

app.factory "freelancer", (connect, auth, parser, message, scroll, $timeout, events, participants, print, lyric, $q) ->
	class Freelancer
		ths = null
		constructor: ->
			ths = @

		clearAuthData: ->
			delete @username
			delete @password

		setProfile: (@profile = profile) ->

		setCredentials: auth.setCredentials

		clearCredentials: auth.clearCredentials

		login: ->
			defer = $q.defer()
			@setCredentials @username, @password
			connect.load
				type: "get"
				params:
					api: "login"
				, (profile) ->
					message.setSuccess lyric.dynamic.t "message_8", var1: profile.username
					ths.setProfile profile
					events.load().then (eventsList) ->
						message.setSuccess lyric.dynamic.t "message_9", var1: events.activeEvent.event_name
						participants.load().then (participantsList) ->
							message.setSuccess lyric.dynamic.t "message_10", var1: events.activeEvent.event_name
							participants.participantsList = participantsList
							participants.filter()
							participants.updateChecinsCount()
							ths.clearAuthData()
							$timeout ->
								scroll.scrollElement()
							defer.resolve()
						, (participantsError) ->
							message.setError lyric.dynamic.t "message_3", var1: participantsError.status, var2: participantsError.statusText
							$timeout ->
								ths.logout()
							, 6000
							defer.reject()
					, (eventsError) ->
						message.setError lyric.dynamic.t "message_3", var1: eventsError.status, var2: eventsError.statusText
						ths.clearCredentials()
						defer.reject()
				, (authError) ->
					message.setError lyric.dynamic.t "message_3", var1: authError.status, var2: authError.statusText
					ths.clearCredentials()
					defer.reject()
			defer.promise

		logout: ->
			message.setNeutral lyric.constant.message_6
			delete @profile
			events.clear()
			scroll.clear()
			participants.clear()
			@clearCredentials()
			print.clear()

	new Freelancer()

app.factory "storage", ->
	setJSON: (key, value) ->
		if key and value then localStorage.setItem key, JSON.stringify value
	getJSON: (key) ->
		if key then JSON.parse localStorage.getItem key
	contain: (key) ->
		if key
			if localStorage[key]
				yes

app.factory "alertt", ($timeout, message) ->
	class Alertt
		ths = null
		constructor: ->
			ths = @
			@scroll = top: undefined

		element = document.querySelector ".alert"

		updatePosition: ->
			delta = ( innerHeight - element.getBoundingClientRect().height ) / 2
			if delta > 0
				ths.scroll.top = scrollY + delta + "px"
			else
				ths.scroll.top = scrollY + "px"

		container = [ ]

		toggle: (name) ->
			index = container.indexOf name
			state = name: null, pre: null
			if index is -1
				container.push name
				state.name = name
				if container.length > 1
					state.pre = container[container.length-2]
				else
					state.pre = null
			else
				if container.length > 1
					state.pre = container[container.length-1]
					if name is container[container.length-1]
						container.length = container.length-1
					else
						last = container[container.length-1]
						container[container.length-1] = container[container.length-2]
						container[container.length-2] = last
					state.name = container[container.length-1]
				else
					state.pre = container[container.length-1]
					container.length = 0
			state

	new Alertt()

app.factory "print", ($sce, $filter) ->
	class Print
		ths = null
		constructor: ->
			ths = @
			@complateProfile = { }
			@printSettings = { }
			@passiveList = undefined

		addComplateProfile: (profile) ->
			priority = 0
			@complateProfile = [ { name: "first_name" }, { name: "last_name" }, { name: "middle_name" }, { name: "email" }, { name: "mobilephone" }, { name: "company_name" }, { name: "city" }, { name: "country" }, { name: "comments" }, { name: "birthday" }, { name: "department" }, { name: "gender" } ]

			angular.forEach @complateProfile, (field) ->
				name = field.name
				if name is "first_name" or name is "last_name"
					status: "active"
				else
					status: "passive"
				label = field.name.replace "_", " "
				field.label = label.slice(0, 1).toUpperCase() + label.slice 1
				field.priority = priority++
				field.bold = "False"
				field.makeRemove = yes
				field.name = name

			angular.forEach profile.options, (option) ->
				option.label = option.label.replace /<[^>]*>/g, ""
				ths.complateProfile.push
					label: option.label
					bold: "False"
					priority: priority++
					status: "passive"
					makeRemove: yes
					name: option.label

		printSetting: (profile) ->
			if not @printSettings[profile.form_id]
				priority = 0
				@printSettings[profile.form_id] =
					activeField: [ ]
					passiveField: [ ]

				angular.forEach @complateProfile, (field) ->
					if field.name is "first_name" or field.name is "last_name"
						ths.printSettings[profile.form_id].activeField.push field
					else
						ths.printSettings[profile.form_id].passiveField.push field

		getField: (field, profile) ->
			result = ""
			angular.forEach profile, (value, label) ->
				if field.name is label
					if value
						result = value
						field.isLabel = no
					else
						angular.forEach ths.complateProfile, (data) ->
							if field.name is data.name
								result = data.label
								field.isLabel = yes

			angular.forEach profile.options, (option) ->
				if field.name is option.label
					valueType = Object.prototype.toString.call(option.value).slice 8, -1
					if valueType is "Object"
						if option.label is "Kryss her for å delta på middag"
							result = "*"
							field.isLabel = no
						else
							angular.forEach option.value, (value) ->
								result += value + if result.length then "\n" else ""
							field.isLabel = no
					else if valueType is "Array"
						if not option.value.length
							result = option.label
							field.isLabel = yes
						else
							if option.label is "Kryss her for å delta på middag"
								result = "*"
								field.isLabel = no
							else
								angular.forEach option.value, (value) ->
									result += value + if result.length then "\n" else ""
								field.isLabel = no
					else if valueType is "Boolean"
						if option.label is "Kryss her for å delta på middag" and option.value
							result = "*"
							field.isLabel = no
						else
							result = option.label
						if option.value
							field.isLabel = no
						else
							field.isLabel = yes
					else
						if option.value
							result = option.value
							field.isLabel = no
						else
							result = option.label
							field.isLabel = yes

			$sce.trustAsHtml result

		passiveVisible: ->
			@passiveList = !@passiveList

		makeBold: (field) ->
			if field.bold is "True"
				field.bold = "False"
			else
				field.bold = "True"

		toActiveSettings: ($index, field, formId) ->
			@printSettings[formId].activeField.push @printSettings[formId].passiveField[$index]
			@printSettings[formId].passiveField.splice $index, 1
			@printSettings[formId].activeField = $filter('orderBy')(@printSettings[formId].activeField, "priority")
			field.status = "active"

		toPassiveSettings: ($index, field, formId) ->
			@printSettings[formId].passiveField.push @printSettings[formId].activeField[$index]
			@printSettings[formId].activeField.splice $index, 1
			@printSettings[formId].passiveField = $filter('orderBy')(@printSettings[formId].passiveField, "priority")
			field.status = "passive"

		priorityDown: ($index, formId) ->
			fieldPriority = @printSettings[formId].activeField[$index].priority
			@printSettings[formId].activeField[$index].priority = @printSettings[formId].activeField[$index+1].priority
			@printSettings[formId].activeField[$index+1].priority = fieldPriority
			@printSettings[formId].activeField = $filter('orderBy')(@printSettings[formId].activeField, "priority")
			fieldPriority = null

		priorityUp: ($index, formId) ->
			fieldPriority = @printSettings[formId].activeField[$index].priority
			@printSettings[formId].activeField[$index].priority = @printSettings[formId].activeField[$index-1].priority
			@printSettings[formId].activeField[$index-1].priority = fieldPriority
			@printSettings[formId].activeField = $filter('orderBy')(@printSettings[formId].activeField, "priority")
			fieldPriority = null

		clear: ->
			delete @complateProfile

	new Print()